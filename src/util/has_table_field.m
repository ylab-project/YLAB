function tf = has_table_field(obj, name)
%has_table_field - table/struct のフィールド有無を返す
%
%   tf = has_table_field(obj, name) は、obj が table の場合は変数名、
%   struct の場合はフィールド名として name の有無を返す。

if istable(obj)
  tf = ismember(name, obj.Properties.VariableNames);
else
  tf = isfield(obj, name);
end

return
end
