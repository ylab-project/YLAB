function pf = column_axial_projection(cz)
%column_axial_projection - 通り心ベース cosθ から軸方向投影係数
%
%   pf = column_axial_projection(cz) は柱軸の Z 成分（通り心ベース）
%   から、剛域長・フェイス長・座屈用部材長を柱軸方向に投影するための
%   補正係数 1/|cos(θ)| を返します。水平柱（|cosθ|<1e-6）では 1 を
%   返します（ゼロ割回避）。
%
%   入力引数:
%     cz - 柱軸 Z 成分 = cos(θ) [n×1]、θ は柱軸と鉛直線のなす角
%
%   出力引数:
%     pf - 投影補正係数 [n×1]

pf = ones(size(cz));
mask = abs(cz) > 1e-6;
pf(mask) = 1 ./ abs(cz(mask));

return
end
