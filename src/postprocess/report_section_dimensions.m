function section = report_section_dimensions(xvar ,com, result, options)
import mlreportgen.report.*
import mlreportgen.dom.*
import mlreportgen.utils.*

% 定数
maxcols = 6;

% 計算の準備
rm = reportManager();
section = Section('断面リスト');
para = Paragraph();
para.Style = [para.Style ...
  {OuterMargin("0pt","0pt","0pt","8pt") KeepWithNext(true)}];
append(section, para);

% ヘッダと本体
[gshead, gsbody, cshead, csbody] = write_cell_section_list(...
  xvar, com, options);

% --- 梁断面リスト ---
maxcols = 4;
para = Paragraph("大梁断面");
para.Style = [para.Style {KeepWithNext(true),...
  OuterMargin("0pt","0pt","8pt","8pt")}];
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
specs(2) = TableColSpec; specs(2).Span = n-1; specs(2).Style = {Width('130pt')};
grps = TableColSpecGroup; grps.Span = n; grps.ColSpecs = specs;
table.ColSpecGroups = grps;
slice_table(table)

% --- 柱断面リスト ---
maxcols = 5;
para = Paragraph("柱断面");
para.Style = [para.Style {KeepWithNext(true),...
  OuterMargin("0pt","0pt","8pt","8pt")}];
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
specs(2) = TableColSpec; specs(2).Span = n-1; specs(2).Style = {Width('85pt')};
grps = TableColSpecGroup; grps.Span = n; grps.ColSpecs = specs;
table.ColSpecGroups = grps;
slice_table(table)

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

% % 共通定数
% nrepc = com.nrepc;
% nrepg = com.nrepg;

% % 共通配列
% dirBeam = com.dirBeam;
% idc2mem = com.idc2mem;
% idg2mem = com.idg2mem;
% repc = com.repc;
% repg = com.repg;
% Hsec = result.Hsec;
% Bsec = result.Bsec;
% Hn = com.Hn;
% Bn = com.Bn;
% twn = com.twn;
% tfn = com.tfn;
% Dn = com.Dn;
% tn = com.tn;

% % --- 梁断面寸法の書き出し ---
% labels = {'Type', '断面番号', 'X', 'Y', 'Z', '寸法番号', 'H', 'B', 'tw', 'tf', 'r'};
% table = rm.createTable(labels);
% 
% for ixy = 1:2
%   for irg = 1:nrepg
%     % 該当方向かチェック
%     ig = repg(irg);
%     im = idg2mem(ig);
%     if (ixy~=dirBeam(im))
%       continue
%     end
% 
%     % 通りラベル
%     xyzlabel = section_xyzlabel(im, com, true);
%     nl = length(xyzlabel);
% 
%     % 設計変数番号ラベル
%     dvlabel = sprintf('(%d,%d,%d,%d)', ...
%       Hn(repg(irg)), Bn(repg(irg)), twn(repg(irg)), tfn(repg(irg)));
% 
%     for kl=1:nl
%       row = TableRow();
%       if (kl==1)
%         rm.append_top_border(row);
%         switch dirBeam(im)
%           case 1
%             rm.append_entry(row, '%s', 'GX');
%           case 2
%             rm.append_entry(row, '%s', 'GY');
%         end
%         rm.append_entry(row, '%d', irg);
%         rm.append_entry(row, '%s', xyzlabel{kl}{1});
%         rm.append_entry(row, '%s', xyzlabel{kl}{2});
%         rm.append_entry(row, '%s', xyzlabel{kl}{3});
%         rm.append_entry(row, '%s', dvlabel);
%         rm.append_entry(row, '%-8.0f', Hsec(ig,:));
%       else
%         rm.append_entry(row, '%s', '');
%         rm.append_entry(row, '%s', '');
%         rm.append_entry(row, '%s', xyzlabel{kl}{1});
%         rm.append_entry(row, '%s', xyzlabel{kl}{2});
%         rm.append_entry(row, '%s', xyzlabel{kl}{3});
%       end
%       append(table, row);
%     end
%   end
% end
% rm.append_bottom_border(row);
% append(robj, table);
% append(robj, PageBreak());
% 
% % --- 柱断面寸法の書き出し ---
% labels = {'Type', '断面番号', 'X', 'Y', 'Z', '寸法番号', 'D', 't', 'r'};
% table = rm.createTable(labels);
% for irc = 1:nrepc
%   ic = repc(irc);
%   im = idc2mem(ic);
% 
%   % 通りラベル
%   xyzlabel = section_xyzlabel(im, com, true);
%   nl = length(xyzlabel);
% 
%   % 設計変数番号ラベル
%   dvlabel = sprintf('(%d,%d)', Dn(repc(irc)), tn(repc(irc)));
% 
%   for kl=1:nl
%     row = TableRow();
%     if kl==1
%       rm.append_top_border(row);
%       rm.append_entry(row, '%s', 'C');
%       rm.append_entry(row, '%d', irc);
%       rm.append_entry(row, '%s', xyzlabel{kl}{1});
%       rm.append_entry(row, '%s', xyzlabel{kl}{2});
%       rm.append_entry(row, '%s', xyzlabel{kl}{3});
%       rm.append_entry(row, '%s', dvlabel);
%       rm.append_entry(row, '%-8.0f', Bsec(ic,:));
%     else
%       rm.append_entry(row, '%s', '');
%       rm.append_entry(row, '%s', '');
%       rm.append_entry(row, '%s', xyzlabel{kl}{1});
%       rm.append_entry(row, '%s', xyzlabel{kl}{2});
%       rm.append_entry(row, '%s', xyzlabel{kl}{3});
%     end
%     append(table, row);
%   end
% end
% rm.append_bottom_border(row);
% append(robj, table);
% end
