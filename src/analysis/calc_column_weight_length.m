function [lm_weight, lm_lower_extension] = calc_column_weight_length( ...
  member_column, member_girder, floor, node, stype_sec, ...
  idsecc2sec, idsecg2sec, secdim)
%calc_column_weight_length - 柱荷重計算用の部材長を算出する
%
%   [lm_weight, lm_lower_extension] = calc_column_weight_length( ...
%   member_column, member_girder, floor, node, stype_sec, ...
%   idsecc2sec, idsecg2sec, secdim) は、柱の自重・仕上重量に
%   用いる部材長と、柱脚節点より下に延びる長さを計算する。
%
%   SS7計算編4.1.2の梁天端間の長さを、標準階高、節点移動、
%   梁レベルから求める。最下層や下層に柱がない箇所では、
%   柱と同じ構造種別の梁せいを加える。一本部材の指定がある
%   梁の中間箇所に柱頭が接続する場合は梁下面までとする。
%   ブレース分割柱の柱脚節点・梁面は基礎梁内の下側要素から採る。
%
%   入力引数:
%     member_column - 柱部材構造体。BODYのidsplitはFOUNDATION番号
%     member_girder - 梁部材構造体
%     floor         - フロアテーブル（standard_height）
%     node          - 節点構造体（座標、dz、idz）
%     stype_sec     - 断面種別配列 [nsec×1]
%     idsecc2sec    - 柱断面番号から統一断面番号への対応
%     idsecg2sec    - 梁断面番号から統一断面番号への対応
%     secdim        - 断面寸法配列 [nsec×ncol] (mm)
%
%   出力引数:
%     lm_weight          - 荷重計算用部材長 [nmec×1] (mm)
%     lm_lower_extension - 柱脚節点より下に延びる長さ [nmec×1] (mm)

nmec = numel(member_column.idme);
idmc2n1 = member_column.idnode1;
idmc2n2 = member_column.idnode2;
ctype = member_column.type;
idmc2base = (1:nmec)';
ids = ctype == PRM.COLUMN_FOR_BRACE_BODY;
if any(ids)
  idmc2base(ids) = member_column.idsplit(ids);
end
idmc2nbase = idmc2n1(idmc2base);
idmg2s = idsecg2sec(member_girder.idsecg);
idmc2s = idsecc2sec(member_column.idsecc);
is_steel_c = stype_sec(idmc2s) ~= PRM.RCRS;
is_steel_g = [false; stype_sec(idmg2s) ~= PRM.RCRS];
Hg = [0; calc_girder_section_depth(secdim, stype_sec(idmg2s), idmg2s)];

% BODYの柱脚はFOUNDATIONの節点・梁面を用いる。
idg1 = [member_column.idmeg_face1x(idmc2base, :) ...
  member_column.idmeg_face1y(idmc2base, :)];
idg2 = [member_column.idmeg_face2x member_column.idmeg_face2y];
idnode1 = [0; member_girder.idnode1];
idnode2 = [0; member_girder.idnode2];
isthrough1 = [false; member_girder.isthrough(:, 1)];
isthrough2 = [false; member_girder.isthrough(:, 2)];
glv = [-inf; member_girder.level];
max_glv1 = max(reshape(glv(idg1 + 1), size(idg1)), [], 2);
max_glv2 = max(reshape(glv(idg2 + 1), size(idg2)), [], 2);
max_glv1(~any(idg1, 2)) = 0;
max_glv2(~any(idg2, 2)) = 0;

% 標準階高の加算順を保ち、節点移動と梁天端の高低差を反映する。
lm_weight = zeros(nmec, 1);
lm_lower_extension = zeros(nmec, 1);
standard_height = floor.standard_height;
for ic = 1:nmec
  if ctype(ic) == PRM.COLUMN_FOR_BRACE_FOUNDATION
    continue
  end
  ifl1 = node.idz(idmc2nbase(ic));
  ifl2 = node.idz(idmc2n2(ic)) - 1;
  if ifl2 <= numel(standard_height)
    lm_weight(ic) = sum(standard_height(ifl1:ifl2)) ...
      - node.dz(idmc2nbase(ic)) + node.dz(idmc2n2(ic));
  end
end
lm_weight = lm_weight + max_glv2 - max_glv1;

% 最下層・下層柱抜けでは、通し梁の中間端以外の梁せいを加える。
is_first_story = member_column.idstory == min(member_column.idstory);
is_lower_column_missing = ~is_first_story & ~ismember(idmc2nbase, ...
  idmc2n2) & ctype ~= PRM.COLUMN_FOR_BRACE_FOUNDATION;
is_intermediate = is_intermediate_connection(idmc2nbase, idg1, ...
  idnode1, idnode2, isthrough1, isthrough2);
ids = idg1 > 0 & reshape(is_steel_g(idg1 + 1), size(idg1)) == ...
  is_steel_c & ~is_intermediate & (is_first_story | ...
  is_lower_column_missing);
height = max(reshape(Hg(idg1 + 1), size(idg1)) .* ids, [], 2);
lm_weight = lm_weight + height;
lm_lower_extension(is_lower_column_missing) = ...
  height(is_lower_column_missing);

% 柱頭は同じ構造種別の通し梁の中間箇所では梁せいを控除する。
is_intermediate = is_intermediate_connection(idmc2n2, idg2, ...
  idnode1, idnode2, isthrough1, isthrough2);
ids = idg2 > 0 & reshape(is_steel_g(idg2 + 1), size(idg2)) == ...
  is_steel_c & is_intermediate;
[found, column] = max(ids, [], 2);
idg = idg2(sub2ind(size(idg2), (1:nmec)', column));
lm_weight = lm_weight - Hg(idg + 1) .* found;

% 斜め柱の水平移動を反映し、基礎梁内の分割要素は自重対象外とする。
dx = node.x(idmc2n2) - node.x(idmc2n1);
dy = node.y(idmc2n2) - node.y(idmc2n1);
horizontal = sqrt(dx.^2 + dy.^2);
ids = horizontal > 0;
lm_weight(ids) = sqrt(lm_weight(ids).^2 + horizontal(ids).^2);
ids = ctype == PRM.COLUMN_FOR_BRACE_FOUNDATION;
lm_weight(ids) = 0;
lm_lower_extension(ids) = 0;

return
end

function is_intermediate = is_intermediate_connection(idnode, idg, ...
  idnode1, idnode2, isthrough1, isthrough2)
%is_intermediate_connection - 柱の接続点が通し梁の中間端かを判定する
%
%   is_intermediate = is_intermediate_connection(idnode, idg, ...
%     idnode1, idnode2, isthrough1, isthrough2) は、
%   梁始端との一致を優先し、該当する端の通し指定を返す。
%
%   入力引数:
%     idnode - 柱端の節点番号 [nmec×1]
%     idg - 柱面の梁番号 [nmec×4]（0は梁なし）
%     idnode1, idnode2 - 先頭に0を置いた梁端節点番号
%     isthrough1, isthrough2 - 先頭にfalseを置いた梁端の通し指定
%
%   出力引数:
%     is_intermediate - 通し梁の中間端への接続 [nmec×4]

is_start = reshape(idnode1(idg + 1), size(idg)) == idnode;
is_intermediate = (is_start & reshape(isthrough1(idg + 1), ...
  size(idg))) | (~is_start & reshape(idnode2(idg + 1), ...
  size(idg)) == idnode & reshape(isthrough2(idg + 1), size(idg)));

return
end
