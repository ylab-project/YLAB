function member_girder = set_member_girder_slab_block(dbc, com)
%set_member_girder_slab_block - スラブ協力幅データを読み込む
%
%   二重スラブ（上面・下面）を分離して格納する。
%   列13「床面」が「下面」の行は下面用フィールドに格納し、
%   それ以外は上面用フィールドに格納する。

data = dbc.get_data_block('スラブ協力幅');
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
[idx, idy, idz] = find_idxyz_girder(story_name, ...
  frame_name, coord_name, baseline);

% 梁部材番号
idmeg = find_idgirder_from_idxyz(idx, idy, idz, member_girder, ...
  [], baseline);

% スラブ協力幅・スラブ厚・材料・デッキ高さ
% 上面（既定）と下面（二重スラブ）を分離
slab_width = zeros(nmg,2);
slab_thickness = zeros(nmg,2);
slab_E = zeros(nmg,1); iddd = 1:com.nma;
deck_height = zeros(nmg,2);
slab_width_l = zeros(nmg,2);
slab_thickness_l = zeros(nmg,2);
slab_E_l = zeros(nmg,1);
deck_height_l = zeros(nmg,2);
has_col13 = size(data,2) >= 13;
for i=1:n
  ids = idmeg(i,:);
  ids = ids(ids > 0);
  if isempty(ids); continue; end

  % 下面判定（列13）
  is_lower = false;
  if has_col13
    v13 = data{i,13};
    if ~any(ismissing(v13))
      is_lower = strcmp(tochar(v13), '下面');
    end
  end

  % スラブデータの読み取り
  bl_ = data{i,6};  br_ = data{i,7};
  tl_ = data{i,8};  tr_ = tl_;
  if ~ismissing(data{i,10}); tr_ = data{i,10}; end
  dhl_ = 0; dhr_ = 0;
  if ~ismissing(data{i,11}); dhl_ = data{i,11}; end
  if ~ismissing(data{i,12}); dhr_ = data{i,12}; end
  material_name = data{i,9};
  idm_ = iddd(matches(material.name, material_name));
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
