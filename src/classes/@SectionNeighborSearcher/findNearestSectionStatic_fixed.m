function secdim = findNearestSectionStatic_fixed(xvar, options, ...
  idMapper, standardAccessor, dimension, secListAll, constraintValidator)
%findNearestSectionStatic_fixed 最近傍断面選択の静的メソッド版（修正版）
%   secdim = findNearestSectionStatic_fixed(xvar, options, ...) は、
%   並列処理用の静的メソッドとして実装された最近傍断面選択です。
%   通常版のfindNearestSectionと同じロジックを使用します。
%
%   入力引数:
%     xvar                - 設計変数ベクトル [1×nxvar]
%     options             - オプション構造体
%     idMapper            - IdMapperオブジェクト
%     standardAccessor    - SectionStandardAccessorオブジェクト
%     dimension           - 既存の断面寸法データ [nsec×7]
%     secListAll          - 断面リストデータ
%     constraintValidator - SectionConstraintValidatorオブジェクト
%
%   出力引数:
%     secdim - 断面寸法配列 [nsec×7]

% 初期化
idsec2stype = idMapper.idsec2stype;
idSectionList = idMapper.idSectionList;
nsec = length(idsec2stype);
nlist = standardAccessor.nlist;
secdim = dimension;  % 既存のデータをコピー

% 各断面タイプのマッピング取得
idwfs2slist = idMapper.idwfs2slist;
idhss2slist = idMapper.idhss2slist;
idbrbs2slist = idMapper.idbrbs2slist;

% 各断面リストごとに処理
for idslist = 1:nlist
  is_target = (idSectionList == idslist);
  
  % 断面タイプを取得
  sectionType = standardAccessor.getSectionType(idslist);
  
  switch sectionType
    case PRM.WFS
      % H形鋼の処理 - 通常版と同じロジックを使用
      is_target_wfs = (idwfs2slist == idslist);
      
      % 通常版のfindNearestSectionWfsと同じ実装
      [secwfs, ~, id_temp] = findNearestSectionWfsStatic_fixed(...
        xvar, idslist, options, idMapper, standardAccessor, ...
        constraintValidator, secListAll);
      
      % 結果を設定
      if ~isempty(secwfs)
        % is_targetのインデックスを取得
        idx_target = find(is_target);
        idx_wfs = find(is_target_wfs);
        
        % 対応するインデックスのみコピー
        for k = 1:length(idx_wfs)
          if k <= size(secwfs, 1)
            secdim(idx_target(k), 1:5) = secwfs(k, 1:5);
            secdim(idx_target(k), 6:7) = secwfs(k, 6:7);
          end
        end
      end
      
    case PRM.HSS
      % 角形鋼管の処理
      is_target_hss = (idhss2slist == idslist);
      
      [sechss, ~, id_temp] = findNearestSectionHssStatic_fixed(...
        xvar, idslist, options, idMapper, standardAccessor, ...
        constraintValidator, secListAll);
      
      if ~isempty(sechss)
        idx_target = find(is_target);
        idx_hss = find(is_target_hss);
        
        for k = 1:length(idx_hss)
          if k <= size(sechss, 1)
            secdim(idx_target(k), 1:3) = sechss(k, 1:3);
            secdim(idx_target(k), 6:7) = sechss(k, 6:7);
          end
        end
      end
      
    case PRM.BRB
      % BRBの処理
      is_target_brbs = (idbrbs2slist == idslist);
      
      [secbrb, ~, id_temp] = findNearestSectionBrbStatic_fixed(...
        xvar, idslist, options, idMapper, standardAccessor, ...
        constraintValidator, secListAll);
      
      if ~isempty(secbrb)
        idx_target = find(is_target);
        idx_brbs = find(is_target_brbs);
        
        for k = 1:length(idx_brbs)
          if k <= size(secbrb, 1)
            secdim(idx_target(k), 1:4) = secbrb(k, 1:4);
            secdim(idx_target(k), 6:7) = secbrb(k, 6:7);
          end
        end
      end
      
    case PRM.RCRS
      % RCRS断面（最適化対象外）- 変更なし
      
    otherwise
      % その他の断面タイプ - 変更なし
  end
end

return
end

%% findNearestSectionWfsStatic_fixed
function [wfsec, repwfs, id] = findNearestSectionWfsStatic_fixed(...
  xvar, idslist, options, idMapper, standardAccessor, ...
  constraintValidator, secListAll)
%findNearestSectionWfsStatic_fixed WFS断面の最近傍選択（修正版）
%   通常版のfindNearestSectionWfsと同じロジックを実装

