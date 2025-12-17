function robj = report_nodal_displacement(robj, convar, result)
import mlreportgen.report.*
import mlreportgen.dom.*

rm = reportManager();
robj.Title = '節点変位表';
append(robj, LineBreak());

% 共通定数
nlc = convar.nlc;
nj = convar.nj;

% 共通配列
idnode2coord = convar.idnode2coord;

% --- 節点変位の書き出し ---
trgmat = transrg(convar);
dg = trgmat*result.dvec;
labels = {'節点番号', '　X', '　Y', '　Z', ...
  'ux [mm]', 'uy [mm]', 'uz [mm]', ...
  sprintf('\x03B8x [rad]'), sprintf('\x03B8y [rad]'), sprintf('\x03B8z [rad]')};
for ilc=1:nlc
  sec = Section();
  sec.Title = sprintf('荷重ケース%d', ilc);
  append(sec, rm.print(sprintf('荷重ケース%d', ilc)));
  table = rm.createTable(labels);
  for ij=1:nj
    row = TableRow();
    rm.append_entry(row, '%g', ij);
    rm.append_entry(row, '%g', idnode2coord(1:3,ij));
    ijk = (ij-1)*6+(1:6);
    rm.append_entry(row, '%6.2f', dg(ijk(1:3),ilc))
    rm.append_entry(row, '%6.4f', dg(ijk(4:6),ilc))
    append(table, row);
  end
  rm.append_top_border(table.Body);
  rm.append_bottom_border(table.Body);
  append(sec, table);
  append(robj, sec);
  append(robj, PageBreak());
end

end
