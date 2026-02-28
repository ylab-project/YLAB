function findNearestSectionBraceSteelOnce( ...
  obj, xvar, idslist, is_target)
%findNearestSectionBraceSteelOnce - ブレース鋼材の初回検索
%
%   findNearestSectionBraceSteelOnce(obj, xvar, idslist,
%     is_target) は、ブレース鋼材断面（BWFS/BHSS/BHSR）の
%   最近傍断面を断面リストから検索し、braceSteelCache_ に
%   保存する。固定変数のため初回のみ実行される。
%
%   入力引数:
%     xvar      - 設計変数ベクトル [nxvar×1]
%     idslist   - 断面リストID (スカラー)
%     is_target - 対象断面の論理配列 [nsec×1]

% 断面リストの寸法データを全件取得
secdimlist = ...
  obj.standardAccessor_.getSectionDimension(idslist);
nsecdim = size(secdimlist, 2);

% 対象断面のインデックスと変数IDを取得
idsec_list = find(is_target);
idsec2var = obj.idMapper_.idsec2var;

for i = 1:length(idsec_list)
  isec = idsec_list(i);
  varids = idsec2var(isec, :);
  varids = varids(varids > 0);
  nvar = length(varids);

  % xvarから目標値を取得
  ncol = min(nvar, nsecdim);
  if ncol == 0
    continue
  end
  target = zeros(1, ncol);
  for j = 1:ncol
    target(j) = xvar(varids(j));
  end

  % ユークリッド距離で最近傍選択
  dist = sqrt(sum( ...
    (secdimlist(:, 1:ncol) - target).^2, 2));
  [~, idx] = min(dist);

  % キャッシュに結果を保存
  ndim = min(nsecdim, 5);
  obj.braceSteelCache_.secdim(isec, 1:ndim) = ...
    secdimlist(idx, 1:ndim);
  obj.braceSteelCache_.idslist(isec) = idslist;
  obj.braceSteelCache_.idsec(isec) = idx;
  obj.braceSteelCache_.initialized(isec) = true;
end

return
end
