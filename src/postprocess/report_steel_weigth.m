function section = report_steel_weigth(fval)
import mlreportgen.report.*
import mlreportgen.dom.*

rm = reportManager();
section = Section('鋼材量');
para = Paragraph();
para.Style = [para.Style ...
  {OuterMargin("0pt","0pt","8pt","8pt") KeepWithNext(true)}];
append(section, para);

labels = {'全体 (ton)'};
table = rm.createTable(labels);
row = TableRow();
rm.append_top_border(row);
rm.append_entry(row, '%8.1f', fval);
rm.append_bottom_border(row);
append(table, row);
append(section, table);
end
