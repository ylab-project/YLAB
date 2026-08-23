function element_force = set_legacy_girder_force_block(dbc, com)
%set_legacy_girder_force_block - 梁要素荷重を線材荷重テーブルへ変換する
%
%   element_force = set_legacy_girder_force_block(dbc, com) は、CSVの梁要素
%   荷重ブロックからCMQを読み取り、対象梁を全体部材番号へ解決した
%   線材荷重テーブルを返す旧入力アダプターである。部材端応力配列
%   への加算は calc_element_force_ar が行い、共通加算側へ梁番号を
%   渡さない。
%
%   入力引数:
%     dbc - DataBlockContainerオブジェクト
%     com - 共通オブジェクト
%
%   出力引数:
%     element_force - idme・ilc・ar・M0・位置値・重量分類・入力位置を
%                     列に持つ線材荷重テーブル。旧入力は1/4・3/4
%                     位置値を持たないためquarterはNaN、重量分類は0
%
%   備考:
%     分割梁の処理:
%       継続列あり → SS7が計算した各分割梁のCMQを直接適用
data = dbc.get_data_block('梁要素荷重');
n = size(data,1);
csv_rows = dbc.origrows(dbc.get_data_block_rows('梁要素荷重'));

% 共通定数
nlc = com.nlc;

% 共通配列
baseline = com.baseline;
member_girder = com.member.girder;
loadcase = com.loadcase;
idmg2m = member_girder.idme;

% --- 分割梁の継続列対応 ---
% SS7が分割梁の各部材CMQを2行で出力する場合、
% 19列目に継続フラグ(T/F)が付与される。
% 1行目(T): 1番目の分割梁（i端側）のCMQ
% 2行目:    2番目の分割梁（j端側）のCMQ（列1-5は空欄）

[is_continued, data] = read_continuation_flag(data, n);

% 荷重ケース名
name = cell(n,1);
for i=1:n
  name{i} = tochar(data{i,1});
end

% 層名・通り名
story_name = cell(n,1);

frame_name = cell(n,1);
coord_name = cell(n,2);
for i=1:n
  story_name{i} = tochar(data{i,2});
  frame_name{i} = tochar(data{i,3});
  coord_name(i,:) = tochar(data(i,4:5));
end

% 荷重ケース番号
iddlc = 1:nlc;
lcase = zeros(n,1);
for i=1:n
  lcase(i) = iddlc(matches(loadcase.name, name{i}));
end

% 通り番号・方向
[idx, idy, idz] = find_idxyz_girder(story_name, frame_name, ...
  coord_name, baseline);

% 個別梁検索
idmgs = find_idgirder_from_idxyz(idx, idy, idz, member_girder, ...
  [], baseline);

% 分割梁判定: idsplit連結ありの部材を含むか
% （通し梁はidsplit=0なので除外される。
%   idmgs には別方向の梁も含まれうるため、
%   idsplit の有無で分割梁を判定する）
% 分割梁なしのモデルではidsplitフィールドが存在しない
is_split = false(n, 1);
if isfield(member_girder, 'idsplit') || (istable(member_girder) && ...
    ismember('idsplit', member_girder.Properties.VariableNames))
  idsplit = member_girder.idsplit;
  for i = 1:n
    ids = idmgs(i, 1:nnz(idmgs(i,:)));
    if length(ids) > 1 && any(idsplit(ids) > 0)
      is_split(i) = true;
    end
  end
end

% 行数上限を入力行数として列配列を確保し、最後にtableを構築する
idme = zeros(n, 1);
ilc = zeros(n, 1);
ar = zeros(n, 12);
M0 = zeros(n, 1);
M0y = zeros(n, 1);
M0z = zeros(n, 1);
quarter = nan(n, 4);
wclass = zeros(n, 1);
wusage = zeros(n, 1);
wtype = zeros(n, 1);
block_name = repmat({'梁要素荷重'}, n, 1);
iblock = ones(n, 1);
irow = zeros(n, 1);
csv_row = zeros(n, 1);
nforce = 0;

