function cz_std = calc_column_standard_cosine_z(idnode1, idnode2, node)
%calc_column_standard_cosine_z - 柱の標準座標系Z方向余弦を計算
%
%   cz_std = calc_column_standard_cosine_z(idnode1, idnode2, node) は、
%   柱両端の通り心座標から柱軸のZ方向余弦を計算する。Z座標には
%   標準階高ベースの値を使い、斜め柱の投影補正に用いる。
%
%   入力引数:
%     idnode1 - 柱脚節点番号 [n x 1]
%     idnode2 - 柱頭節点番号 [n x 1]
%     node    - 節点座標テーブル
%
%   出力引数:
%     cz_std - 標準座標系における柱軸のZ方向余弦 [n x 1]

n = length(idnode1);
cz_std = nan(n,1);
isvalid = idnode1 > 0 & idnode2 > 0;
in1 = idnode1(isvalid);
in2 = idnode2(isvalid);
dx = node.x(in2) - node.x(in1);
dy = node.y(in2) - node.y(in1);
dz = node.z_standard(in2) - node.z_standard(in1);
length_std = sqrt(dx.^2 + dy.^2 + dz.^2);
cz_std(isvalid) = dz ./ length_std;

return
end
