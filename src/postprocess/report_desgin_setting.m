function section = report_desgin_setting(com, options)
import mlreportgen.report.*
import mlreportgen.dom.*
import mlreportgen.utils.*

% 共通定数
nvar = com.nvar;
maxcols = 6;

% 共通配列
% Hp = com.Hp;
% Bp = com.Bp;
% twp = com.twp;
% tfp = com.tfp;
% Dp = com.Dp;
% tp = com.tp;
% Hp = com.secmgr.idH2var;
% Bp = com.secmgr.idB2var;
% twp = com.secmgr.idtw2var;
% tfp = com.secmgr.idtf2var;
% Dp = com.secmgr.idD2var;
% tp = com.secmgr.idt2var;
variable = com.design.variable;

% 準備
section = Section('変数設定');
rm = reportManager();
labels = cell(1,nvar+1);
labels{1} = '変数';
for i=1:nvar
  labels{i+1} = ['x' num2str(i)];
end
para = Paragraph();
para.Style = [para.Style ...
  {OuterMargin("0pt","0pt","0pt","0pt") KeepWithNext(true)}];
append(section, para);

% --- 変数割当 ---
para = Paragraph('変数割当');
para.Style = [para.Style ...
  {OuterMargin("0pt","0pt","16pt","8pt") KeepWithNext(true)}];
append(section, para);
table = rm.createTable(labels);
rm.appned_multi_entry(table, '%s', [{'変数名'} variable.name']);
rm.append_bottom_border(table);

% 列幅設定
specs = TableColSpec; specs.Span = nvar; specs.Style = {Width('40pt')};
grps = TableColSpecGroup; grps.Span = nvar; grps.ColSpecs = specs;
table.ColSpecGroups = grps;

% 分割処理
slicer = TableSlicer('Table', table, 'MaxCols', 10, 'RepeatCols', 1);
slices = slicer.slice();
for slice = slices
  add(section, slice.Table);
  para = Paragraph(); 

  para.Style = [para.Style {OuterMargin("0pt","0pt","0pt","8pt")}];
  add(section, para);
end
add(section, PageBreak());

% --- 断面表 ---
[gshead, gsbody, cshead, csbody] = write_cell_section_list(...
  [], com, options);

% 梁断面リスト作成
maxcols = 4;
para = Paragraph("大梁断面");
para.Style = [para.Style {KeepWithNext(true),...
  OuterMargin("0pt","0pt","0pt","8pt")}];
add(section, para);
table = rm.createTable(gshead);
for i=1:size(gsbody,1)
  rm.appned_multi_entry(table, '%s', gsbody(i,:));
end
table.TableEntriesHAlign = "left";
table.KeepWithinPage = true;
rm.append_bottom_border(table);

% 列幅設定と分割
n = size(gsbody,2);
specs(1) = TableColSpec; specs(1).Span = 1; specs(1).Style = {Width('30pt')};
specs(2) = TableColSpec; specs(2).Span = n-1; specs(2).Style = {Width('120pt')};
grps = TableColSpecGroup; grps.Span = n; grps.ColSpecs = specs;
table.ColSpecGroups = grps;
slice_table(table)

add(section, PageBreak());

% 柱断面リスト作成
maxcols = 5;
para = Paragraph("柱断面");
para.Style = [para.Style {KeepWithNext(true),...
  OuterMargin("0pt","0pt","0pt","8pt")}];
add(section, para);
table = rm.createTable(cshead);
for i=1:size(csbody,1)
  rm.appned_multi_entry(table, '%s', csbody(i,:));
end
table.TableEntriesHAlign = "left";
table.KeepWithinPage = true;
rm.append_bottom_border(table);

% 列幅設定と分割
n = size(csbody,2);
specs(1) = TableColSpec; specs(1).Span = 1; specs(1).Style = {Width('30pt')};
specs(2) = TableColSpec; specs(2).Span = n-1; specs(2).Style = {Width('90pt')};
grps = TableColSpecGroup; grps.Span = n; grps.ColSpecs = specs;
table.ColSpecGroups = grps;
slice_table(table)

return
%--------------------------------------------------------------------------
  function slice_table(table)
    % 分割処理
    slicer = TableSlicer('Table', table, 'MaxCols', maxcols, 'RepeatCols', 1);
    slices = slicer.slice();
    for slice = slices
      add(section, slice.Table);
      para = Paragraph();
      para.Style = [para.Style {OuterMargin("0pt","0pt","0pt","8pt")}];
      add(section, para);
    end
  end
end

% % コンテンツ追加
% append(robj, section)
% 
% % --- 寸法番号 ---
% para = Paragraph('H');
% para.Style = [para.Style ...
%   {OuterMargin("0pt","0pt","8pt","8pt") KeepWithNext(true)}];
% append(robj, para);
% table = rm.createTable(variable.name(Hp)');
% rm.appned_multi_entry(table, '%g', xvar(Hp));
% rm.append_top_border(table.Body);
% rm.append_bottom_border(table.Body);
% append(robj, table);
% 
% para = Paragraph('B');
% para.Style = [para.Style ...
%   {OuterMargin("0pt","0pt","8pt","8pt") KeepWithNext(true)}];
% append(robj, para);
% table = rm.createTable(variable.name(Bp)');
% rm.appned_multi_entry(table, '%g', xvar(Bp));
% rm.append_top_border(table.Body);
% rm.append_bottom_border(table.Body);
% append(robj, table);
% 
% para = Paragraph('tw');
% para.Style = [para.Style ...
%   {OuterMargin("0pt","0pt","8pt","8pt") KeepWithNext(true)}];
% append(robj, para);
% table = rm.createTable(variable.name(twp)');
% rm.appned_multi_entry(table, '%g', xvar(twp));
% rm.append_top_border(table.Body);
% rm.append_bottom_border(table.Body);
% append(robj, table);
% 
% para = Paragraph('tf');
% para.Style = [para.Style ...
%   {OuterMargin("0pt","0pt","8pt","8pt") KeepWithNext(true)}];
% append(robj, para);
% table = rm.createTable(variable.name(tfp)');
% rm.appned_multi_entry(table, '%g', xvar(tfp));
% rm.append_top_border(table.Body);
% rm.append_bottom_border(table.Body);
% append(robj, table);
% 
% para = Paragraph('D');
% para.Style = [para.Style ...
%   {OuterMargin("0pt","0pt","8pt","8pt") KeepWithNext(true)}];
% append(robj, para);
% table = rm.createTable(variable.name(Dp)');
% rm.appned_multi_entry(table, '%g', xvar(Dp));
% rm.append_top_border(table.Body);
% rm.append_bottom_border(table.Body);
% append(robj, table);
% 
% para = Paragraph('t');
% para.Style = [para.Style ...
%   {OuterMargin("0pt","0pt","8pt","8pt") KeepWithNext(true)}];
% append(robj, para);
% table = rm.createTable(variable.name(tp)');
% rm.appned_multi_entry(table, '%g', xvar(tp));
% rm.append_top_border(table.Body);
% rm.append_bottom_border(table.Body);
% append(robj, table);
% end


