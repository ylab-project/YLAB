function member_column = set_member_column_p1_block(dbc, com)
%set_member_column_p1_block - 柱配置データを読み込み柱部材テーブルを作成
%   （P1ブロック処理）
%
% 「柱配置」データブロックから柱の配置情報を読み込み、
% 名前からIDへの変換を行って柱部材テーブルを生成する。
% 断面番号・節点番号・変数番号はP2ブロックで設定される。
%
% 入力:
%   dbc: データブロックコントローラ
%   com: 共通データ構造体
%
% 出力:
%   member_column: 柱部材テーブル
%     .floor_name     - 柱脚階名 {n×1} cell
%     .top_floor_name - 柱頭階名 {n×1} cell
%     .coord_name     - 通り名 {n×2} cell（X, Y）
%     .section_name   - 断面符号 {n×1} cell
%     .type           - 柱タイプ [n×1]
%     .angle          - 強軸角度 [n×1] (度)
%     .idstory        - 層番号 [n×1]
%     .idfloor        - 階番号 [n×1]
%     .idx, .idy      - 通り番号 [n×2]
%     .idz            - Z座標番号 [n×2]（下端, 上端）
%     .idsecc         - 断面番号 [n×1]（P2で設定）
%     .idnode1/2      - 節点番号 [n×1]（P2で設定）
%     .cxl, .cyl      - 方向余弦 [n×3]（後続処理で設定）
%     .idvar          - 変数番号 [n×MAX_NSVAR]（P2で設定）
%
% データブロック形式（柱配置）:
%   列1: 階名, 列2: X通り, 列3: Y通り, 列4: 断面符号,
%   列5: 角度, 列6: (未使用), 列7: 柱頭階（省略可）
%
% See also: set_member_column_p2_block

% データブロックの読み込み
data = dbc.get_data_block('柱配置');
n = size(data,1);

% ダミー部材の検出
% 断面符号（列4）が空の行は無効とみなして除外
isvalid = true(1,n);
for i=1:n
  if ismissing(data{i,4})
    isvalid(i) = false;
  end
end
data = data(isvalid,:);
n = size(data,1);

% 階名の抽出（列1: 柱脚の階）
floor_name = cell(n,1);
for i=1:n
  floor_name{i} = tochar(data{i,1});
end

% 通り名の抽出（列2: X通り, 列3: Y通り）
coord_name = cell(n,2);
for i=1:n
  coord_name(i,:) = tochar(data(i,2:3));
end

% 断面符号の抽出（列4）
section_name = cell(n,1);
for i=1:n
  section_name{i} = tochar(data{i,4});
end

% 断面（強軸）の角度（列5、省略時は0）
angle = zeros(n,1);
for i=1:n
  if ~ismissing(data{i,5})
    angle(i) = data{i,5};
  end
end

% 層番号・階番号の設定
% 階名から対応するIDを検索
idfloor = zeros(n,1); iddf = 1:com.nfl;
idstory = zeros(n,1); idds = 1:com.nstory;
for i=1:n
  idfloor(i) = iddf(matches(com.floor.name, floor_name{i}));
  idstory(i) = idds(matches(com.story.floor_name, floor_name{i}));
end

% 通り番号の設定
% 通り名から対応するIDを検索し、Z座標は柱脚階から1層分を設定
idx = zeros(n,2); iddx = 1:size(com.baseline.x,1);
idy = zeros(n,2); iddy = 1:size(com.baseline.y,1);
idz = zeros(n,2); iddz = com.story.idz;
xlist = com.baseline.x.name;
ylist = com.baseline.y.name;
zlist = com.story.floor_name;
for i=1:n
  idx(i,:) = iddx(matches(xlist, coord_name{i,1}));
  idy(i,:) = iddy(matches(ylist, coord_name{i,2}));
  idz(i,1) = iddz(matches(zlist, floor_name{i}))-1;  % 柱脚Z座標
  idz(i,2) = idz(i,1)+1;                              % 柱頭Z座標（デフォルト: 1層上）
end

% 柱頭階の設定（列7、省略時は1層上）
% 複数層にまたがる柱の場合、柱頭のZ座標を上書き
top_floor_name = cell(n,1);
for i=1:n
  if ~ismissing(data{i,7})
    top_floor_name{i} = tochar(data{i,7});
    idz(i,2) = iddz(matches(zlist, top_floor_name{i}));
  end
end

% 以下はP2ブロックで設定されるプレースホルダ
% 断面番号（P2で断面マッチングにより設定）
idsecc = zeros(n,1);

% 節点番号（P2で座標から検索して設定）
idnode1 = zeros(n,1);
idnode2 = zeros(n,1);

% 変数番号（P2で断面から継承）
mvar = PRM.MAX_NSVAR;
idvar = zeros(n,mvar);

% 方向余弦（後続処理で設定）
cxl = zeros(n,3);
cyl = zeros(n,3);

% 柱タイプ（標準柱）
type = PRM.COLUMN_STANDARD*ones(n,1);

% 柱部材テーブルの生成
member_column = table(floor_name, top_floor_name, coord_name, section_name, type, ...
  angle, idstory, idfloor, idx, idy, idz, idsecc, idnode1, idnode2, ...
  cxl, cyl, idvar);

return
end
