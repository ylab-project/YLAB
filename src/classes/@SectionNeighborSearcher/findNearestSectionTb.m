function [tbsec, id] = ...
  findNearestSectionTb(obj, idslist)
%findNearestSectionTb TB断面の最近傍選択
%   [tbsec, id] = findNearestSectionTb(obj, idslist) は、
%   初期寸法から最近傍のTB断面を選択します。
%
%   TB断面は設計変数を持たない（nvar=0）ため、
%   初期dimension（shape_code, A）で断面リストを検索する。
%
%   検索アルゴリズム:
%     1. shape_code が一致するエントリをフィルタ
%     2. A（全断面積）が最も近い断面を選択
%
%   入力引数:
%     idslist - 断面リストID (スカラー)
%
%   出力引数:
%     tbsec - TB断面寸法 [ntbs×3]
%     id    - ID構造体（.slist, .section）

% TB断面の情報を取得
idsec2stype = obj.idMapper_.idsec2stype;
idSectionList = obj.idMapper_.idSectionList;
isTb = (idsec2stype == PRM.TB);
ntbs = sum(isTb);
idtbs2slist = idSectionList(isTb);

% 断面リストの寸法データを取得
% [shape_code, A(mm2), Ae(mm2)]
secdimlist = ...
  obj.standardAccessor_.getSectionDimension(idslist);

% 初期寸法（shape_code, A）を取得
% dimension_: [shape_code, A(mm2), Ae(mm2), Ta(kN)]
init_dim = obj.dimension_(isTb, :);

% 結果配列
tbsec = zeros(ntbs, 3);
id.slist = zeros(ntbs, 1);
id.section = zeros(ntbs, 1);

for i = 1:ntbs
  % この断面リストに属さない場合はスキップ
  if idtbs2slist(i) ~= idslist
    continue
  end

  % 検索キー
  target_code = init_dim(i, 1);
  target_A = init_dim(i, 2);

  % 同じ shape_code のエントリをフィルタ
  same_code = (secdimlist(:,1) == target_code);

  if any(same_code)
    % shape_code 一致の中から A が最も近いものを選択
    candidates = find(same_code);
    [~, idx_min] = ...
      min(abs(secdimlist(candidates, 2) - target_A));
    idx_found = candidates(idx_min);
  else
    % shape_code 不一致の場合は A のみで最近傍
    [~, idx_found] = ...
      min(abs(secdimlist(:, 2) - target_A));
  end

  tbsec(i, :) = secdimlist(idx_found, :);
  id.slist(i) = idslist;
  id.section(i) = idx_found;
end

return
end
