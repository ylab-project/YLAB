function data = create_girder_height_smooth_data(com)
%create_girder_height_smooth_data - 同一符号の梁せい平滑化データを作成
%
%   data = create_girder_height_smooth_data(com) は、S梁断面表の
%   同一符号を階方向に並べ、梁せい変数の一次差分行列を作成する。
%   断面登録済みセルだけを使い、RC梁と手動除外セルは対象外とする。
%   実部材の配置有無と配置数は判定に使用しない。
%
%   入力引数:
%     com - 共通データ構造体
%
%   出力引数:
%     data - 梁せい平滑化の固定データ（idvarH, Dmat）

section = com.section.girder;
is_steel = section.type ~= PRM.RCRS;
idsecg_steel = find(is_steel);
[symbol_names, ~, isymbol_steel] = unique(section.name(is_steel), ...
  'stable');
nsymbol = numel(symbol_names);
idsecg2symbol = zeros(height(section), 1);
idsecg2symbol(idsecg_steel) = isymbol_steel;

% S梁断面表の符号×階セルへH変数を配置する。
idstory2varH = zeros(com.nstory, nsymbol);
for i = 1:numel(idsecg_steel)
  idsecg = idsecg_steel(i);
  idstory = section.idstory(idsecg);
  idsymbol = idsecg2symbol(idsecg);
  if idstory2varH(idstory, idsymbol) > 0
    msg = ['S梁断面表で同じ符号と階が重複しています: ' ...
      section.name{idsecg} ', ' section.story_name{idsecg}];
    error('YLAB:DuplicateGirderSectionCell', msg)
  end
  idstory2varH(idstory, idsymbol) = section.idvar(idsecg, 1);
end

% 位置範囲で選ばれた梁の断面表セルを列から省く。
idsecg_ex = unique(com.member.girder.idsecg( ...
  com.exclusion.girder_smooth.idme));
idsecg_ex = idsecg_ex(is_steel(idsecg_ex));
idstory2varH(sub2ind(size(idstory2varH), section.idstory(idsecg_ex), ...
  idsecg2symbol(idsecg_ex))) = 0;

% 使用するH変数を局所IDへ変換し、同一符号列の差分を作る。
data.idvarH = unique(idstory2varH(idstory2varH > 0))';
if isempty(data.idvarH)
  data.Dmat = zeros(0, 0);
  return
end
id_lookup = zeros(1, max(data.idvarH));
id_lookup(data.idvarH) = 1:numel(data.idvarH);
idstory2H = zeros(size(idstory2varH));
is_section = idstory2varH > 0;
idstory2H(is_section) = id_lookup(idstory2varH(is_section));
data.Dmat = create_difference_matrix(idstory2H, numel(data.idvarH));

return
end
