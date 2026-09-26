function lfgirder = comp_face_length_girder(secdim, stype, idmg2sfl, ...
  idmg2sfr, idscb2s, cbsDf, cxl, idmg2n, idsup2n)
%comp_face_length_girder - 梁端部のフェイス位置を計算
%
%   lfgirder = comp_face_length_girder(secdim, stype, idmg2sfl, ...
%     idmg2sfr, idscb2s, cbsDf, cxl, idmg2n, idsup2n) は、梁端部の
%   柱面位置を計算する。
%
%   柱面寸法は calc_column_outer_size のX・Y方向の外形（H形鋼柱は
%   向きに応じてせいとフランジ幅、RC柱は secdim 第1列の断面寸法）
%   を用いる。斜め梁の場合、梁の水平方向と柱外形（矩形）の交点
%   距離を幾何学的に計算する。
%   柱脚Dfは支点のある梁端部にのみ適用する。
%
%   入力引数:
%     secdim   - 断面寸法配列 [nsec×ncol]
%     stype    - 断面タイプ [nsec×1]
%     idmg2sfl - 梁左端の接続柱断面ID [nmg×ncol]
%     idmg2sfr - 梁右端の接続柱断面ID [nmg×ncol]
%     idscb2s  - CBS断面ID [ncbs×1]
%     cbsDf    - CBS断面のDf値 [ncbs×1]
%     cxl      - 梁の方向余弦（X軸方向）[nmg×3]
%     idmg2n   - 梁端節点ID [nmg×2]（左端、右端）
%     idsup2n  - 支点節点ID [nsup×1]
%
%   出力引数:
%     lfgirder - 梁端部フェイス位置 [nmg×2]（左端、右端）

nmg = size(idmg2sfl,1);

% 柱面寸法（X方向、Y方向）。RC柱は第1列の断面寸法
outer_size = calc_column_outer_size(secdim, stype, 1);

face_dimension_x = zeros(nmg, 2);
face_dimension_y = zeros(nmg, 2);

for ig=1:nmg
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

      % 接続する柱と柱脚のうち最大の柱面を方向別に採る
      sss = outer_size(ids(ids>0), :);
      face_dimension_x(ig, ilr) = max([sss(:,1); Df]);
      face_dimension_y(ig, ilr) = max([sss(:,2); Df]);
    end
  end
end

[lfgirder, ~, ~] = calc_girder_face_deduct(face_dimension_x, ...
  face_dimension_y, cxl);

return
end
