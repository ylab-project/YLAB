function lfgirder = comp_face_length_girder(...
  secdim, idmg2sfl, idmg2sfr, idscb2s, cbsDf, cxl, cyl, idmg2n, idsup2n)
%comp_face_length_girder - 梁端部のフェイス位置を計算
%
%   lfgirder = comp_face_length_girder(secdim, idmg2sfl, idmg2sfr, ...
%     idscb2s, cbsDf, cxl, cyl, idmg2n, idsup2n) は、梁端部の柱面位置を
%   計算する。
%
%   斜め梁の場合、梁軸方向と柱断面（矩形）の交点距離を幾何学的に計算する。
%   柱脚Dfは支点のある梁端部にのみ適用する。
%
%   入力引数:
%     secdim   - 断面寸法配列 [nsec×ncol]
%     idmg2sfl - 梁左端の接続柱断面ID [nmg×ncol]
%     idmg2sfr - 梁右端の接続柱断面ID [nmg×ncol]
%     idscb2s  - CBS断面ID [ncbs×1]
%     cbsDf    - CBS断面のDf値 [ncbs×1]
%     cxl      - 梁の方向余弦（X軸方向）[nmg×3]
%     cyl      - 梁の方向余弦（Y軸方向）[nmg×3]
%     idmg2n   - 梁端節点ID [nmg×2]（左端、右端）
%     idsup2n  - 支点節点ID [nsup×1]
%
%   出力引数:
%     lfgirder - 梁端部フェイス位置 [nmg×2]（左端、右端）

% 定数
nmg = size(idmg2sfl,1);
TOL = 1e-6;

% 計算の準備
lfgirder = zeros(nmg,2);
czl = cross(cxl, cyl, 2);

% 梁の柱面長さ
for ig=1:nmg
  % 梁軸方向の水平成分（XY平面）
  cx = cxl(ig,1);
  cy = cxl(ig,2);
  cz = czl(ig,3);

  for ilr=1:2
    switch ilr
      case 1
        ids = idmg2sfl(ig,:);
      case 2
        ids = idmg2sfr(ig,:);
    end

    Df = 0;
    if any(ids>0)
      % 梁端節点が支点かどうかを確認
      is_support = any(idmg2n(ig,ilr) == idsup2n);

      % 支点のある梁端部でのみ柱脚Dfを考慮
      for i = 1:length(ids)
        idsc = ids(i);
        if idsc > 0 && any(idsc==idscb2s) && is_support
          Df = max(Df, cbsDf(idsc==idscb2s));
        end
      end

      % 柱断面寸法（HSS: D=B=第1列、矩形の場合は将来対応）
      sss = secdim(ids(ids>0),1);
      D = max([sss; Df]);  % 柱断面の代表寸法
      B = D;  % HSS（正方形）を仮定

      % 梁軸と矩形柱断面の交点距離を計算
      if abs(cx) < TOL && abs(cy) < TOL
        % 鉛直梁（水平成分なし）の場合
        face = D/2;
      elseif abs(cx) < TOL
        % Y方向のみに傾く梁
        face = B/2;
      elseif abs(cy) < TOL
        % X方向のみに傾く梁
        face = D/2;
      else
        % 斜め梁: 矩形との交点距離
        % tx = 梁軸がX方向に(D/2)進むのに必要な距離
        % ty = 梁軸がY方向に(B/2)進むのに必要な距離
        tx = (D/2) / abs(cx);
        ty = (B/2) / abs(cy);
        face = min(tx, ty);
      end

      % Z方向の勾配補正（斜め梁の投影長さ）
      lfgirder(ig,ilr) = face / abs(cz);
    end
  end
end

return
end
