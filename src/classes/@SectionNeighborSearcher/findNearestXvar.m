function [xvar, mapping_info] = findNearestXvar(obj, secdim, ...
  options, initial_guess)
%findNearestXvar - 断面寸法から変数値を抽出
%
%   [xvar, mapping_info] = findNearestXvar(obj, secdim, options,
%   initial_guess) は、断面寸法データから対応する変数値を抽出する。
%   initial_guessを指定した場合は、代表断面行の規格断面IDを比較し、
%   変更代表断面に属する変数だけを再計算する。initial_guessを
%   省略した場合は、既存の全逆写像を実行する。
%
%   入力引数:
%     secdim - 断面寸法データ [nsec×7]
%     options - オプション構造体
%     initial_guess - 直前の逆写像結果（.x、.secdim）。省略可能
%
%   出力引数:
%     xvar - 変数値ベクトル [1×nxvar]
%     mapping_info - 再利用した断面行数と設計変数数

id_mapper = obj.idMapper_;
nxvar = id_mapper.nxvar;
if nargin < 4
  initial_guess = [];
end
use_initial_guess = ~isempty(initial_guess);
if use_initial_guess
  representative_rows = id_mapper.idsrep2sec;
  id_columns = [PRM.MAPPED_SECDIM_SLIST PRM.MAPPED_SECDIM_SECTION];
  current_section_ids = secdim(representative_rows, id_columns);
  initial_secdim = initial_guess.secdim;
  initial_section_ids = initial_secdim(representative_rows, id_columns);
  changed_srep = any(current_section_ids ~= initial_section_ids, 2);
  changed_variable_ids = id_mapper.idsrep2var(changed_srep, :);
  changed_variable_ids = changed_variable_ids(changed_variable_ids > 0);
  recalculate_variable = false(1, nxvar);
  recalculate_variable(changed_variable_ids) = true;
  idsec2srep = id_mapper.idsec2srep;
  unchanged_rows = true(size(secdim, 1), 1);
  has_representative = idsec2srep > 0;
  unchanged_rows(has_representative) = ...
    ~changed_srep(idsec2srep(has_representative));
  xvar = initial_guess.x(:)';
else
  unchanged_rows = false(size(secdim, 1), 1);
  recalculate_variable = true(1, nxvar);
  xvar = [];
end

% H形鋼
idsec2stype = id_mapper.idsec2stype;
idrepwfs2wfs = id_mapper.idrepwfs2wfs;
secwfs = secdim(idsec2stype == PRM.WFS, :);
repwfs = secwfs(idrepwfs2wfs, :);
xvar = obj.findNearestXvarofWfs(repwfs, xvar, options, ...
  recalculate_variable);

% 角形鋼管
idrephss2hss = id_mapper.idrephss2hss;
sechss = secdim(idsec2stype == PRM.HSS, :);
rephss = sechss(idrephss2hss, :);
xvar = obj.findNearestXvarofHss(rephss, xvar, options, ...
  recalculate_variable);

% BRB
idrepbrbs2brbs = id_mapper.idrepbrbs2brbs;
secbrbs = secdim(idsec2stype == PRM.BRB, :);
repbrbs = secbrbs(idrepbrbs2brbs, :);
xvar = obj.findNearestXvarofBrb(repbrbs, xvar, options, ...
  recalculate_variable);

% HSR（円形鋼管）
idrephsr2hsr = id_mapper.idrephsr2hsr;
sechsr = secdim(idsec2stype == PRM.HSR, :);
rephsr = sechsr(idrephsr2hsr, :);
xvar = obj.findNearestXvarofHsr(rephsr, xvar, options, ...
  recalculate_variable);

% ブレース鋼材（BWFS/BHSS/BHSR）
is_bsteel = idsec2stype == PRM.BWFS | ...
  idsec2stype == PRM.BHSS | idsec2stype == PRM.BHSR;
xvar = obj.findNearestXvarofBraceSteel(secdim, is_bsteel, xvar, ...
  recalculate_variable);

if nargout >= 2
  mapping_info = struct;
  mapping_info.num_section_rows = size(secdim, 1);
  mapping_info.num_reused_section_rows = sum(unchanged_rows);
  mapping_info.num_variables = nxvar;
  mapping_info.num_reused_variables = sum(~recalculate_variable);
  mapping_info.num_recomputed_variables = sum(recalculate_variable);
end

return
end
