function [section_brace, design_variable] = ...
  set_section_vertical_brace_manufacturer_block(dbc, com)
%set_section_vertical_brace_manufacturer_block - メーカー製品鉛直ブレース断面の読み込み

% 計算の準備
data = ...
  dbc.get_data_block('鉛直ブレース断面（メーカー製品）');
n = size(data,1);
design_variable = com.design.variable;

% 断面符号
section_name = cell(n,1);
for i=1:n
  section_name{i} = tochar(data{i,1});
end

% 断面リスト
section_list_name = cell(n,1);
id_section_list = zeros(n,1);
iddd = 1:com.nsectionList;
type = zeros(n,1);
type_name = cell(n,1);
for i=1:n
  section_list_name{i} = tochar(data{i,2});
  idx = strcmp(com.sectionList.name, ...
    section_list_name{i});
  if any(idx)
    idsl = iddd(idx);
    id_section_list(i) = idsl(1);
  else
    throw_err('IO', ...
      'SectionListNotFound', ...
      section_list_name{i}, ...
      '鉛直ブレース断面（メーカー製品）', ...
      ['符号: ' section_name{i}]);
  end
  % 同一の鉄骨形状のみ複数リスト指定可
  type_ = ...
    unique(com.sectionList.section_type(idsl));
  if length(type_)~=1
    error( ...
      '同一断面リストに対する鉄骨形状は同一としてください')
  end
  type(i) = ...
    com.sectionList.section_type(idsl(1));
  type_name(i) = ...
    com.sectionList.section_type_name(idsl(1));
end

% 設計変数番号
mvar = PRM.MAX_NSVAR;
variable = cell(n,mvar);
idvar = zeros(n,mvar);
iddd = 1:PRM.MAX_NVAR;
nvar = com.nvar;
nvrows = sum(~isnan(design_variable.isvar));
for i=1:n
  ndvar = PRM.nvar_of_section_type(type(i));
  cdata = data(i,3:(2+ndvar));
  variable(i,1:ndvar) = tochar(cdata);
  for j=1:ndvar
    idvar_ = iddd( ...
      matches(design_variable.name, variable{i,j}));
    if isempty(idvar_)
      % 変数追加
      nvrows = nvrows+1;
      nvar = nvar+1;
      design_variable(nvrows,:) = ...
        {variable{i,j}, 0, false, nvar};
      idvar_ = nvar;
    end
    idvar(i,j) = idvar_(1);
  end
end

% 寸法指定（断面リストから取得するためゼロで初期化）
dimension = zeros(n,mvar);

% 結果の保存
name = section_name;
A = zeros(n,1);
E = zeros(n,1);
unit_weight = zeros(n,1);
ir = zeros(n,1);    % 回転半径
lmbe = zeros(n,1);  % 有効細長比
tctype = zeros(n,1);
tctype(1:n) = PRM.BRACE_TENSION_COMPRESSION;
section_brace = table(name, id_section_list, ...
  type_name, type, tctype, ...
  idvar, A, E, unit_weight, ir, lmbe, dimension);

return
end
