function secdim = findNearestSectionStatic(xvar, options, ...
  idMapper, standardAccessor, dimension, secListAll)
%findNearestSectionStatic 最近傍断面選択の静的メソッド版
%   secdim = findNearestSectionStatic(xvar, options, ...) は、
%   並列処理用の静的メソッドとして実装された最近傍断面選択です。
%
%   入力引数:
%     xvar             - 設計変数ベクトル [1×nxvar]
%     options          - オプション構造体
%     idMapper         - IdMapperオブジェクト
%     standardAccessor - SectionStandardAccessorオブジェクト
%     dimension        - 既存の断面寸法データ [nsec×7]
%     secListAll       - 断面リストデータ
%
%   出力引数:
%     secdim - 断面寸法配列 [nsec×7]

% 初期化
idsec2stype = idMapper.idsec2stype;
idSectionList = idMapper.idSectionList;
nsec = length(idsec2stype);
nlist = standardAccessor.nlist;
secdim = dimension;  % 既存のデータをコピー

% ID初期化
id_slist = zeros(nsec, 1);
id_section = zeros(nsec, 1);

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
      % H形鋼の処理
      is_target_wfs = (idwfs2slist == idslist);
      
      % findNearestSectionWfsのロジックをインライン実装
      [secwfs, ~, id_temp] = findNearestSectionWfsStatic(...
        xvar, idslist, options, idMapper, secListAll);
      
      % secwfsの最初の5列を取得
      if size(secwfs, 2) >= 5
        secdim(is_target, 1:5) = secwfs(is_target_wfs, 1:5);
      else
        secdim(is_target, 1:size(secwfs,2)) = secwfs(is_target_wfs, :);
      end
      id_slist(is_target) = id_temp.slist(is_target_wfs);
      id_section(is_target) = id_temp.section(is_target_wfs);
      
    case PRM.HSS
      % 角形鋼管の処理
      is_target_hss = (idhss2slist == idslist);
      
      [sechss, ~, id_temp] = findNearestSectionHssStatic(...
        xvar, idslist, options, idMapper, secListAll);
      
      secdim(is_target, 1:3) = sechss(is_target_hss, 1:3);
      id_slist(is_target) = id_temp.slist(is_target_hss);
      id_section(is_target) = id_temp.section(is_target_hss);
      
    case PRM.BRB
      % BRBの処理
      is_target_brbs = (idbrbs2slist == idslist);
      
      [secbrb, ~, id_temp] = findNearestSectionBrbStatic(...
        xvar, idslist, options, idMapper, secListAll);
      
      secdim(is_target, 1:4) = secbrb(is_target_brbs, 1:4);
      id_slist(is_target) = id_temp.slist(is_target_brbs);
      id_section(is_target) = id_temp.section(is_target_brbs);
      
    case PRM.RCRS
      % RCRS断面（最適化対象外）
      id_slist(is_target) = 0;
      id_section(is_target) = 0;
      
    otherwise
      % その他の断面タイプ
      id_slist(is_target) = 0;
      id_section(is_target) = 0;
  end
end

% 6-7列目に結果を設定
secdim(:, 6) = id_slist;
secdim(:, 7) = id_section;

return
end

%% findNearestSectionWfsStatic
function [secwfs, repwfs, id] = findNearestSectionWfsStatic(...
  xvar, idslist, options, idMapper, secListAll)
%findNearestSectionWfsStatic WFS断面の最近傍選択（静的版）

% 必要なマッピングを取得
idrepwfs2wfs = idMapper.idrepwfs2wfs;
idrepwfs2var = idMapper.idrepwfs2var;
idwfs2slist = idMapper.idwfs2slist;

% idrepwfs2slistを計算
idwfs2sec = idMapper.idwfs2sec;
idrepwfs2sec = idwfs2sec(idrepwfs2wfs);
idSectionList = idMapper.idSectionList;
idrepwfs2slist = idSectionList(idrepwfs2sec);

