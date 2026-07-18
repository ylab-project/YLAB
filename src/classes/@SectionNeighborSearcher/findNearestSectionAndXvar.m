function [xvar, secdim, mapping_info] = findNearestSectionAndXvar( ...
  obj, xvar0, options, initial_guess)
%findNearestSectionAndXvar - 最近傍断面と対応変数値を一体で求める
%
%   [xvar, secdim, mapping_info] = findNearestSectionAndXvar(obj,
%   xvar0, options, initial_guess) は、設計変数から最近傍断面を
%   選択し、影響する変数だけを断面値へ補正する。
%
%   入力引数:
%     obj - SectionNeighborSearcherインスタンス
%     xvar0 - 写像前の設計変数ベクトル [1×nxvar]
%     options - 共通オプション
%     initial_guess - 直前の写像結果（.x、.secdim）。省略可能
%
%   出力引数:
%     xvar - 写像後の設計変数ベクトル [1×nxvar]
%     secdim - 写像後の断面寸法配列 [nsec×7]
%     mapping_info - 再利用行数、集約変数数、補正変数数

if nargin < 4
  initial_guess = [];
end
if isempty(initial_guess)
  secdim = obj.findNearestSection(xvar0, options);
  if nargout >= 3
    [xvar, mapping_info] = obj.findNearestXvar(secdim, options);
    mapping_info.num_corrected_variables = sum(xvar ~= xvar0);
  else
    xvar = obj.findNearestXvar(secdim, options);
  end
  return
end

[secdim, id, section_info] = obj.findNearestSection( ...
  xvar0, options, initial_guess);
id_mapper = obj.idMapper_;
nxvar = id_mapper.nxvar;
representative_rows = id_mapper.idsrep2sec;
id_columns = [PRM.MAPPED_SECDIM_SLIST PRM.MAPPED_SECDIM_SECTION];
current_ids = [id.slist(representative_rows), ...
  id.section(representative_rows)];
initial_ids = initial_guess.secdim(representative_rows, id_columns);
changed_srep = any(current_ids ~= initial_ids, 2);
changed_variable_ids = id_mapper.idsrep2var(changed_srep, :);
changed_variable_ids = changed_variable_ids(changed_variable_ids > 0);
recalculate_variable = xvar0(:)' ~= initial_guess.x(:)';
recalculate_variable(changed_variable_ids) = true;

xvar = section_info.xvar;
processed_variable = false(1, nxvar);
aggregated_variable = section_info.aggregate_variable;
idsec2stype = id_mapper.idsec2stype;

% WFSの非一致共有変数だけを既存規則で集約する
wfs_variable_ids = unique([id_mapper.idH2var(:); ...
  id_mapper.idB2var(:); id_mapper.idtw2var(:); id_mapper.idtf2var(:)]);
wfs_variable_ids = wfs_variable_ids(wfs_variable_ids > 0);
wfs_target = false(1, nxvar);
wfs_target(wfs_variable_ids) = recalculate_variable(wfs_variable_ids);
wfs_aggregate = aggregated_variable & wfs_target;
if any(wfs_aggregate)
  idrepwfs2wfs = id_mapper.idrepwfs2wfs;
  secwfs = secdim(idsec2stype == PRM.WFS, :);
  repwfs = secwfs(idrepwfs2wfs, :);
  xvar = obj.findNearestXvarofWfs(repwfs, xvar, options, wfs_aggregate);
end
processed_variable(wfs_target) = true;

% HSSの非一致共有変数だけを既存規則で集約する
hss_variable_ids = unique([id_mapper.idD2var(:); id_mapper.idt2var(:)]);
hss_variable_ids = hss_variable_ids(hss_variable_ids > 0);
hss_target = false(1, nxvar);
hss_target(hss_variable_ids) = recalculate_variable(hss_variable_ids);
hss_aggregate = aggregated_variable & hss_target;
if any(hss_aggregate)
  idrephss2hss = id_mapper.idrephss2hss;
  sechss = secdim(idsec2stype == PRM.HSS, :);
  rephss = sechss(idrephss2hss, :);
  xvar = obj.findNearestXvarofHss(rephss, xvar, options, hss_aggregate);
end
processed_variable(hss_target) = true;

% その他の断面種は既存規則で対象変数だけを再計算する
brb_variable_ids = unique([id_mapper.idBrb1_var(:); ...
  id_mapper.idBrb2_var(:)]);
brb_variable_ids = brb_variable_ids(brb_variable_ids > 0);
brb_target = false(1, nxvar);
brb_target(brb_variable_ids) = recalculate_variable(brb_variable_ids);
if any(brb_target)
  idrepbrbs2brbs = id_mapper.idrepbrbs2brbs;
  secbrbs = secdim(idsec2stype == PRM.BRB, :);
  repbrbs = secbrbs(idrepbrbs2brbs, :);
  xvar = obj.findNearestXvarofBrb(repbrbs, xvar, options, brb_target);
  processed_variable(brb_target) = true;
  aggregated_variable(brb_target) = true;
end

hsr_variable_ids = unique(id_mapper.idrephsr2var(:));
hsr_variable_ids = hsr_variable_ids(hsr_variable_ids > 0);
hsr_target = false(1, nxvar);
hsr_target(hsr_variable_ids) = recalculate_variable(hsr_variable_ids);
if any(hsr_target)
  idrephsr2hsr = id_mapper.idrephsr2hsr;
  sechsr = secdim(idsec2stype == PRM.HSR, :);
  rephsr = sechsr(idrephsr2hsr, :);
  xvar = obj.findNearestXvarofHsr(rephsr, xvar, options, hsr_target);
  processed_variable(hsr_target) = true;
  aggregated_variable(hsr_target) = true;
end

is_bsteel = idsec2stype == PRM.BWFS | ...
  idsec2stype == PRM.BHSS | idsec2stype == PRM.BHSR;
bsteel_variable_ids = unique(id_mapper.idsec2var(is_bsteel, :));
bsteel_variable_ids = bsteel_variable_ids(bsteel_variable_ids > 0);
bsteel_target = false(1, nxvar);
bsteel_target(bsteel_variable_ids) = ...
  recalculate_variable(bsteel_variable_ids);
if any(bsteel_target)
  xvar = obj.findNearestXvarofBraceSteel(secdim, is_bsteel, ...
    xvar, bsteel_target);
  processed_variable(bsteel_target) = true;
  aggregated_variable(bsteel_target) = true;
end

% 対応する逆写像規則がない対象変数は従来どおり基点値へ戻す
unprocessed_variable = recalculate_variable & ~processed_variable;
xvar(unprocessed_variable) = initial_guess.x(unprocessed_variable);

if nargout >= 3
  idsec2srep = id_mapper.idsec2srep;
  unchanged_rows = true(size(secdim, 1), 1);
  has_representative = idsec2srep > 0;
  unchanged_rows(has_representative) = ...
    ~changed_srep(idsec2srep(has_representative));
  mapping_info = struct;
  mapping_info.num_section_rows = size(secdim, 1);
  mapping_info.num_reused_section_rows = sum(unchanged_rows);
  mapping_info.num_variables = nxvar;
  mapping_info.num_reused_variables = sum(~aggregated_variable);
  mapping_info.num_recomputed_variables = sum(aggregated_variable);
  mapping_info.num_corrected_variables = sum(xvar ~= xvar0);
end

return
end