% 共通定数と配列の取得
nrepwfs = idMapper.nrepwfs;
idwfs2repwfs = idMapper.idwfs2repwfs;
idrepwfs2wfs = idMapper.idrepwfs2wfs;

% 代表断面の断面リストIDを取得
idsec2stype = idMapper.idsec2stype;
idSectionList = idMapper.idSectionList;
isWfs = (idsec2stype == PRM.WFS);
idwfs2sec = find(isWfs);
idrepwfs2sec = idwfs2sec(idrepwfs2wfs);
idrepwfs2slist = idSectionList(idrepwfs2sec);

% 代表断面の変数IDを取得
idrepwfs2var = idMapper.idrepwfs2var;

% 断面リストの寸法データと有効フラグを取得
secdimlist_all = standardAccessor.getSectionDimension(idslist);
idPhase = standardAccessor.idPhase;
isvalid = constraintValidator.extractValidSectionFlags(...
  idslist, idPhase);
% isvalidを列ベクトルに変換（logical indexing用）は各断面で行う

% 計算準備
repHBnominal = zeros(nrepwfs, 2);  % H,B公称値を格納
repHBnominal(idrepwfs2slist==idslist, 1:2) = ...
  xvar(idrepwfs2var(idrepwfs2slist==idslist, 1:2));
repwfs = zeros(nrepwfs, 5);  % 実寸値を格納
repwfs(idrepwfs2slist==idslist, 3:4) = ...
  xvar(idrepwfs2var(idrepwfs2slist==idslist, 3:4));
id.slist = zeros(nrepwfs, 1);
id.section = zeros(nrepwfs, 1);

% 小さいH断面の丸め処理（H,B公称値に対して）
is_small_H = repHBnominal(:,1) < 200;
repHBnominal(is_small_H, 1) = ...
  round(repHBnominal(is_small_H, 1)/25)*25;
repHBnominal(~is_small_H, 2) = ...
  round(repHBnominal(~is_small_H, 2)/50)*50;

% 断面の検索
for id_ = 1:nrepwfs
  % 断面と断面リストが対応しないときはスキップ
  if idrepwfs2slist(id_) ~= idslist
    continue
  end
  
  % 有効な断面のみ抽出
  idwfs = idrepwfs2wfs(id_);
  % isvalidがnwfs×nsecdimの場合、idwfs番目の行を取得
  if size(isvalid, 1) > 1
    isvalid_ = isvalid(idwfs, :);
  else
    isvalid_ = isvalid;
  end
  isvalid_ = isvalid_(:);  % 列ベクトルに変換
  secdimlist = secdimlist_all(isvalid_, :);
  valid_indices = find(isvalid_);
  
  if isempty(valid_indices)
    throw_err('Search', 'NoWfsCandidate', idslist);
    return
  end
  
  % 寸法値と幅厚比の事前計算
  H_nom_values = secdimlist(:, PRM.SECDIM_WFS_H_NOM);  % 公称値
  B_nom_values = secdimlist(:, PRM.SECDIM_WFS_B_NOM);  % 公称値
  H_actual_values = secdimlist(:, 1);  % 実寸
  B_actual_values = secdimlist(:, 2);  % 実寸
  tw_values = secdimlist(:, 3);
  tf_values = secdimlist(:, 4);
  rtw_values = H_actual_values ./ tw_values;  % 幅厚比（実寸）
  rtf_values = B_actual_values ./ tf_values;  % 幅厚比（実寸）
  
  % 設計変数から目標値を取得
  H_target = repHBnominal(id_, 1);  % H公称値（丸め処理済み）
  B_target = repHBnominal(id_, 2);  % B公称値（丸め処理済み）
  tw_target = repwfs(id_, 3);  % 板厚（xvarから初期化済み）
  tf_target = repwfs(id_, 4);  % 板厚（xvarから初期化済み）
  
  % 完全一致をチェック（H,Bは目標値と公称値で比較、板厚は実寸値）
  exact_match = (H_target == H_nom_values) & ...
                (B_target == B_nom_values) & ...
                (tw_target == tw_values) & ...
                (tf_target == tf_values);
  
  if any(exact_match)
    idx_found = find(exact_match, 1);
  else
    % Step 1: H値が許容範囲内でB値が最も近い断面を検索（公称値で比較）
    isGivenH = abs(H_nom_values - H_target) <= options.tolHgap;
    
    if any(isGivenH)
      % H互換断面からB最近傍を選択
      B_distances = abs(B_nom_values - B_target);
      B_distances(~isGivenH) = inf;
      [~, idx_HB] = min(B_distances);
    else
      % H値が最も近い断面を選択
      [~, idx_HB] = min(abs(H_nom_values - H_target));
    end
    
    % 選択したH,B値を取得（公称値と実寸値）
    H_nom_selected = H_nom_values(idx_HB);
    B_nom_selected = B_nom_values(idx_HB);
    
    % repHBnominalを更新（公称値を設定）
    repHBnominal(id_, 1:2) = [H_nom_selected, B_nom_selected];
    
    % Step 2: 板厚最適化（公称値で比較）
    isGivenB = abs(B_nom_values - B_nom_selected) <= options.tolBgap;
    HB_match = isGivenH & isGivenB;
    
    if any(HB_match)
      % 幅厚比距離を計算（実寸値を使用）
      rtw_target = H_nom_selected / tw_target;
      rtf_target = B_nom_selected / tf_target;
      rt_distances = (rtw_values - rtw_target).^2 + ...
                     (rtf_values - rtf_target).^2;
      rt_distances(~HB_match) = inf;
      [~, idx_found] = min(rt_distances);
    else
      % H,B選択時の断面を使用
      idx_found = idx_HB;
    end
  end
  
  % 結果を保存（実寸値）
  repwfs(id_, 1:5) = secdimlist(idx_found, 1:5);
  id.slist(id_) = idslist;
  id.section(id_) = valid_indices(idx_found);
