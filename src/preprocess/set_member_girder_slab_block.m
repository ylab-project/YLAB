function member_girder = set_member_girder_slab_block(dbc, com)
%set_member_girder_slab_block - スラブ協力幅データを読み込む
%
%   member_girder = set_member_girder_slab_block(dbc, com) は、
%   スラブ協力幅と寸法を梁の左右・上下面ごとに読み込む。
%   デッキ高さは空欄をNaN、明示された0を高さ0のデッキ床とする。
%   列13「床面」が「下面」の行は下面へ、それ以外は上面へ格納する。
%
%   入力引数:
%     dbc - 入力CSVのブロック読込オブジェクト
%     com - 通り・材料・梁部材の情報を持つ構造体
%
%   出力引数:
%     member_girder - スラブ協力幅・寸法を設定した梁部材情報

data = dbc.get_data_block('スラブ協力幅');
% 右側スラブ厚・デッキ高さ・床面の省略列を空欄として扱う。
data(:,end+1:13) = {missing};
n = size(data,1);

% 共通定数
nmg = com.nmeg;

% 共通配列
baseline = com.baseline;
material = com.material;
member_girder = com.member.girder;

% 層名・通り名
story_name = cell(n,1);
frame_name = cell(n,1);
coord_name = cell(n,2);
for i=1:n
  story_name{i} = tochar(data{i,1});
  frame_name{i} = tochar(data{i,2});
  coord_name(i,:) = tochar(data(i,3:4));
end

% 断面符号
section_name = cell(n,1);
for i=1:n
  section_name{i} = tochar(data{i,5});
end

% 通り番号・方向
[idx, idy, idz] = find_idxyz_girder(story_name, frame_name, ...
  coord_name, baseline);

% 梁部材番号
idmeg = find_idgirder_from_idxyz(idx, idy, idz, member_girder, ...
  [], baseline);

% スラブ協力幅・スラブ厚・材料・デッキ高さ
% 上面（既定）と下面（二重スラブ）を分離
slab_width = zeros(nmg,2);
slab_thickness = zeros(nmg,2);
slab_E = zeros(nmg,1);
deck_height = NaN(nmg,2);
slab_width_l = zeros(nmg,2);
slab_thickness_l = zeros(nmg,2);
slab_E_l = zeros(nmg,1);
deck_height_l = NaN(nmg,2);
for i=1:n
  ids = idmeg(i,:);
  ids = ids(ids > 0);
  if isempty(ids); continue; end

  % 下面判定（列13）
  is_lower = strcmp(tochar(data{i,13}), '下面');

  % スラブデータの読み取り
  bl_ = data{i,6};  br_ = data{i,7};
  tl_ = data{i,8};  tr_ = tl_;
  if ~ismissing(data{i,10}); tr_ = data{i,10}; end
  dhl_ = read_deck_height(data, i, 11, dbc);
  dhr_ = read_deck_height(data, i, 12, dbc);
  material_name = tochar(data{i,9});
  idm_ = find(matches(material.name, material_name));
  E_ = material.E(idm_);

  % 上面/下面に直接代入
  if is_lower
    slab_width_l(ids,1) = bl_;
    slab_width_l(ids,2) = br_;
    slab_thickness_l(ids,1) = tl_;
    slab_thickness_l(ids,2) = tr_;
    slab_E_l(ids) = E_;
    deck_height_l(ids,1) = dhl_;
    deck_height_l(ids,2) = dhr_;
  else
    slab_width(ids,1) = bl_;
    slab_width(ids,2) = br_;
    slab_thickness(ids,1) = tl_;
    slab_thickness(ids,2) = tr_;
    slab_E(ids) = E_;
    deck_height(ids,1) = dhl_;
    deck_height(ids,2) = dhr_;
  end
end

% 結果の保存
member_girder.slab_width = slab_width;
member_girder.slab_thickness = slab_thickness;
member_girder.slab_E = slab_E;
member_girder.deck_height = deck_height;
member_girder.slab_width_lower = slab_width_l;
member_girder.slab_thickness_lower = slab_thickness_l;
member_girder.slab_E_lower = slab_E_l;
member_girder.deck_height_lower = deck_height_l;

return
end

function value = read_deck_height(data, irow, icol, dbc)
%read_deck_height - デッキ高さの空欄と数値を区別して読む
%
%   value = read_deck_height(data, irow, icol, dbc) は、デッキ高さを
%   NaN（空欄）または0以上の有限値として読み込む。入力範囲は
%   SS7入力マニュアル7.11のデッキ高さに従う。
%
%   入力引数:
%     data - スラブ協力幅の入力セル配列
%     irow - ブロック内の行番号
%     icol - 左右のデッキ高さの列番号
%     dbc  - 元CSV行を示してエラー通知する読込オブジェクト
%
%   出力引数:
%     value - 入力された高さ [mm]。通常の床はNaN

[value, is_valid] = normalize_numeric_cell(data{irow,icol});
if ~is_valid
  dbc.throw_dat_err('スラブ協力幅', irow, 'Input', ...
    'InvalidNumericValue', sprintf('デッキ高さ（%d列目）', icol));
end
if value < 0 || value > PRM.MAX_DECK_HEIGHT
  dbc.throw_dat_err('スラブ協力幅', irow, 'Input', 'InvalidDeckHeight', ...
    icol, PRM.MAX_DECK_HEIGHT, value);
end

return
end
