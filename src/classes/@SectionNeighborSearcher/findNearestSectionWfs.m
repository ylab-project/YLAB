function [wfsec, repwfs, id] = ...
  findNearestSectionWfs(obj, xvar, idslist, options)
%findNearestSectionWfs WFS断面の最近傍選択
%   [wfsec, repwfs, id] = findNearestSectionWfs(obj, xvar, 
%     idslist, options) は、変数値から最近傍のWFS断面を選択します。
%
%   断面選択アルゴリズム:
%     1. 完全一致チェック: 目標値（公称値）と候補断面（公称値）を比較
%     2. H,B選択: 公称値同士で比較し、tolHgap内で最も近いものを選択
%     3. 板厚選択: 実寸値ベースの幅厚比で最適な板厚を選択
%     4. 最終出力: 実寸値を返す（secdimlistの列1-5）
%
%   データ取り扱いルール:
%     - xvar: 公称値（入力）
%     - secdimlist(:,1:5): 実寸値
%     - secdimlist(:,6:7): 公称値（H_nom, B_nom）
%     - 幅厚比計算: 常に実寸値を使用
%     - repwfs, wfsec: 実寸値（出力）
%
%   入力引数:
%     xvar      - 設計変数ベクトル [nxvar×1]（公称値）
%     idslist   - 断面リストID (スカラー)
%     options   - オプション構造体（tolHgap, tolBgapを含む）
%
%   出力引数:
%     wfsec  - WFS断面寸法 [nwfs×5]（実寸値）
%     repwfs - 代表WFS断面 [nrepwfs×5]（実寸値）
%     id     - ID構造体（.slist, .section）

% 共通定数と配列の取得
nrepwfs = obj.idMapper_.nrepwfs;
idwfs2repwfs = obj.idMapper_.idwfs2repwfs;
idrepwfs2wfs = obj.idMapper_.idrepwfs2wfs;

% 代表断面の断面リストIDを取得
idsec2stype = obj.idMapper_.idsec2stype;
idSectionList = obj.idMapper_.idSectionList;
isWfs = (idsec2stype == PRM.WFS);
idwfs2sec = find(isWfs);
idrepwfs2sec = idwfs2sec(idrepwfs2wfs);
idrepwfs2slist = idSectionList(idrepwfs2sec);

% 代表断面の変数IDを取得
idrepwfs2var = obj.idMapper_.idrepwfs2var;

% 断面リストの寸法データと有効フラグを取得
secdimlist_all = obj.standardAccessor_.getSectionDimension(idslist);
idPhase = obj.standardAccessor_.idPhase;
isvalid = obj.constraintValidator_.extractValidSectionFlags(...
  idslist, idPhase);

% 計算準備
repHBnominal = zeros(nrepwfs, 2);  % H,B公称値を格納
repHBnominal(idrepwfs2slist==idslist, 1:2) = ...
  xvar(idrepwfs2var(idrepwfs2slist==idslist, 1:2));
repwfs = zeros(nrepwfs, 5);  % 実寸値を格納
repwfs(idrepwfs2slist==idslist, 3:4) = ...
  xvar(idrepwfs2var(idrepwfs2slist==idslist, 3:4));
% 板厚をrepwfsに初期化（xvarから取得）
id.slist = zeros(nrepwfs, 1);
id.section = zeros(nrepwfs, 1);

% 小さいH断面の丸め処理（H,B公称値に対して）
is_small_H = repHBnominal(:,1) < 200;
repHBnominal(is_small_H, 1) = round(repHBnominal(is_small_H, 1)/25)*25;
repHBnominal(~is_small_H, 2) = round(repHBnominal(~is_small_H, 2)/50)*50;

% 断面の検索
for id_ = 1:nrepwfs
  % 断面と断面リストが対応しないときはスキップ
  if idrepwfs2slist(id_) ~= idslist
    continue
  end
  
  % 有効な断面のみ抽出
  idwfs = idrepwfs2wfs(id_);
  isvalid_ = isvalid(idwfs, :);
  isvalid_ = isvalid_(:);
  secdimlist = secdimlist_all(isvalid_, :);
  valid_indices = find(isvalid_);
  if isempty(valid_indices)
    throw_err('Search', 'NoWfsCandidate', idwfs);
    return
  end
  
  % 寸法値と幅厚比の事前計算
  H_nom_values = secdimlist(:, PRM.SECDIM_WFS_H_NOM);  % 公称値
  B_nom_values = secdimlist(:, PRM.SECDIM_WFS_B_NOM);  % 公称値
  H_actual_values = secdimlist(:, 1);  % 実寸
  B_actual_values = secdimlist(:, 2);  % 実寸
  tw_values = secdimlist(:, 3);
  tf_values = secdimlist(:, 4);
  % rtw_values = H_nom_values ./ tw_values;  % ウェブ幅厚比（公称値）
  % rtf_values = B_nom_values ./ tf_values;  % フランジ幅厚比（公称値）
  rtw_values = H_actual_values ./ tw_values;  % ウェブ幅厚比（実寸）
  rtf_values = B_actual_values ./ tf_values;  % フランジ幅厚比（実寸）
  
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
    H_actual_selected = H_actual_values(idx_HB);
    B_actual_selected = B_actual_values(idx_HB);
    
    % repHBnominalを更新（公称値を設定、旧実装の96行目に相当）
    repHBnominal(id_, 1:2) = [H_nom_selected, B_nom_selected];
    
    % Step 2: 旧実装と同じロジックで板厚最適化（公称値で比較）
    isGivenB = abs(B_nom_values - B_nom_selected) <= options.tolBgap;
    HB_match = isGivenH & isGivenB;
    
    if any(HB_match)
      % 幅厚比距離を計算（実寸値を使用）
      % rtw_target = H_nom_selected / tw_target;
      % rtf_target = B_nom_selected / tf_target;
      rtw_target = H_actual_selected / tw_target;
      rtf_target = B_actual_selected / tf_target;
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

return
end
