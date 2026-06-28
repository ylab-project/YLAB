function member_girder = set_member_girder_block(dbc, com)
%set_member_girder_block - 大梁配置ブロックの読み込みと梁部材テーブル作成
data = dbc.get_data_block('大梁配置');
n = size(data,1);

% 共通配列
section_girder = com.section.girder;
node = com.node;
x = node.x;
y = node.y;
z = node.z;

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

% 断面（強軸）の角度
angle = zeros(n,1);
for i=1:n
  if ~ismissing(data{i,6})
    angle(i) = data{i,6};
  end
end

% 合成梁効果
comp_effect = zeros(n,1);
for i=1:n
  val = data{i,7};
  if ~ismissing(val)
    comp_effect(i) = val;
  end
end

% 横補剛間隔
Lb = nan(n,1);
for i=1:n
  val = data{i,8};
  if ~ismissing(val)
    Lb(i) = val;
  end
end

% 反転配置
ismirrored = false(n,1);
for i=1:n
  val = tochar(data{i,9});
  if ismissing(val)
    continue
  end
  if val=='T'
    ismirrored(i) = true;
  end
end

% 層番号
idstory = zeros(n,1); idds = 1:com.nstory;
for i=1:n
  idstory(i) = idds(matches(com.story.name, story_name{i}));
end

% 通り番号・方向
[idx, idy, idz, idir, idzn] = find_idxyz_girder(story_name, ...
  frame_name, coord_name, com.baseline);

% 断面番号
idsecg = zeros(n,1); iddd = 1:com.nsecg;
for i=1:n
  % id = iddd(matches(section_girder.name, section_name{i}) ...
  %   & section_girder.idz==idz(i));
  id = iddd(matches(section_girder.name, section_name{i}) ...
    & section_girder.idznominal==idzn(i,1));
  if isempty(id)
    id = iddd(matches(section_girder.full_name, section_name{i}));
  end
  idsecg(i) = id;
end

% 断面種別
section_type = section_girder.type(idsecg);

% 節点番号
idnode1 = find_idnode_from_idxyz(idx(:,1), idy(:,1), idz(:,1), node);
idnode2 = find_idnode_from_idxyz(idx(:,2), idy(:,2), idz(:,2), node);

% 変数番号
mvar = PRM.MAX_NSVAR;
idvar = zeros(n,mvar);
for i=1:n
  idvar(i,:) = section_girder.idvar(idsecg(i),:);
end

% 方向余弦の計算
an = deg2rad(angle);
[cyl, cxl] = ystar(x(idnode1), y(idnode1), z(idnode1), ...
  x(idnode2), y(idnode2), z(idnode2), an);

% 梁タイプ（デフォルト: GIRDER_STANDARD）
type = zeros(n,1);  % GIRDER_STANDARD = 0

% 結果の保存
level = zeros(n, 1);
member_girder = table(story_name, frame_name, coord_name, ...
  section_name, section_type, type, angle, comp_effect, Lb, ismirrored, ...
  idstory, idir, idx, idy, idz, idzn, idsecg, idnode1, idnode2, ...
  cxl, cyl, idvar, level);

% 基礎梁フラグ（両端が支点節点なら基礎梁）
idsup2n = com.support.idnode;
member_girder.isfg = ismember(idnode1, idsup2n) & ...
  ismember(idnode2, idsup2n);

% WFS部材番号の設定
nmeg = size(member_girder,1);
idmewfs = zeros(nmeg,1);
is_wfs = (section_type == PRM.WFS);
idmewfs(is_wfs) = 1:sum(is_wfs);
member_girder.idmewfs = idmewfs;

return
end
