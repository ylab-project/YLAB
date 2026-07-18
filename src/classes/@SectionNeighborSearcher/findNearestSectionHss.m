function [hssec, rephss, id, selection_info] = findNearestSectionHss( ...
  obj, xvar, idslist, options, initial_guess, mapped_xvar)
%findNearestSectionHss - HSS断面の最近傍選択
%
%   [hssec, rephss, id] = findNearestSectionHss(obj, xvar, idslist,
%   options, initial_guess) は、設計変数値から最近傍のHSS断面を
%   選択する。initial_guessを省略した場合は既存検索を実行する。
%
%   入力引数:
%     obj     - SectionNeighborSearcher インスタンス
%     xvar    - 設計変数ベクトル [nxvar×1]
%     idslist - 断面リストID（スカラー）
%     options - オプション構造体（tolDgap等）
%     initial_guess - 直前の写像結果（.x、.secdim）。省略可能
%     mapped_xvar - 断面リスト間で引き継ぐ補正済み変数値。省略可能
%
%   出力引数:
%     hssec  - HSS断面寸法 [nhss×5]（列1-3使用、4-5は互換性用）
%     rephss - 代表HSS断面 [nrephss×5]（列1-3使用、4-5は互換性用）
%     id     - ID構造体（.slist, .section）
%     selection_info - 補正済み変数値と共有変数の集約対象マスク
%
%   備考:
%     - secdimlist の列1=D（外径）、列2=t（板厚）、列3=R（曲率半径）
%     - 径厚比 = D/t（選択したD / 元のt）

% 共通定数と配列の取得
nrephss = obj.idMapper_.nrephss;
idhss2rephss = obj.idMapper_.idhss2rephss;
idrephss2hss = obj.idMapper_.idrephss2hss;

% 代表断面の断面リストIDを取得
idsec2stype = obj.idMapper_.idsec2stype;
idSectionList = obj.idMapper_.idSectionList;
isHss = (idsec2stype == PRM.HSS);
idhss2sec = find(isHss);
idrephss2sec = idhss2sec(idrephss2hss);
idrephss2slist = idSectionList(idrephss2sec);

% 代表断面と設計変数の対応を取得
idrephss2var = obj.idMapper_.idrephss2var;
relevant_idx = find(idrephss2slist == idslist);
use_initial_guess = nargin >= 5 && ~isempty(initial_guess);
is_unchanged = false(nrephss, 1);
if use_initial_guess
  var_ids = idrephss2var(relevant_idx, 1:2);
  is_unchanged(relevant_idx) = all( ...
    xvar(var_ids) == initial_guess.x(var_ids), 2);
end

% 出力を初期化し、不変な代表断面を直前の写像結果からコピー
rephss = zeros(nrephss, 5);
rephss(relevant_idx, 1:2) = xvar(idrephss2var(relevant_idx, 1:2));
id.slist = zeros(nrephss, 1);
id.section = zeros(nrephss, 1);
unchanged_idx = relevant_idx(is_unchanged(relevant_idx));
if ~isempty(unchanged_idx)
  initial_rows = idrephss2sec(unchanged_idx);
  initial_secdim = initial_guess.secdim(initial_rows, :);
  rephss(unchanged_idx, 1:3) = initial_secdim(:, 1:3);
  id.slist(unchanged_idx) = initial_secdim(:, PRM.MAPPED_SECDIM_SLIST);
  id.section(unchanged_idx) = initial_secdim(:, PRM.MAPPED_SECDIM_SECTION);
end

% 全代表断面が不変ならカタログを取得せず終了
changed_idx = relevant_idx(~is_unchanged(relevant_idx));
collect_mapping = nargout >= 4;
if collect_mapping
  if nargin < 6
    mapped_xvar = xvar(:)';
  end
  aggregate_variable = false(1, obj.idMapper_.nxvar);
  idvar2srep = obj.idMapper_.idvar2srep;
  idsrep2stype = obj.idMapper_.idsrep2stype;
  selection_info.xvar = mapped_xvar;
  selection_info.aggregate_variable = aggregate_variable;
end
if isempty(changed_idx)
  hssec = rephss(idhss2rephss, :);
  id.slist = id.slist(idhss2rephss);
  id.section = id.section(idhss2rephss);
  return
end

% 変更した代表断面に必要なカタログと有効フラグを取得
secdimlist_all = obj.standardAccessor_.getSectionDimension(idslist);
isvalid_all = obj.constraintValidator_.extractValidSectionFlags(idslist);

% 変更した代表断面だけを検索
for id_ = changed_idx(:)'
  D_target = xvar(idrephss2var(id_, 1));
  t_target = xvar(idrephss2var(id_, 2));

  % 断面ごとの有効フラグを抽出
  idhss = idrephss2hss(id_);
  isvalid_ = isvalid_all(idhss, :);
  isvalid_ = isvalid_(:);
  secdimlist = secdimlist_all(isvalid_, :);
  valid_indices = find(isvalid_);
  if isempty(valid_indices)
    throw_err('List', 'NoHssCandidate', idslist);
    return
  end

  % D値と径厚比の計算
  D_values = secdimlist(:, PRM.SECDIM_HSS_D);
  t_values = secdimlist(:, PRM.SECDIM_HSS_T);
  rt_values = D_values ./ t_values;

  % 完全一致をチェック
  exact_match = (D_target == D_values) & (t_target == t_values);
  is_exact_match = any(exact_match);
  if is_exact_match
    idx_found = find(exact_match, 1);
  else
    % Step 1: D値が最も近い断面を選択
    [~, idx_D] = min(abs(D_values - D_target));
    D_selected = D_values(idx_D);
    rephss(id_, 1) = D_selected;

    % Step 2: 板厚最適化（径厚比で選択）
    D_compatible = abs(D_values - D_selected) <= options.tolDgap;

    if any(D_compatible)
      rt_target = D_selected / t_target;
      rt_distances = (rt_values - rt_target).^2;
      rt_distances(~D_compatible) = inf;
      [~, idx_found] = min(rt_distances);
    else
      idx_found = idx_D;
    end
  end

  % 結果を保存
  rephss(id_, 1:3) = secdimlist(idx_found, 1:3);
  if collect_mapping && ~is_exact_match
    selected_components = secdimlist(idx_found, 1:2);
    for component_id = 1:2
      variable_id = idrephss2var(id_, component_id);
      representative_ids = idvar2srep{variable_id};
      num_representative = sum( ...
        idsrep2stype(representative_ids) == PRM.HSS);
      if num_representative == 1
        mapped_xvar(variable_id) = selected_components(component_id);
      else
        aggregate_variable(variable_id) = true;
      end
    end
  end
  id.slist(id_) = idslist;
  id.section(id_) = valid_indices(idx_found);
end

if collect_mapping
  selection_info.xvar = mapped_xvar;
  selection_info.aggregate_variable = aggregate_variable;
end
% HSS断面の抽出（5列を維持）
hssec = rephss(idhss2rephss, :);
id.slist = id.slist(idhss2rephss);
id.section = id.section(idhss2rephss);

return
end