end

% WFS断面の抽出（実寸値）
wfsec = repwfs(idwfs2repwfs, :);
id.slist = id.slist(idwfs2repwfs);
id.section = id.section(idwfs2repwfs);

% 6-7列目を追加
nwfs = length(idwfs2repwfs);
wfsec_full = zeros(nwfs, 7);
wfsec_full(:, 1:5) = wfsec;
wfsec_full(:, 6) = id.slist;
wfsec_full(:, 7) = id.section;
wfsec = wfsec_full;

return
end

%% findNearestSectionHssStatic_fixed
function [sechss, rephss, id] = findNearestSectionHssStatic_fixed(...
  xvar, idslist, options, idMapper, standardAccessor, ...
  constraintValidator, secListAll)
%findNearestSectionHssStatic_fixed HSS断面の最近傍選択（修正版）

% 共通定数と配列の取得
nrephss = idMapper.nrephss;
idhss2rephss = idMapper.idhss2rephss;
idrephss2hss = idMapper.idrephss2hss;

% 代表断面の断面リストIDを取得
idsec2stype = idMapper.idsec2stype;
idSectionList = idMapper.idSectionList;
isHss = (idsec2stype == PRM.HSS);
idhss2sec = find(isHss);
idrephss2sec = idhss2sec(idrephss2hss);
idrephss2slist = idSectionList(idrephss2sec);

% 代表断面の変数IDを取得
idrephss2var = idMapper.idrephss2var;

% 断面リストの寸法データと有効フラグを取得
secdimlist_all = standardAccessor.getSectionDimension(idslist);
idPhase = standardAccessor.idPhase;
isvalid = constraintValidator.extractValidSectionFlags(...
  idslist, idPhase);
% isvalidを列ベクトルに変換（logical indexing用）は各断面で行う

% 計算準備
repDnominal = zeros(nrephss, 1);  % D公称値を格納
repDnominal(idrephss2slist==idslist) = ...
  xvar(idrephss2var(idrephss2slist==idslist, 1));
rephss = zeros(nrephss, 3);  % 実寸値を格納
rephss(idrephss2slist==idslist, 2) = ...
  xvar(idrephss2var(idrephss2slist==idslist, 2));
id.slist = zeros(nrephss, 1);
id.section = zeros(nrephss, 1);

% 断面の検索
for id_ = 1:nrephss
  % 断面と断面リストが対応しないときはスキップ
  if idrephss2slist(id_) ~= idslist
    continue
  end
  
  % 有効な断面のみ抽出
  idhss = idrephss2hss(id_);
  % isvalidがnhss×nsecdimの場合、idhss番目の行を取得
  if size(isvalid, 1) > 1
    isvalid_ = isvalid(idhss, :);
  else
    isvalid_ = isvalid;
  end
  isvalid_ = isvalid_(:);  % 列ベクトルに変換
  secdimlist = secdimlist_all(isvalid_, :);
  valid_indices = find(isvalid_);
  
  if isempty(valid_indices)
    continue
  end
  
  % 寸法値の事前計算
  D_values = secdimlist(:, 1);
  t_values = secdimlist(:, 2);
  
  % 設計変数から目標値を取得
  D_target = repDnominal(id_);
  t_target = rephss(id_, 2);
  
  % 許容範囲内の断面を選択
  isGivenD = abs(D_values - D_target) <= options.tolDgap;
  
  if ~any(isGivenD)
    [~, closest_idx] = min(abs(D_values - D_target));
    isGivenD(closest_idx) = true;
  end
  
  % 幅厚比で最適な断面を選択
  valid_idx = find(isGivenD);
  rt_values = D_values(valid_idx) ./ t_values(valid_idx);
  rt_target = D_target / t_target;
  
  [~, min_idx] = min(abs(rt_values - rt_target));
  selected_idx = valid_idx(min_idx);
  
  % 結果を保存
  rephss(id_, 1:3) = secdimlist(selected_idx, 1:3);
  id.slist(id_) = idslist;
  id.section(id_) = valid_indices(selected_idx);