% 断面リストデータを取得
secListCell = secListAll{idslist};
if isempty(secListCell) || ~isstruct(secListCell)
  nwfs = sum(idwfs2slist == idslist);
  secwfs = zeros(nwfs, 7);
  repwfs = zeros(length(find(idrepwfs2slist == idslist)), 5);
  id.slist = zeros(nwfs, 1);
  id.section = zeros(nwfs, 1);
  return;
end

% 断面寸法データを取得
secdimlist = secListCell.secdim;
nsecdim = size(secdimlist, 1);

% 初期化
nwfs = sum(idwfs2slist == idslist);
nrepwfs = sum(idrepwfs2slist == idslist);
secwfs = zeros(nwfs, 7);
repwfs = zeros(nrepwfs, 5);
repHBnominal = zeros(nrepwfs, 2);  % H,B公称値格納用

% 各代表断面を処理
for id_ = 1:nrepwfs
  if idrepwfs2slist(id_) ~= idslist
    continue;
  end
  
  % 目標値を取得
  H_target = xvar(idrepwfs2var(id_, 1));
  B_target = xvar(idrepwfs2var(id_, 2));
  tw_target = xvar(idrepwfs2var(id_, 3));
  tf_target = xvar(idrepwfs2var(id_, 4));
  
  % H,Bの丸め処理（公称値）
  if H_target < 200
    H_nom_selected = ceil(H_target / 25) * 25;
  else
    H_nom_selected = floor(H_target / 50) * 50;
  end
  
  if H_nom_selected < 200
    B_nom_selected = ceil(B_target / 25) * 25;
  else
    B_nom_selected = floor(B_target / 50) * 50;
  end
  
  % 公称値を保存
  repHBnominal(id_, :) = [H_nom_selected, B_nom_selected];
  
  % 候補断面の選択
  H_nom_values = secdimlist(:, 6);
  B_nom_values = secdimlist(:, 7);
  H_actual_values = secdimlist(:, 1);
  B_actual_values = secdimlist(:, 2);
  tw_values = secdimlist(:, 3);
  tf_values = secdimlist(:, 4);
  
  % 許容範囲内の断面を選択
  isGivenH = abs(H_nom_values - H_target) <= options.tolHgap;
  isGivenB = abs(B_nom_values - B_target) <= options.tolBgap;
  isvalid_ = isGivenH & isGivenB;
  
  if ~any(isvalid_)
    isvalid_ = (H_nom_values == H_nom_selected) & ...
               (B_nom_values == B_nom_selected);
  end
  
  if ~any(isvalid_)
    throw_err('Search', 'NoWfsCandidate', idslist);
    return
  end
  
  % 幅厚比計算と最適断面選択
  rtw_target = H_nom_selected / tw_target;
  rtf_target = B_nom_selected / tf_target;
  
  valid_idx = find(isvalid_);
  rtw_values = H_actual_values(valid_idx) ./ tw_values(valid_idx);
  rtf_values = B_actual_values(valid_idx) ./ tf_values(valid_idx);
  
  rt_distances = (rtw_values - rtw_target).^2 + ...
                 (rtf_values - rtf_target).^2;
  [~, min_idx] = min(rt_distances);
  selected_idx = valid_idx(min_idx);
  
  % 結果を格納
  repwfs(id_, :) = secdimlist(selected_idx, 1:5);
  secwfs(idrepwfs2wfs(id_), :) = [secdimlist(selected_idx, 1:5), ...
    idslist, selected_idx];
end

% ID情報を設定
id.slist = idslist * ones(nwfs, 1);
id.section = (1:nwfs)';

return
end

%% findNearestSectionHssStatic  
function [sechss, rephss, id] = findNearestSectionHssStatic(...
  xvar, idslist, options, idMapper, secListAll)
%findNearestSectionHssStatic HSS断面の最近傍選択（静的版）

% 必要なマッピングを取得
idrephss2hss = idMapper.idrephss2hss;
idrephss2var = idMapper.idrephss2var;
idhss2slist = idMapper.idhss2slist;

% idrephss2slistを計算
nrephss = idMapper.nrephss;
idhss2sec = idMapper.idhss2sec;
idrephss2sec = idhss2sec(idrephss2hss);
idSectionList = idMapper.idSectionList;
idrephss2slist = idSectionList(idrephss2sec);

