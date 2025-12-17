function robj = report_section_calculation_girder(robj, convar, result)
import mlreportgen.report.*
import mlreportgen.dom.*

rm = reportManager();
robj.Title = '梁';
% append(robj, LineBreak());

% 共通定数
ng = convar.ng;
nlc = convar.nlc;
nm = convar.nm;

% 共通配列
c_g = convar.c_g;
dirBeam = convar.dirBeam;
idmem2g = convar.idmem2g;
repginv = convar.repginv;

% 梁許容応力度比
bri = reshape(result.bri,ng,nlc)+1; % 梁i端曲げ応力度の検定
brj = reshape(result.brj,ng,nlc)+1; % 梁j端曲げ応力度の検定
brc = reshape(result.brc,ng,nlc)+1; % 梁中央曲げ応力度の検定
bsi = reshape(result.bsi,ng,nlc)+1; % 梁i端せん断応力度の検定
bsj = reshape(result.bsj,ng,nlc)+1; % 梁j端せん断応力度の検定
brimax = [bri(:,1) max(bri(:,2:nlc),[],2)];
brjmax = [brj(:,1) max(brj(:,2:nlc),[],2)];
brcmax = [brc(:,1) max(brc(:,2:nlc),[],2)];
bsimax = max(bsi(:,1:nlc),[],2);
bsjmax = max(bsj(:,1:nlc),[],2);
bmax = max([brimax brcmax brjmax bsimax bsjmax],[],2);

% --- 梁許容応力度比の書き出し ---
labels = {...
  '部材' ,'番号', ''; ...
  'Type', '', ''; ...
  '断面', '番号', ''; ...
  '　　X', '', ''; ...
  '　　Y', '', ''; ...
  '　Z', '', ''; ...
  '検定比', '(最大)', ''; ...
  '曲げ', '長期', 'i端'; ...
  '', '', '中央'; ...
  '', '', 'j端'; ...
  '', '短期', 'i端'; ...
  '', '', '中央'; ...
  '', '', 'j端'; ...
  'せん断', '', 'i端'; ...
  '', '', 'j端'; ...
  }';
sec = Section();
sec.Title = sprintf('概要');
for ixy=1:2
  table = rm.createTable(labels);
  for im = 1:nm
    ig = idmem2g(im);
    if c_g(im) ~= PRM.GIRDER || dirBeam(ig) ~=ixy
      continue
    end
    switch dirBeam(ig)
      case 1
        typelabel = 'GX';
      case 2
        typelabel = 'GY';
    end
    irg = repginv(ig);
    xyzlabel = member_xyzlabel(im, convar, 0);
    row = TableRow();
    rm.append_entry(row, '%g', im);
    rm.append_entry(row, '%s', typelabel);
    rm.append_entry(row, '%d', irg);
    rm.append_entry(row, '%s', xyzlabel);
    rm.append_entry(row, '%8.2f', bmax(ig))
    rm.append_entry(row, '%8.2f', brimax(ig,1));
    rm.append_entry(row, '%8.2f', brcmax(ig,1));
    rm.append_entry(row, '%8.2f', brjmax(ig,1));
    rm.append_entry(row, '%8.2f', brimax(ig,2));
    rm.append_entry(row, '%8.2f', brcmax(ig,2));
    rm.append_entry(row, '%8.2f', brjmax(ig,2));
    rm.append_entry(row, '%8.2f', bsimax(ig));
    rm.append_entry(row, '%8.2f', bsjmax(ig));
    append(table, row);
  end
  rm.append_top_border(table.Body);
  rm.append_bottom_border(table.Body);
  append(sec, table);
  append(sec, PageBreak());
end
append(robj, sec);
% for ilc=1:nlc
% append(sec, rm.print(sprintf('荷重ケース%d', ilc)));
% end

end