end

% HSS断面の抽出
sechss = rephss(idhss2rephss, :);
id.slist = id.slist(idhss2rephss);
id.section = id.section(idhss2rephss);

% 6-7列目を追加
nhss = length(idhss2rephss);
sechss_full = zeros(nhss, 7);
sechss_full(:, 1:3) = sechss;
sechss_full(:, 6) = id.slist;
sechss_full(:, 7) = id.section;
sechss = sechss_full;

return
end

%% findNearestSectionBrbStatic_fixed
function [secbrb, repbrbs, id] = findNearestSectionBrbStatic_fixed(...
  xvar, idslist, options, idMapper, standardAccessor, ...
  constraintValidator, secListAll)
%findNearestSectionBrbStatic_fixed BRB断面の最近傍選択（修正版）

% 共通定数と配列の取得
nrepbrbs = idMapper.nrepbrbs;
idbrbs2repbrbs = idMapper.idbrbs2repbrbs;
idrepbrbs2brbs = idMapper.idrepbrbs2brbs;

% 代表断面の断面リストIDを取得
idsec2stype = idMapper.idsec2stype;
idSectionList = idMapper.idSectionList;
isBrbs = (idsec2stype == PRM.BRB);
idbrbs2sec = find(isBrbs);
idrepbrbs2sec = idbrbs2sec(idrepbrbs2brbs);
idrepbrbs2slist = idSectionList(idrepbrbs2sec);

% 代表断面の変数IDを取得
idrepbrbs2var = idMapper.idrepbrbs2var;

% 断面リストの寸法データと有効フラグを取得
secdimlist_all = standardAccessor.getSectionDimension(idslist);
idPhase = standardAccessor.idPhase;
isvalid = constraintValidator.extractValidSectionFlags(...
  idslist, idPhase);
% isvalidを列ベクトルに変換（logical indexing用）は各断面で行う

% 計算準備
repbrbs = zeros(nrepbrbs, 4);
id.slist = zeros(nrepbrbs, 1);
id.section = zeros(nrepbrbs, 1);

% 断面の検索
for id_ = 1:nrepbrbs
  % 断面と断面リストが対応しないときはスキップ
  if idrepbrbs2slist(id_) ~= idslist
    continue
  end
  
  % 有効な断面のみ抽出
  idbrbs = idrepbrbs2brbs(id_);
  % isvalidがnbrbs×nsecdimの場合、idbrbs番目の行を取得
  if size(isvalid, 1) > 1
    isvalid_ = isvalid(idbrbs, :);
  else
    isvalid_ = isvalid;
  end
  isvalid_ = isvalid_(:);  % 列ベクトルに変換
  secdimlist = secdimlist_all(isvalid_, :);
  valid_indices = find(isvalid_);
  
  if isempty(valid_indices)
    continue
  end
  
  % 設計変数から目標値を取得
  V1_target = xvar(idrepbrbs2var(id_, 1));
  V2_target = xvar(idrepbrbs2var(id_, 2));
  
  % 寸法値
  V1_values = secdimlist(:, 1);
  V2_values = secdimlist(:, 2);
  
  % 最近傍を選択
  exact_match = (V1_values == V1_target) & (V2_values == V2_target);
  
  if any(exact_match)
    selected_idx = find(exact_match, 1);
  else
    distances = (V1_values - V1_target).^2 + (V2_values - V2_target).^2;
    [~, selected_idx] = min(distances);
  end
  
  % 結果を保存
  repbrbs(id_, 1:4) = secdimlist(selected_idx, 1:4);
  id.slist(id_) = idslist;
  id.section(id_) = valid_indices(selected_idx);
end

% BRB断面の抽出
secbrb = repbrbs(idbrbs2repbrbs, :);
id.slist = id.slist(idbrbs2repbrbs);
id.section = id.section(idbrbs2repbrbs);

% 6-7列目を追加
nbrbs = length(idbrbs2repbrbs);
secbrb_full = zeros(nbrbs, 7);
secbrb_full(:, 1:4) = secbrb;
secbrb_full(:, 6) = id.slist;
secbrb_full(:, 7) = id.section;
secbrb = secbrb_full;

return
end