% 初期化
nhss = sum(idhss2slist == idslist);
nrephss = sum(idrephss2slist == idslist);
sechss = zeros(nhss, 7);
rephss = zeros(nrephss, 3);

% 断面リストデータを取得
secListCell = secListAll{idslist};
if isempty(secListCell) || ~isstruct(secListCell)
  id.slist = zeros(nhss, 1);
  id.section = zeros(nhss, 1);
  return;
end

secdimlist = secListCell.secdim;

% 各代表断面を処理
for id_ = 1:nrephss
  if idrephss2slist(id_) ~= idslist
    continue;
  end
  
  D_target = xvar(idrephss2var(id_, 1));
  t_target = xvar(idrephss2var(id_, 2));
  
  % 候補断面の選択
  D_values = secdimlist(:, 1);
  t_values = secdimlist(:, 2);
  
  isGivenD = abs(D_values - D_target) <= options.tolDgap;
  
  if ~any(isGivenD)
    [~, closest_idx] = min(abs(D_values - D_target));
    isGivenD(closest_idx) = true;
  end
  
  valid_idx = find(isGivenD);
  rt_values = D_values(valid_idx) ./ t_values(valid_idx);
  rt_target = D_target / t_target;
  
  [~, min_idx] = min(abs(rt_values - rt_target));
  selected_idx = valid_idx(min_idx);
  
  rephss(id_, :) = secdimlist(selected_idx, 1:3);
  sechss(idrephss2hss(id_), :) = [secdimlist(selected_idx, 1:3), ...
    0, 0, idslist, selected_idx];
end

id.slist = idslist * ones(nhss, 1);
id.section = (1:nhss)';

return
end

%% findNearestSectionBrbStatic
function [secbrb, repbrbs, id] = findNearestSectionBrbStatic(...
  xvar, idslist, options, idMapper, secListAll)
%findNearestSectionBrbStatic BRB断面の最近傍選択（静的版）

% 必要なマッピングを取得
idrepbrbs2brbs = idMapper.idrepbrbs2brbs;
idrepbrbs2var = idMapper.idrepbrbs2var;
idbrbs2slist = idMapper.idbrbs2slist;

% idrepbrbs2slistを計算
idbrbs2sec = idMapper.idbrbs2sec;
idrepbrbs2sec = idbrbs2sec(idrepbrbs2brbs);
idSectionList = idMapper.idSectionList;
idrepbrbs2slist = idSectionList(idrepbrbs2sec);

% 初期化
nbrbs = sum(idbrbs2slist == idslist);
nrepbrbs = sum(idrepbrbs2slist == idslist);
secbrb = zeros(nbrbs, 7);
repbrbs = zeros(nrepbrbs, 4);

% 断面リストデータを取得
secListCell = secListAll{idslist};
if isempty(secListCell) || ~isstruct(secListCell)
  id.slist = zeros(nbrbs, 1);
  id.section = zeros(nbrbs, 1);
  return;
end

secdimlist = secListCell.secdim;

% 各代表断面を処理
for id_ = 1:nrepbrbs
  if idrepbrbs2slist(id_) ~= idslist
    continue;
  end
  
  V1_target = xvar(idrepbrbs2var(id_, 1));
  V2_target = xvar(idrepbrbs2var(id_, 2));
  
  V1_values = secdimlist(:, 1);
  V2_values = secdimlist(:, 2);
  
  exact_match = (V1_values == V1_target) & (V2_values == V2_target);
  
  if any(exact_match)
    selected_idx = find(exact_match, 1);
  else
    distances = (V1_values - V1_target).^2 + (V2_values - V2_target).^2;
    [~, selected_idx] = min(distances);
  end
  
  repbrbs(id_, :) = secdimlist(selected_idx, 1:4);
  secbrb(idrepbrbs2brbs(id_), :) = [secdimlist(selected_idx, 1:4), ...
    0, idslist, selected_idx];
end

id.slist = idslist * ones(nbrbs, 1);
id.section = (1:nbrbs)';

return
end
