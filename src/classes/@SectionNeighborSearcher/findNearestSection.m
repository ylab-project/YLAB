function [secdim, id] = findNearestSection(obj, xvar, options, ...
  initial_guess)
%findNearestSection - 全断面タイプの最近傍を選択する
%
%   [secdim, id] = findNearestSection(obj, xvar, options,
%   initial_guess) は、設計変数から最近傍の規格断面を選択する。
%   initial_guessを省略した場合は、既存の全検索を実行する。
%
%   入力引数:
%     obj           - SectionNeighborSearcherインスタンス
%     xvar          - 設計変数ベクトル [1×nxvar]
%     options       - 共通オプション
%     initial_guess - 直前の写像結果（.x、.secdim）。省略可能
%
%   出力引数:
%     secdim - 断面寸法配列 [nsec×7]
%     id     - ID構造体（.slist、.section）

if nargin < 4
  initial_guess = [];
end
use_initial_guess = ~isempty(initial_guess);

% 初期化
id_mapper = obj.idMapper_;
idsec2stype = id_mapper.idsec2stype;
idSectionList = id_mapper.idSectionList;
nsec = length(idsec2stype);
nlist = obj.standardAccessor_.nlist;
if use_initial_guess
  changed_variable = xvar(:)' ~= initial_guess.x(:)';
  changed_srep = false(id_mapper.nsrep, 1);
  idvar2srep = id_mapper.idvar2srep;
  for idvar = find(changed_variable)
    changed_srep(idvar2srep{idvar}) = true;
  end
  changed_list = false(nlist, 1);
  changed_section = id_mapper.idsrep2sec(changed_srep);
  changed_list_ids = idSectionList(changed_section);
  changed_list_ids = changed_list_ids(changed_list_ids > 0);
  changed_list(changed_list_ids) = true;
  secdim = initial_guess.secdim;
  id.slist = secdim(:, PRM.MAPPED_SECDIM_SLIST);
  id.section = secdim(:, PRM.MAPPED_SECDIM_SECTION);
else
  changed_list = true(nlist, 1);
  secdim = obj.dimension_;
  id.slist = zeros(nsec, 1);
  id.section = zeros(nsec, 1);
end

% 各断面タイプのマッピング取得
idwfs2slist = obj.idMapper_.idwfs2slist;
idhss2slist = obj.idMapper_.idhss2slist;
idbrbs2slist = obj.idMapper_.idbrbs2slist;
idhsr2slist = obj.idMapper_.idhsr2slist;
idtbs2slist = obj.idMapper_.idtbs2slist;

% 断面リストごとの最近傍選択
for idslist = 1:nlist
  if ~changed_list(idslist)
    continue
  end
  is_target = (idSectionList == idslist);
  section_type = obj.standardAccessor_.getSectionType(idslist);

  switch section_type
    case PRM.WFS
      is_target_wfs = (idwfs2slist == idslist);
      [secwfs, ~, id_temp] = obj.findNearestSectionWfs( ...
        xvar, idslist, options, initial_guess);
      secdim(is_target, 1:5) = secwfs(is_target_wfs, :);
      id.slist(is_target) = id_temp.slist(is_target_wfs);
      id.section(is_target) = id_temp.section(is_target_wfs);

    case PRM.HSS
      is_target_hss = (idhss2slist == idslist);
      [sechss, ~, id_temp] = obj.findNearestSectionHss( ...
        xvar, idslist, options, initial_guess);
      secdim(is_target, 1:3) = sechss(is_target_hss, 1:3);
      id.slist(is_target) = id_temp.slist(is_target_hss);
      id.section(is_target) = id_temp.section(is_target_hss);

    case PRM.BRB
      is_target_brbs = (idbrbs2slist == idslist);
      [secbrb, ~, id_temp] = obj.findNearestSectionBrb( ...
        xvar, idslist, options);
      secdim(is_target, 1:4) = secbrb(is_target_brbs, 1:4);
      id.slist(is_target) = id_temp.slist(is_target_brbs);
      id.section(is_target) = id_temp.section(is_target_brbs);

    case PRM.HSR
      is_target_hsr = (idhsr2slist == idslist);
      [sechsr, ~, id_temp] = obj.findNearestSectionHsr( ...
        xvar, idslist, options);
      secdim(is_target, 1:2) = sechsr(is_target_hsr, 1:2);
      id.slist(is_target) = id_temp.slist(is_target_hsr);
      id.section(is_target) = id_temp.section(is_target_hsr);

    case {PRM.BWFS, PRM.BHSS, PRM.BHSR}
      [secbrace, id_temp] = obj.findNearestSectionBraceSteel( ...
        xvar, idslist, is_target);
      secdim(is_target, 1:5) = secbrace;
      id.slist(is_target) = id_temp.slist;
      id.section(is_target) = id_temp.section;

    case PRM.RCRS
      id.slist(is_target) = 0;
      id.section(is_target) = 0;

    case PRM.TB
      is_target_tb = (idtbs2slist == idslist);
      [sectb, id_temp] = obj.findNearestSectionTb(idslist);
      secdim(is_target, 1:3) = sectb(is_target_tb, 1:3);
      id.slist(is_target) = id_temp.slist(is_target_tb);
      id.section(is_target) = id_temp.section(is_target_tb);

    otherwise
      id.slist(is_target) = 0;
      id.section(is_target) = 0;
  end
end

% 断面リストIDと断面IDを付加
secdim(:, PRM.MAPPED_SECDIM_SLIST) = id.slist;
secdim(:, PRM.MAPPED_SECDIM_SECTION) = id.section;

return
end