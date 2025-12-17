function [hssec, rephss, id] = ...
  findNearestSectionHss(obj, xvar, idslist, options)
%findNearestSectionHss HSS断面の最近傍選択
%   [hssec, rephss, id] = findNearestSectionHss(obj, xvar, idslist,
%     options) は、変数値から最近傍のHSS断面を選択します。
%
%   断面選択アルゴリズム:
%     1. 完全一致チェック: 目標値（D,t）と候補断面を比較
%     2. D選択: 目標値に最も近いDを選択
%     3. 板厚選択: 選択したDと元のtでの径厚比に最も近い断面を選択
%     4. 最終出力: 選択された断面の寸法（D, t, R）
%
%   データ取り扱いルール:
%     - xvar: 設計変数（入力）
%     - secdimlist: 断面寸法データ
%       - 列1: D（外径）
%       - 列2: t（板厚）
%       - 列3: R（曲率半径）
%     - 径厚比計算: D/t（選択したD / 元のt）
%     - rephss, hssec: 出力（実寸値）
%
%   入力引数:
%     xvar      - 設計変数ベクトル [nxvar×1]
%     idslist   - 断面リストID (スカラー)
%     options   - オプション構造体（tolDgap, toltgapを含む）
%
%   出力引数:
%     hssec  - HSS断面寸法 [nhss×5]（列1-3使用、4-5は互換性用）
%     rephss - 代表HSS断面 [nrephss×5]（列1-3使用、4-5は互換性用）
%     id     - ID構造体（.slist, .section）

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
% idPhaseはstandardAccessorから取得
idPhase = obj.standardAccessor_.idPhase;
isvalid = obj.constraintValidator_.extractValidSectionFlags(idslist, idPhase);

% 有効な断面のみ抽出（ループ外で一度だけ）
secdimlist = secdimlist_all(isvalid, :);
valid_indices = find(isvalid);

% D値と板厚比の事前計算（ループ外で一度だけ）
D_values = secdimlist(:, PRM.SECDIM_HSS_D);
t_values = secdimlist(:, PRM.SECDIM_HSS_T);
rt_values = D_values ./ t_values;  % 径厚比

% 計算準備
rephss = zeros(nrephss, 5);  % 旧実装との互換性のため5列
rephss(idrephss2slist==idslist, 1:2) = ...
  xvar(idrephss2var(idrephss2slist==idslist, 1:2));
id.slist = zeros(nrephss, 1);
id.section = zeros(nrephss, 1);

% 該当する代表断面のインデックスを一括取得（ベクトル化）
relevant_idx = find(idrephss2slist == idslist);
n_relevant = length(relevant_idx);

if n_relevant == 0
  % 該当断面がない場合は処理をスキップ
  % （後続の処理は空の結果を返す）
else
  % 設計変数を一括取得
  D_targets = xvar(idrephss2var(relevant_idx, 1));
  t_targets = xvar(idrephss2var(relevant_idx, 2));
  
  % 各代表断面の最近傍を探索
  for i = 1:n_relevant
    id_ = relevant_idx(i);
    D_target = D_targets(i);
    t_target = t_targets(i);
    
    % 完全一致をチェック
    exact_match = (D_target == D_values) & ...
                  (t_target == t_values);
    if any(exact_match)
      idx_found = find(exact_match, 1);
    else
      % Step 1: D値が最も近い断面を選択
      [~, idx_D] = min(abs(D_values - D_target));
      D_selected = D_values(idx_D);
      
      % rephssを更新（旧実装の73行目に相当）
      rephss(id_, 1) = D_selected;
      
      % Step 2: 板厚最適化（径厚比で選択）
      D_compatible = abs(D_values - D_selected) <= options.tolDgap;
      
      if any(D_compatible)
        % 選択したD値と元のt値での径厚比を計算
        rt_target = D_selected / t_target;
        rt_distances = (rt_values - rt_target).^2;
        rt_distances(~D_compatible) = inf;  % 範囲外を除外
        [~, idx_found] = min(rt_distances);
      else
        % 該当断面なし：D選択時の断面を使用
        idx_found = idx_D;
      end
    end
    
    % 結果を保存（旧実装との互換性のため3列）
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