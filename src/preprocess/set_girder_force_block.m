function [felement, ar, M0] = set_girder_force_block(dbc, com)
%set_girder_force_block - 梁要素荷重を読み込み等価節点力を計算
%
%   [felement, ar, M0] = set_girder_force_block(dbc, com) は、
%   CSVの梁要素荷重ブロックからCMQを読み取り、
%   要素座標系の等価節点力(ar,M0)と
%   全体座標系の等価節点力(felement)を計算する。
%
%   入力引数:
%     dbc - DataBlockContainerオブジェクト
%     com - 共通オブジェクト
%
%   出力引数:
%     felement - 全体座標系の節点単位等価節点力 [nnode×6×nlc]
%     ar       - 要素座標系の等価節点力 [nm×12×nlc]
%     M0       - 単純梁中央モーメント [nm×nlc]
%
%   備考:
%     分割梁の処理:
%       継続列あり → SS7が計算した各分割梁のCMQを直接適用
data = dbc.get_data_block('梁要素荷重');
n = size(data,1);

% 共通定数
nlc = com.nlc;
nm = com.nme;
nnode = com.nnode;

% 共通配列
baseline = com.baseline;
member_girder = com.member.girder;
js = com.member.girder.idnode1;
je = com.member.girder.idnode2;
loadcase = com.loadcase;
cxl = member_girder.cxl;
cyl = member_girder.cyl;
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
if isfield(member_girder, 'idsplit') || ...
    (istable(member_girder) && ...
    ismember('idsplit', member_girder.Properties.VariableNames))
  idsplit = member_girder.idsplit;
  for i = 1:n
    ids = idmgs(i, 1:nnz(idmgs(i,:)));
    if length(ids) > 1 && any(idsplit(ids) > 0)
      is_split(i) = true;
    end
  end
end

% 部材にかかる中間荷重の等価節点力の総和
ar = zeros(nm,12,nlc);
M0 = zeros(nm,nlc);

% 部材座標第3軸
czl = cross(cxl, cyl, 2);

% 要素荷重のセット
%   ※座標変換行列は[T]^Tなので注意
felement = zeros(nnode, 6, nlc);
for i = 1:n
  % 前行の継続で処理済みの行はスキップ
  if i > 1 && is_continued(i-1)
    continue
  end

  ilc = lcase(i);
  arunit = cell2mat(data(i,6:17));

  if is_continued(i) && is_split(i)
    % 継続行あり: SS7のCMQを各分割梁に直接適用
    % 按分せず、SS7が計算した各分割梁のCMQをそのまま使用
    idmeg_all = build_split_group(idmgs(i,:), idsplit);
    assert(length(idmeg_all) == 2, '継続行ペア処理は2分割梁のみ対応');

    % 1行目 → 1番目の分割梁（i端側）
    [felement, ar, M0] = apply_single_girder_force( ...
      idmeg_all(1), arunit, data{i, 18}, ilc, felement, ...
      ar, M0, idmg2m, cxl, cyl, czl, js, je);

    % 2行目 → 2番目の分割梁（j端側）
    arunit_2nd = cell2mat(data(i+1, 6:17));
    [felement, ar, M0] = apply_single_girder_force( ...
      idmeg_all(2), arunit_2nd, data{i+1, 18}, ilc, ...
      felement, ar, M0, idmg2m, cxl, cyl, czl, js, je);

  elseif is_split(i)
    % 分割梁だが継続列なし: 未対応
    error('分割梁に継続列がありません（行%d）', i);

  else
    % 通常梁: 1部材に直接適用
    idmg = idmgs(i,1);
    if idmg == 0, continue, end
    [felement, ar, M0] = apply_single_girder_force( ...
      idmg, arunit, data{i, 18}, ilc, felement, ar, ...
      M0, idmg2m, cxl, cyl, czl, js, je);
  end
end

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


function [felement, ar, M0] = apply_single_girder_force( ...
  ig, arunit, M0_val, ilc, felement, ar, M0, idmg2m, ...
  cxl, cyl, czl, js, je)
%apply_single_girder_force - 1部材に梁要素荷重を適用
%
%   [felement, ar, M0] = apply_single_girder_force(ig, arunit,
%     M0_val, ilc, felement, ar, M0, idmg2m, cxl, cyl, czl,
%     js, je) は、
%   梁igの要素座標系CMQ(arunit)をar/M0に加算し、
%   全体座標系に変換した節点単位等価節点力をfelementに加算する。
%   剛床偏心 Mz は node_to_dof_vec で集約時に加算される。
%
%   入力引数:
%     ig      - 梁部材番号（梁インデックス）
%     arunit  - 要素座標系CMQ [1×12]
%     M0_val  - 単純梁中央モーメント（スカラー）
%     ilc     - 荷重ケース番号
%     felement - 全体座標系の節点単位等価節点力 [nnode×6×nlc]
%     ar      - 要素座標系の等価節点力 [nm×12×nlc]
%     M0      - 単純梁中央モーメント [nm×nlc]
%     idmg2m  - 梁番号→全体部材番号の変換配列
%     cxl,cyl,czl - 部材座標系の方向余弦
%     js,je   - 部材のi端・j端節点番号
%
%   出力引数:
%     felement - 更新後の節点単位等価節点力
%     ar       - 更新後の要素座標系等価節点力
%     M0       - 更新後の単純梁中央モーメント

idm = idmg2m(ig);
ar(idm,:,ilc) = ar(idm,:,ilc) + arunit;
M0(idm, ilc) = M0(idm, ilc) + M0_val;

tt = [cxl(ig,:)' cyl(ig,:)' czl(ig,:)'];

% felement: i端
in = js(ig);
fi = tt * arunit(1:3)';
mi = tt * arunit(4:6)';
felement(in, :, ilc) = felement(in, :, ilc) + reshape([fi; mi], 1, 6);

% felement: j端
in = je(ig);
fj = tt * arunit(7:9)';
mj = tt * arunit(10:12)';
felement(in, :, ilc) = felement(in, :, ilc) + reshape([fj; mj], 1, 6);

return
end
