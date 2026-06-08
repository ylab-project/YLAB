function idvar = find_design_variable_id(design_variable, vname)
%find_design_variable_id - 設計変数名から変数番号を取得する

valid = ~isnan(design_variable.isvar);
idrow = find(valid & matches(design_variable.name, vname), 1);
if isempty(idrow)
  idvar = [];
else
  idvar = design_variable.idvar(idrow);
end

return
end
