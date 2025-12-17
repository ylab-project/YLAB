function section = report_desgin_variables(com, xvar)
import mlreportgen.report.*
import mlreportgen.dom.*
import mlreportgen.utils.*

% 定数
maxcols = 10;

% 共通配列
% Hp = com.Hp;
% Bp = com.Bp;
% twp = com.twp;
% tfp = com.tfp;
% Dp = com.Dp;
% tp = com.tp;
Hp = com.secmgr.idH2var;
Bp = com.secmgr.idB2var;
twp = com.secmgr.idtw2var;
tfp = com.secmgr.idtf2var;
Dp = com.secmgr.idD2var;
tp = com.secmgr.idt2var;
variable = com.design.variable;

% 準備
rm = reportManager();
labels = {'1', '2', '3', '4', '5', '6', '7', '8', '9', '10', ...
  '11', '12', '13', '14', '15', '16', '17', '18', '19', '20'};
section = Section('最適解');
para = Paragraph();
para.Style = [para.Style ...
  {OuterMargin("0pt","0pt","0pt","0pt") KeepWithNext(true)}];
append(section, para);

% --- 変数番号 ---
para = Paragraph('設計解');
para.Style = [para.Style ...
  {OuterMargin("0pt","0pt","8pt","8pt") KeepWithNext(true)}];
append(section, para);
table = rm.createTable(labels(1:min(length(xvar), 20)));
rm.appned_multi_entry(table, '%g', xvar);
rm.append_top_border(table.Body);
rm.append_bottom_border(table.Body);
append(section, table);

% --- H寸法番号 ---
para = Paragraph('H');
para.Style = [para.Style ...
  {OuterMargin("0pt","0pt","8pt","8pt") KeepWithNext(true)}];
append(section, para);
table = rm.createTable(variable.name(Hp)');
rm.appned_multi_entry(table, '%g', xvar(Hp));
% rm.append_top_border(table.Body);
rm.append_bottom_border(table);

% 列幅設定と分割
n = length(Hp);
specs = TableColSpec; specs.Span = n; specs.Style = {Width('40pt')};
grps = TableColSpecGroup; grps.Span = n; grps.ColSpecs = specs;
table.ColSpecGroups = grps;
slice_table(table)

% --- B寸法番号 ---
para = Paragraph('B');
para.Style = [para.Style ...
  {OuterMargin("0pt","0pt","8pt","8pt") KeepWithNext(true)}];
append(section, para);
table = rm.createTable(variable.name(Bp)');
rm.appned_multi_entry(table, '%g', xvar(Bp));
rm.append_bottom_border(table);

% 列幅設定と分割
n = length(Bp);
specs = TableColSpec; specs.Span = n; specs.Style = {Width('40pt')};
grps = TableColSpecGroup; grps.Span = n; grps.ColSpecs = specs;
table.ColSpecGroups = grps;
slice_table(table)

% --- tw寸法番号 ---
para = Paragraph('tw');
para.Style = [para.Style ...
  {OuterMargin("0pt","0pt","8pt","8pt") KeepWithNext(true)}];
append(section, para);
table = rm.createTable(variable.name(twp)');
rm.appned_multi_entry(table, '%g', xvar(twp));
rm.append_bottom_border(table);

% 列幅設定と分割
n = length(twp);
specs = TableColSpec; specs.Span = n; specs.Style = {Width('40pt')};
grps = TableColSpecGroup; grps.Span = n; grps.ColSpecs = specs;
table.ColSpecGroups = grps;
slice_table(table)

% --- tf寸法番号 ---
para = Paragraph('tf');
para.Style = [para.Style ...
  {OuterMargin("0pt","0pt","8pt","8pt") KeepWithNext(true)}];
append(section, para);
table = rm.createTable(variable.name(tfp)');
rm.appned_multi_entry(table, '%g', xvar(tfp));
rm.append_bottom_border(table);

% 列幅設定と分割
n = length(tfp);
specs = TableColSpec; specs.Span = n; specs.Style = {Width('40pt')};
grps = TableColSpecGroup; grps.Span = n; grps.ColSpecs = specs;
table.ColSpecGroups = grps;
slice_table(table)

% --- D寸法番号 ---
para = Paragraph('D');
para.Style = [para.Style ...
  {OuterMargin("0pt","0pt","8pt","8pt") KeepWithNext(true)}];
append(section, para);
table = rm.createTable(variable.name(Dp)');
rm.appned_multi_entry(table, '%g', xvar(Dp));
rm.append_bottom_border(table);

% 列幅設定と分割
n = length(Dp);
specs = TableColSpec; specs.Span = n; specs.Style = {Width('40pt')};
grps = TableColSpecGroup; grps.Span = n; grps.ColSpecs = specs;
table.ColSpecGroups = grps;
slice_table(table)
% append(section, table);

% --- t寸法番号 ---
para = Paragraph('t');
para.Style = [para.Style ...
  {OuterMargin("0pt","0pt","8pt","8pt") KeepWithNext(true)}];
append(section, para);
table = rm.createTable(variable.name(tp)');
rm.appned_multi_entry(table, '%g', xvar(tp));
rm.append_bottom_border(table);

% 列幅設定と分割
n = length(tp);
specs = TableColSpec; specs.Span = n; specs.Style = {Width('40pt')};
grps = TableColSpecGroup; grps.Span = n; grps.ColSpecs = specs;
table.ColSpecGroups = grps;
slice_table(table)

return
%--------------------------------------------------------------------------
  function slice_table(table)
    % 分割処理
    slicer = TableSlicer('Table', table, 'MaxCols', maxcols, 'RepeatCols', 0);
    slices = slicer.slice();
    for slice = slices
      add(section, slice.Table);
      para = Paragraph();
      para.Style = [para.Style {OuterMargin("0pt","0pt","0pt","8pt")}];
      add(section, para);
    end
  end
end
