function [lrcolumnx, lrcolumny] = calc_rigid_zone_column(...
  secdim, stdh, mglevel, mgstype, ...
  idmc2mf1x, idmc2mf2x, idmc2mf1y, idmc2mf2y, idmc2st, idmg2sg, idsg2s, ...
  mcstype, idmc2s, ccxl, ~)
%calc_rigid_zone_column 柱の剛域長を計算
%   [lrcolumnx, lrcolumny] = calc_rigid_zone_column(secdim, stdh,
%     mglevel, mgstype, idmc2mf1x, idmc2mf2x, idmc2mf1y, idmc2mf2y,
%     idmc2st, idmg2sg, idsg2s, mcstype, idmc2s, ccxl, ccyl) は、
%   柱の剛域長を計算します。SS7仕様書3.3.1(RC造)と3.3.2(S造)に準拠します。
%
%   入力引数:
%     secdim    - 断面寸法行列 [nsec×4]
%                 列1-2: 名目寸法(H,B)、列3-4: 実寸法(D,W)
%     stdh      - 階高配列 [nst×1]
%     mglevel   - 梁レベル配列 [nmg×1]
%     mgstype   - 梁断面タイプ配列 [nmg×1]
%     idmc2mf1x - 柱脚側X方向梁ID配列 [nmc×*]
%     idmc2mf2x - 柱頭側X方向梁ID配列 [nmc×*]
%     idmc2mf1y - 柱脚側Y方向梁ID配列 [nmc×*]
%     idmc2mf2y - 柱頭側Y方向梁ID配列 [nmc×*]
%     idmc2st   - 柱階ID配列 [nmc×1]
%     idmg2sg   - 梁ID→梁断面IDマッピング [nmg×1]
%     idsg2s    - 梁断面ID→全断面IDマッピング [nsecg×1]
%     mcstype   - 柱断面タイプ配列 [nmc×1]
%     idmc2s    - 柱断面ID配列 [nmc×1]
%     ccxl      - 柱の方向余弦（X軸方向）[nmc×3]
%     ccyl      - 柱の方向余弦（Y軸方向）[nmc×3]
%
%   出力引数:
%     lrcolumnx - X方向柱剛域長 [nmc×2]
%                 列1: 柱脚側、列2: 柱頭側
%     lrcolumny - Y方向柱剛域長 [nmc×2]
%                 列1: 柱脚側、列2: 柱頭側
%
%   備考:
%     - RC柱: 剛域長 = 梁せい - 階高差 - 0.25×柱寸法
%     - S柱: RC梁が取り付く場合、剛域長 = 梁せい - 階高差（フェイス位置まで）
%     - S柱にS梁のみの場合: 剛域なし
%     - 斜め柱の場合、剛域長を柱軸方向に投影補正する
%
%   参考:
%     calc_rigid_zone_girder, update_geometry

% 定数
nmc = size(idmc2mf1x,1);

% 計算の準備
lrcolumnx = zeros(nmc,2);
lrcolumny = zeros(nmc,2);

% 柱軸方向のZ成分を取得
% ccxl は部材軸方向（i端からj端）の方向余弦 [cx, cy, cz]
% 柱軸のZ成分 = ccxl(:,3) = cos(θ)、θは柱軸と鉛直線のなす角度
cz = ccxl(:,3);

% 柱の剛域長さ
for ic=1:nmc
  % 斜め柱の投影補正係数を計算
  % cz(ic) = cos(θ)、θは柱軸と鉛直線のなす角度
  if abs(cz(ic)) > 1e-6
    proj_factor = 1 / abs(cz(ic));
  else
    proj_factor = 1;  % 水平柱（通常は存在しない）
  end
  ist = idmc2st(ic);
  idsc = idmc2s(ic);  % 柱断面ID

  % 柱の寸法を取得（実寸法を使用、SS7仕様）
  col_D = secdim(idsc,1);  % 柱せい（X方向寸法）
  col_B = secdim(idsc,2);  % 柱幅（Y方向寸法）

  % 柱タイプ判定とα係数設定
  % RC柱: α=0.25（SS7仕様書3.3.1）
  % S柱: α=0（フェイス位置まで、SS7仕様書3.3.2）
  if mcstype(ic) == PRM.RCRS
    alfa = 0.25;  % RC柱
  else
    alfa = 0;     % S柱
  end

  for ij=1:2
    switch ij
      case 1
        % 柱脚側
        dh = -stdh(ist-1);
        rx = 0; ry = 0;

        % X方向梁の処理
        idm_ = idmc2mf1x(ic,:);
        idm_ = idm_(idm_>0);
        if any(mgstype(idm_)==PRM.RCRS)
          % RC梁が接続する場合
          rx = max([dh+mglevel(idm_); 0]);
          % SS7仕様：柱寸法×αを減じる
          rx = rx - alfa * col_D;  % X方向梁なので柱せいを減じる
        end

        % Y方向梁の処理
        idm_ = idmc2mf1y(ic,:);
        idm_ = idm_(idm_>0);
        if any(mgstype(idm_)==PRM.RCRS)
          ry = max([dh+mglevel(idm_); 0]);
          % SS7仕様：柱寸法×αを減じる
          ry = ry - alfa * col_B;  % Y方向梁なので柱幅を減じる
        end

      case 2
        % 柱頭側
        dh = -stdh(ist);
        rx = 0; ry = 0;

        for idir = 1:2
          switch idir
            case PRM.X
              idm = idmc2mf2x(ic,:);
              col_dim = col_D;  % X方向梁には柱せい
            case PRM.Y
              idm = idmc2mf2y(ic,:);
              col_dim = col_B;  % Y方向梁には柱幅
          end

          for i = 1:length(idm)
            img = idm(i);
            if img==0
              continue
            end
            % 梁インデックス→梁断面ID→全断面IDの順で変換
            ids = idsg2s(idmg2sg(img));

            if mgstype(img)==PRM.RCRS
              % RC梁のみ対象
              H = secdim(ids,2);  % 梁せい
              r = H-dh+mglevel(img);

              % SS7仕様：柱寸法×αを減じる
              r = r - alfa * col_dim;

              switch idir
                case PRM.X
                  rx = max([rx, r]);
                case PRM.Y
                  ry = max([ry, r]);
              end
            end
          end
        end
    end

    % 方向別（負値は0に）、斜め柱の投影補正を適用
    lrcolumnx(ic,ij) = max(rx, 0) * proj_factor;
    lrcolumny(ic,ij) = max(ry, 0) * proj_factor;
  end
end

return
end

