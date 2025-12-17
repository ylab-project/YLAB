function [secdim, id] = ...
  findNearestSection(obj, xvar, options)
%findNearestSection 全断面タイプの最近傍選択（統合版）
%   [secdim, id] = findNearestSection(obj, xvar, options) は、
%   変数値から最近傍の断面を全断面タイプについて選択します。
%
%   入力引数:
%     xvar    - 設計変数ベクトル [nxvar×1]
%     options - オプション構造体
%
%   出力引数:
%     secdim - 断面寸法配列 [nsec×ndim]
%     id     - ID構造体（.slist, .section）

% 初期化（既存のdimensionデータを保持）
idsec2stype = obj.idMapper_.idsec2stype;
idSectionList = obj.idMapper_.idSectionList;
nsec = length(idsec2stype);
nlist = obj.standardAccessor_.nlist;
secdim = obj.dimension_;  % 既存のdimensionデータを使用
id.slist = zeros(nsec, 1);
id.section = zeros(nsec, 1);

% 各断面タイプのマッピング取得
idwfs2slist = obj.idMapper_.idwfs2slist;
idhss2slist = obj.idMapper_.idhss2slist;
idbrbs2slist = obj.idMapper_.idbrbs2slist;
idhsr2slist = obj.idMapper_.idhsr2slist;

% 断面リストごとに処理（元の実装と同じループ構造）
for idslist = 1:nlist
  is_target = (idSectionList == idslist);
  
  % 断面タイプを取得
  sectionType = obj.standardAccessor_.getSectionType(idslist);
  
  switch sectionType
    case PRM.WFS
      % H形鋼
      is_target_wfs = (idwfs2slist == idslist);
      [secwfs, ~, id_temp] = ...
        obj.findNearestSectionWfs(xvar, idslist, options);
      secdim(is_target, 1:5) = secwfs(is_target_wfs, :);
      id.slist(is_target) = id_temp.slist(is_target_wfs);
      id.section(is_target) = id_temp.section(is_target_wfs);
      
    case PRM.HSS
      % 角形鋼管
      is_target_hss = (idhss2slist == idslist);
      [sechss, ~, id_temp] = ...
        obj.findNearestSectionHss(xvar, idslist, options);
      secdim(is_target, 1:3) = sechss(is_target_hss, 1:3);
      id.slist(is_target) = id_temp.slist(is_target_hss);
      id.section(is_target) = id_temp.section(is_target_hss);
      
    case PRM.BRB
      % 座屈拘束ブレース
      is_target_brbs = (idbrbs2slist == idslist);
      [secbrb, ~, id_temp] = ...
        obj.findNearestSectionBrb(xvar, idslist, options);
      secdim(is_target, 1:4) = secbrb(is_target_brbs, 1:4);
      id.slist(is_target) = id_temp.slist(is_target_brbs);
      id.section(is_target) = id_temp.section(is_target_brbs);

    case PRM.HSR
      % 円形鋼管
      is_target_hsr = (idhsr2slist == idslist);
      [sechsr, ~, id_temp] = ...
        obj.findNearestSectionHsr(xvar, idslist, options);
      secdim(is_target, 1:2) = sechsr(is_target_hsr, 1:2);
      id.slist(is_target) = id_temp.slist(is_target_hsr);
      id.section(is_target) = id_temp.section(is_target_hsr);

    case PRM.RCRS
      % RCRS断面（最適化対象外）
      id.slist(is_target) = 0;  % RCRS断面は最適化対象外なので0
      id.section(is_target) = 0;  % RCRS断面は最適化対象外なので0
      % 寸法値はdimension_の初期値をそのまま使用
      
    otherwise
      % その他の断面タイプ（最適化対象外）
      id.slist(is_target) = 0;  % 最適化対象外なので0
      id.section(is_target) = 0;  % 最適化対象外なので0
  end
end

% 6-7列目にidsec2slistを設定
% YLAB.mやoptimization_gradientで使用される形式
secdim(:, 6) = id.slist;
secdim(:, 7) = id.section;

return
end