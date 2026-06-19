function [lfcolumnx, lfcolumny] = comp_face_length_column(secdim, stdh, ...
  column_idz, girder_level, stype, idmc2sf1x, idmc2sf2x, ~, idmc2sf2y, ...
  ~, idmc2mf1x, idmc2mf2x, idmc2mf1y, idmc2mf2y, gcxl, ~, cz_std)
%comp_face_length_column - 柱のフェイス長を計算
%
%   [lfcolumnx, lfcolumny] = comp_face_length_column(secdim, stdh,
%     column_idz, girder_level, stype, idmc2sf1x, idmc2sf2x, ~,
%     idmc2sf2y, ~, idmc2mf1x, idmc2mf2x, idmc2mf1y, idmc2mf2y,
%     gcxl, gcyl, cz_std) は、柱の梁フェイス位置までの長さを
%   X/Y方向別・柱脚柱頭別に計算します。斜め柱の場合は通り心ベースで
%   柱軸方向に投影補正します。
%
%   入力引数:
%     secdim       - 断面寸法行列 [nsec×4]
%     stdh         - 階高配列 [nstory×1]
%     column_idz   - 柱のZ座標範囲 [nmc×2]（列1:下端, 列2:上端）
%     girder_level - 梁レベル配列 [nmg×1]
%     stype        - 断面タイプ配列 [nsec×1]
%     idmc2sf1x    - 柱脚側X方向梁の断面ID配列 [nmc×*]（未使用）
%     idmc2sf2x    - 柱頭側X方向梁の断面ID配列 [nmc×*]
%     idmc2sf2y    - 柱頭側Y方向梁の断面ID配列 [nmc×*]
%     idmc2mf1x    - 柱脚側X方向梁ID配列 [nmc×*]
%     idmc2mf2x    - 柱頭側X方向梁ID配列 [nmc×*]
%     idmc2mf1y    - 柱脚側Y方向梁ID配列 [nmc×*]
%     idmc2mf2y    - 柱頭側Y方向梁ID配列 [nmc×*]
%     gcxl         - 梁の局所X方向余弦 [nmg×3]
%     cz_std       - 通り心ベース方向余弦Z成分 = cos(θ) [nmc×1]
%                    θは柱軸（通り心）と鉛直線のなす角度
%
%   出力引数:
%     lfcolumnx - X方向柱フェイス長 [nmc×2]（列1:柱脚側, 列2:柱頭側）
%     lfcolumny - Y方向柱フェイス長 [nmc×2]（列1:柱脚側, 列2:柱頭側）
%
%   備考:
%     - 柱頭側はSS7仕様に従い、梁断面タイプ別に梁せいを参照
%       （S梁: 列1、RC梁: 列2）し、梁の方向余弦Z成分で補正する。
%     - 負値は0に丸める。
%
%   参考:
%     calc_rigid_zone_column, comp_face_length_girder, update_geometry

% 定数
nmc = size(idmc2sf1x,1);
nstory = size(stdh,1);

% 計算の準備
lfcolumnx = zeros(nmc,2);
lfcolumny = zeros(nmc,2);
proj_all = column_axial_projection(cz_std);

% 柱の梁面長さ
for ic=1:nmc
  proj_factor = proj_all(ic);
  for ij=1:2
    switch ij
      case 1
        % 柱脚側
        ist = column_idz(ic,1);
        if ist>nstory
          % TODO: とりあえず
          continue
        end
        dh = -stdh(ist);
        for idir = 1:2
          switch idir
            case PRM.X
              idmg = idmc2mf1x(ic,:);
            case PRM.Y
              idmg = idmc2mf1y(ic,:);
          end
          if any(idmg>0)
            gldh = zeros(length(idmg),1)+dh;
            gldh(idmg>0) = gldh(idmg>0) + girder_level(idmg(idmg>0));
            gldh = gldh(idmg>0);
          else
            gldh = 0;
          end
          gldh = max(gldh);
          switch idir
            case PRM.X
              lfcolumnx(ic,ij) = gldh * proj_factor;
            case PRM.Y
              lfcolumny(ic,ij) = gldh * proj_factor;
          end
        end
      case 2
        % 柱頭側
        ist = column_idz(ic,2);
        if ist>nstory
          % TODO: とりあえず
          continue
        end
        dh = -stdh(ist);
        for idir = 1:2
          switch idir
            case PRM.X
              ids = idmc2sf2x(ic,:);
              idmg = idmc2mf2x(ic,:);
            case PRM.Y
              ids = idmc2sf2y(ic,:);
              idmg = idmc2mf2y(ic,:);
          end
          if any(idmg>0)
            gldh = zeros(length(idmg),1)-dh;
            % idmg>0 を共通フィルタとして使用
            valid = idmg > 0;
            ids_valid = ids(valid);
            H_girder = calc_girder_section_depth( ...
              secdim, stype(ids_valid), ids_valid);
            H_proj = calc_girder_vertical_depth_projection( ...
              H_girder, gcxl(idmg(valid), :));
            gldh(valid) = gldh(valid) + H_proj ...
              - girder_level(idmg(valid));
            gldh = gldh(valid);
          else
            gldh = 0;
          end
          gldh = max(gldh);
          switch idir
            case PRM.X
              lfcolumnx(ic,ij) = gldh * proj_factor;
            case PRM.Y
              lfcolumny(ic,ij) = gldh * proj_factor;
          end
        end
    end
  end
end

% 負値は0にする
lfcolumnx(lfcolumnx<0) = 0;
lfcolumny(lfcolumny<0) = 0;
return
end