for i = 1:n
  % 前行の継続で処理済みの行はスキップ
  if i > 1 && is_continued(i-1)
    continue
  end

  ilc_value = lcase(i);
  arunit = cell2mat(data(i,6:17));

  if is_continued(i) && is_split(i)
    % 継続行あり: SS7のCMQを各分割梁に直接適用
    % 按分せず、SS7が計算した各分割梁のCMQをそのまま使用
    idmeg_all = build_split_group(idmgs(i,:), idsplit);
    assert(length(idmeg_all) == 2, '継続行ペア処理は2分割梁のみ対応');
    arunit_2nd = cell2mat(data(i+1, 6:17));
    indices = nforce + (1:2);
    idme(indices) = idmg2m(idmeg_all(1:2));
    ilc(indices) = ilc_value;
    ar(indices, :) = [arunit; arunit_2nd];
    M0(indices) = [data{i, 18}; data{i+1, 18}];
    irow(indices) = [i; i+1];
    csv_row(indices) = csv_rows([i; i+1]);
    nforce = nforce + 2;

  elseif is_split(i)
    % 分割梁だが継続列なし: 未対応
    error('分割梁に継続列がありません（行%d）', i);

  else
    % 通常梁: 1部材の列値を保存する
    idmg = idmgs(i,1);
    if idmg == 0, continue, end
    nforce = nforce + 1;
    idme(nforce) = idmg2m(idmg);
    ilc(nforce) = ilc_value;
    ar(nforce, :) = arunit;
    M0(nforce) = data{i, 18};
    irow(nforce) = i;
    csv_row(nforce) = csv_rows(i);
  end
end

element_force = table(idme, ilc, ar, M0, M0y, M0z, quarter, ...
  wclass, wusage, wtype, block_name, iblock, irow, csv_row);
element_force = element_force(1:nforce, :);

return
end


function [is_continued, data] = read_continuation_flag(data, n)
%read_continuation_flag - 継続フラグの読み取りと基本検証
%
%   [is_continued, data] = read_continuation_flag(data, n) は、
%   梁要素荷重データの19列目から継続フラグを読み取り、
%   基本検証と継続行の列1-5補完を行う。
%
%   入力引数:
%     data - 梁要素荷重のcell配列 [n×mc]
%     n    - データ行数
%
%   出力引数:
%     is_continued - 継続フラグ [n×1 logical]
%     data         - 列1-5補完後のcell配列

% 19列目の読み取り（省略時はfalse）
mc = size(data, 2);
is_continued = false(n, 1);
if mc >= 19
  is_continued = matches(string(data(:, 19)), 'T');
end

% 基本検証
for i = 1:n
  if ~is_continued(i), continue, end
  if i == n
    throw_warn('Input', 'GirderForceContLastRow', i);
    is_continued(i) = false;
    continue
  end
  % 継続行の列1-5は空欄が仕様。非空なら警告
  if any(~ismissing(string(data(i+1, 1:5))))
    throw_warn('Input', 'GirderForceContRowNotEmpty', i+1);
  end
end

% 継続行の列1-5を親行からコピー
for i = 1:n
  if is_continued(i)
    data(i+1, 1:5) = data(i, 1:5);
  end
end

return
end


function idmeg_all = build_split_group(idmgs_row, idsplit)
%build_split_group - idsplitチェーンから分割梁グループを構築
%
%   idmeg_all = build_split_group(idmgs_row, idsplit) は、
%   idmgs_row内のidsplit>0の部材からidsplitを辿り、
%   分割梁グループを通り順（昇順）で返す。
%
%   入力引数:
%     idmgs_row - 梁番号の行ベクトル [1×m]
%     idsplit   - idsplit配列 [全梁数×1]
%
%   出力引数:
%     idmeg_all - 分割梁グループ [1×k]（昇順）

ids = idmgs_row(idmgs_row > 0);
% idsplit>0の部材を起点にする
start = ids(idsplit(ids) > 0);
ig1 = start(1);
idmeg_all = sort([ig1, idsplit(ig1)]);

return
end
