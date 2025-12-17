function robj = report_section_properties(robj, convar, result)
import mlreportgen.report.*
import mlreportgen.dom.*

rm = reportManager();
robj.Title = '断面性能';
append(robj, LineBreak());

% 共通定数
nrepc = convar.nrepc;
nrepg = convar.nrepg;

% 共通配列
c_g = convar.c_g;
compEffect = convar.compEffect;
% jel = convar.jel;
% F = convar.F;
dirBeam = convar.dirBeam;
idc2mem = convar.idc2mem;
idg2mem = convar.idg2mem;
repc = convar.repc;
repg = convar.repg;
Hsec = result.Hsec;
Bsec = result.Bsec;
% Hn = convar.Hn;
% Bn = convar.Bn;
% twn = convar.twn;
% tfn = convar.tfn;
% Dn = convar.Dn;
% tn = convar.tn;
scallop = convar.girder_scallop_size;

% 断面性能の計算
[A, Asy, Asz, Iy, Iz, Zy, Zz, Zyf, Zpy, Zpz, JJ, Iyo, Aw]  = ...
  datasfsec(Hsec, Bsec, c_g, compEffect, scallop);
% Mpy = Zpy.*F(jel)*1.1;

% --- 梁断面性能の書き出し ---
phiI = sprintf('\x03D5I [cm4]');
labels = {'Type', '断面番号', 'X', 'Y', 'Z', ...
  'Io [cm4]', phiI, 'An [cm2]', 'As [cm2]', 'Aw [cm2]'};
table = rm.createTable(labels);

for ixy = 1:2
  for irg = 1:nrepg
    % 該当方向かチェック
    im = idg2mem(repg(irg));
    if (ixy~=dirBeam(im))
      continue
    end

    % 通りラベル
    xyzlabel = section_xyzlabel(im, convar, true);
    nl = length(xyzlabel);

    for kl=1:nl
      row = TableRow();
      if (kl==1)
        rm.append_top_border(row);
        switch dirBeam(im)
          case 1
            rm.append_entry(row, '%s', 'GX');
          case 2
            rm.append_entry(row, '%s', 'GY');
        end
        rm.append_entry(row, '%d', irg);
        rm.append_entry(row, '%s', xyzlabel{kl}{1});
        rm.append_entry(row, '%s', xyzlabel{kl}{2});
        rm.append_entry(row, '%s', xyzlabel{kl}{3});
        rm.append_entry(row, '%-8.0f', ...
          [Iyo(im)*1.d-4 Iy(im)*1.d-4 A(im)*1.d-2 ...
          Asy(im)*1.d-2 Aw(im)*1.d-2]);
      else
        rm.append_entry(row, '%s', '');
        rm.append_entry(row, '%s', '');
        rm.append_entry(row, '%s', xyzlabel{kl}{1});
        rm.append_entry(row, '%s', xyzlabel{kl}{2});
        rm.append_entry(row, '%s', xyzlabel{kl}{3});
      end
      append(table, row);
    end
  end
end
rm.append_bottom_border(row);
append(robj, table);
append(robj, PageBreak());

% --- 柱断面性能の書き出し ---
labels = {'Type', '断面番号', 'X', 'Y', 'Z', ...
  'Ix [cm4]', 'Iy [cm4]', 'An [cm2]', 'Asx [cm2]', 'Asy [cm2]'};
table = rm.createTable(labels);
for irc = 1:nrepc
  im = idc2mem(repc(irc));

  % 通りラベル
  xyzlabel = section_xyzlabel(im, convar, true);
  nl = length(xyzlabel);

  for kl=1:nl
    row = TableRow();
    if kl==1
      rm.append_top_border(row);
      rm.append_entry(row, '%s', 'C');
      rm.append_entry(row, '%d', irc);
      rm.append_entry(row, '%s', xyzlabel{kl}{1});
      rm.append_entry(row, '%s', xyzlabel{kl}{2});
      rm.append_entry(row, '%s', xyzlabel{kl}{3});
      rm.append_entry(row, '%-8.0f', ...
          [Iy(im)*1.d-4 Iz(im)*1.d-4 A(im)*1.d-2 ...
          Asy(im)*1.d-2 Asz(im)*1.d-2]);
    else
      rm.append_entry(row, '%s', '');
      rm.append_entry(row, '%s', '');
      rm.append_entry(row, '%s', xyzlabel{kl}{1});
      rm.append_entry(row, '%s', xyzlabel{kl}{2});
      rm.append_entry(row, '%s', xyzlabel{kl}{3});
    end
    append(table, row);
  end
end
rm.append_bottom_border(row);
append(robj,table);
end
