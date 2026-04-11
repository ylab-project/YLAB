function [hssec, rephss, id] = findNearestSectionHss( ...
  obj, xvar, idslist, options)
%findNearestSectionHss - HSS断面の最近傍選択
%
%   [hssec, rephss, id] = findNearestSectionHss(obj, xvar, idslist,
%   options) は、設計変数値から最近傍のHSS断面を選択する。完全一致
%   があれば採用し、なければ目標Dに最も近いDを選び、そのDと元のt
%   での径厚比に最も近い断面を最終選択する。
%
%   入力引数:
%     obj     - SectionNeighborSearcher インスタンス
%     xvar    - 設計変数ベクトル [nxvar×1]
%     idslist - 断面リストID（スカラー）
%     options - オプション構造体（tolDgap等）
%
%   出力引数:
%     hssec  - HSS断面寸法 [nhss×5]（列1-3使用、4-5は互換性用）
%     rephss - 代表HSS断面 [nrephss×5]（列1-3使用、4-5は互換性用）
%     id     - ID構造体（.slist, .section）
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

% 代表断面の変数IDを取得
idrephss2var = obj.idMapper_.idrephss2var;

% 断面リストの寸法データと有効フラグを取得
secdimlist_all = obj.standardAccessor_.getSectionDimension(idslist);
idPhase = obj.standardAccessor_.idPhase;
isvalid_all = obj.constraintValidator_.extractValidSectionFlags( ...
  idslist, idPhase);

% 計算準備
rephss = zeros(nrephss, 5);  % 旧実装との互換性のため5列
rephss(idrephss2slist==idslist, 1:2) = ...
  xvar(idrephss2var(idrephss2slist==idslist, 1:2));
id.slist = zeros(nrephss, 1);
id.section = zeros(nrephss, 1);

% 該当する代表断面のインデックスを一括取得
relevant_idx = find(idrephss2slist == idslist);
n_relevant = length(relevant_idx);

if n_relevant > 0
  % 設計変数を一括取得
  D_targets = xvar(idrephss2var(relevant_idx, 1));
  t_targets = xvar(idrephss2var(relevant_idx, 2));

  % 各代表断面の最近傍を探索
  for i = 1:n_relevant
    id_ = relevant_idx(i);
    D_target = D_targets(i);
    t_target = t_targets(i);

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
    if any(exact_match)
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
    id.slist(id_) = idslist;
    id.section(id_) = valid_indices(idx_found);
  end
end

% HSS断面の抽出（5列を維持）
hssec = rephss(idhss2rephss, :);
id.slist = id.slist(idhss2rephss);
id.section = id.section(idhss2rephss);

return
end