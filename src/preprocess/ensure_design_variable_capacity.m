function design_variable = ensure_design_variable_capacity( ...
  design_variable, minRows)
%ensure_design_variable_capacity - 設計変数テーブルの容量を確保する

ncur = height(design_variable);
if minRows <= ncur
  return
end

nadd = max(PRM.MAX_NVAR, minRows - ncur);
name = repmat({''}, nadd, 1);
isvar = nan(nadd, 1);
value = zeros(nadd, 1);
idvar = zeros(nadd, 1);
rows = table(name, isvar, value, idvar);
design_variable = [design_variable; rows];

return
end
