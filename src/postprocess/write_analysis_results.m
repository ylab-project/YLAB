function write_analysis_results(fout, convar, result)
% writeAnalysisResults - Write results of structural analysis.

% --- 定数 ---
nc = convar.nc;
% nely = convar.nely;
% nelz = convar.nelz;
ng = convar.ng;
nfl = convar.nfl;
nj = convar.nj;
nlc = convar.nlc;
nm = convar.nm;
nsj = convar.nsj;
idnsup2node = convar.idsup2node;

% --- 共通配列 ---
c_g = convar.c_g;
dirBeam = convar.dirBeam;
Lb = convar.Lb;
Lm = convar.lm;
repc = convar.repc;
repg = convar.repg;

fbb = result.fbb;
fbc = result.fbc;
fc = result.fc;
kcx = result.kcx;
kcy = result.kcy;
lambday = result.lambday;
lambdaz = result.lambdaz;
ratio = result.ratio;
Mc = result.Mc;
rs = result.rs;
rs0 = result.rs0;
rvec = result.rvec;
rvec0 = result.rvec0;
st = result.st;
stc = result.stc;

% --- インデックステーブル
idRpsNode = result.idRpsNode;
idmem2g = zeros(1,nm); idmem2g(c_g==PRM.GIRDER) = 1:ng;
idmem2c = zeros(1,nm); idmem2c(c_g==PRM.COLUMN) = 1:nc;
idg2mem = 1:nm; idg2mem = idg2mem(c_g==PRM.GIRDER);
idc2mem = 1:nm; idc2mem = idc2mem(c_g==PRM.COLUMN);
idnode2coord = convar.idnode2coord;

% --- 節点変位 ---
trgmat = transrg(convar);
dg = trgmat*result.dvec;
fprintf(fout, '節点変位\n');
fprintf(fout, '%-8s%-8s', 'No.', '  X Y Z');
fprintf(fout, '%-8s%-8s%-8s', 'ux', 'uy', 'uz');

fprintf(fout, '%-8s%-8s%-8s', 'rx', 'ry', 'rz');
fprintf(fout, '\n');
fmt1 = '[case %d]\n';
fmt2 = '%-8d%-8s  %+6.2e  %+6.2e  %+6.2e  %+6.2e  %+6.2e  %+6.2e\n';
for ilc=1:nlc
  fprintf(fout, fmt1, ilc);
  for ij=1:nj
    ijk = (ij-1)*6+(1:6);
    fprintf(fout, fmt2, ij, node_xyzlabel(ij), dg(ijk,ilc));
  end
end
fprintf(fout, '\n');

% --- 支点反力（重ね合わせ前） ---
fprintf(fout, '支点反力（重ね合わせ前）\n');
fmt0 = ['No.   X Y Z\t'...
  '\tRx      \tRy      \tRz       ' , ...
  '\tRmx     \tRmy     \tRmz\n'];
fmt1 = '[case %d]\n';
fprintf(fout, fmt0);
for ilc=1:nlc
  fprintf(fout, fmt1, ilc);
  for isj=1:nsj
    isjk = (isj-1)*6+(1:6);
    rrr = rvec0(isjk,ilc)';
    rrr = rrr.*[1.d-3 1.d-3 1.d-3 1.d-6 1.d-6 1.d-6];
    fprintf(fout, '%-4d%s', idnsup2node(isj), node_xyzlabel(isj));
    for  k=1:6
      fprintf(fout, '\t%9s', sprintf('%6.1f',rrr(k)));
    end
    fprintf(fout, '\n');
  end
end
fprintf(fout, '\n');

% --- 支点反力 ---
fprintf(fout, '設計用支点反力（重ね合わせ）\n');
fmt0 = ['No.   X Y Z\t'...
  '\tRx      \tRy      \tRz       ' , ...
  '\tRmx     \tRmy     \tRmz\n'];
fmt1 = '[case %d]\n';
fprintf(fout, fmt0);
for ilc=1:nlc
  fprintf(fout, fmt1, ilc);
  for isj=1:nsj
    isjk = (isj-1)*6+(1:6);
    rrr = rvec(isjk,ilc)';
    rrr = rrr.*[1.d-3 1.d-3 1.d-3 1.d-6 1.d-6 1.d-6];
    fprintf(fout, '%-4d%s', idnsup2node(isj), node_xyzlabel(isj));
    for  k=1:6
      fprintf(fout, '\t%9s', sprintf('%6.1f',rrr(k)));
    end
    fprintf(fout, '\n');
  end
end
fprintf(fout, '\n');

% --- 応力 ---
fprintf(fout, '応力（重ね合わせ前）\n');
fmt0 = ['No.   X Y Z\t'...
  '\tN       \tQy      \tQz       ' , ...
  '\tMx      \tMy      \tMz\n'];
fmt1 = '[case %d]\n';
for ilc=1:nlc
  fprintf(fout, fmt1, ilc);
  fprintf(fout, fmt0);
  ilck = (ilc-1)*12+(1:12);
  for im=1:nm
    rrr = rs0(ilck,im)';
    rrr = rrr.* [...
      1.d-3 1.d-3 1.d-3 1.d-6 1.d-6 1.d-6 ...
      1.d-3 1.d-3 1.d-3 1.d-6 1.d-6 1.d-6];
    xyzlabel = member_xyzlabel(im, convar, 2);
    fprintf(fout, '%-4d%s', im, xyzlabel{1});
    for  k=1:6
      fprintf(fout, '\t%9s', sprintf('%6.1f',rrr(k)));
    end
    fprintf(fout, '\n    %s', xyzlabel{2});
    for  k=7:12
      fprintf(fout, '\t%9s', sprintf('%6.1f',rrr(k)));
    end
    fprintf(fout, '\n');
  end
end
fprintf(fout, '\n');

% --- 応力 ---
fprintf(fout, '設計用応力（重ね合わせ）\n');
fmt0 = ['No.   X Y Z\t'...
  '\tN       \tQy      \tQz       ' , ...
  '\tMx      \tMy      \tMz\n'];
fmt1 = '[case %d]\n';
for ilc=2:nlc
  fprintf(fout, fmt0);
  fprintf(fout, fmt1, ilc);
  ilck = (ilc-1)*12+(1:12);
  for im=1:nm
    rrr = rs(ilck,im)';
    rrr = rrr.* [...
      1.d-3 1.d-3 1.d-3 1.d-6 1.d-6 1.d-6 ...
      1.d-3 1.d-3 1.d-3 1.d-6 1.d-6 1.d-6];
    xyzlabel = member_xyzlabel(im, convar, 2);
    fprintf(fout, '%-4d%s', im, xyzlabel{1});
    for  k=1:6
      fprintf(fout, '\t%9s', sprintf('%6.1f',rrr(k)));
    end
    fprintf(fout, '\n    %s', xyzlabel{2});
    for  k=7:12
      fprintf(fout, '\t%9s', sprintf('%6.1f',rrr(k)));
    end
    fprintf(fout, '\n');
  end
end
fprintf(fout, '\n');

% --- 許容応力度比 ---
bri = reshape(result.bri,ng,nlc)+1; % 梁i端曲げ応力度の検定
brj = reshape(result.brj,ng,nlc)+1; % 梁j端曲げ応力度の検定
brc = reshape(result.brc,ng,nlc)+1; % 梁中央曲げ応力度の検定
bsi = reshape(result.bsi,ng,nlc)+1; % 梁i端せん断応力度の検定
bsj = reshape(result.bsj,ng,nlc)+1; % 梁j端せん断応力度の検定
cri = reshape(result.cri,nc,nlc)+1; % 柱i端曲げ応力度の検定
crj = reshape(result.crj,nc,nlc)+1; % 柱j端曲げ応力度の検定
csi = reshape(result.csi,nc,nlc)+1; % 柱i端せん断応力度の検定
csj = reshape(result.csj,nc,nlc)+1; % 柱j端せん断応力度の検定
brimax = [bri(:,1) max(bri(:,2:nlc),[],2)];
brjmax = [brj(:,1) max(brj(:,2:nlc),[],2)];
brcmax = [brc(:,1) max(brc(:,2:nlc),[],2)];
bsimax = max(bsi(:,1:nlc),[],2);
bsjmax = max(bsj(:,1:nlc),[],2);
brmax = max([brimax brjmax bsimax bsjmax],[],2);
crimax = [cri(:,1) max(cri(:,2:nlc),[],2)];
crjmax = [crj(:,1) max(crj(:,2:nlc),[],2)];
csimax = max(csi(:,1:nlc),[],2);
csjmax = max(csj(:,1:nlc),[],2);
crmax = max([crimax crjmax csimax csjmax],[],2);

% --- 許容応力度比一覧 ---
fprintf(fout, '許容応力度比\n');
fprintf(fout, '%-8s%-16s%', 'No.', '  X   Y    Z');
fprintf(fout, '%-8s', 'Type');
fprintf(fout, '%-6s', '最大');
fprintf(fout, '%-10s%-8s', '曲げ（長期）', '');
fprintf(fout, '%-10s%-8s', '曲げ（短期）', '');
fprintf(fout, '%-5s%-8s%', 'せん断', '');
fprintf(fout, '\n');
fprintf(fout, '%-8s%-16s%', '', '');
fprintf(fout, '%-8s%', '');
fprintf(fout, '%-8s%', '');
fprintf(fout, '%-7s%-6s%-7s', 'i端', '中央', 'j端');
fprintf(fout, '%-7s%-6s%-7s', 'i端', '中央', 'j端');
fprintf(fout, '%-7s%-7s', 'i端', 'j端');
fprintf(fout, '\n');
fmt1c = '%-8s%-8.2f%-8.2f%8s%-8.2f';
fmt2c = '%-8.2f%8s%-8.2f%-8.2f%-8.2f\n';
fmt1g = '%-8s%-8.2f%-8.2f%-8.2f%-8.2f';
fmt2g = '%-8.2f%-8.2f%-8.2f%-8.2f%-8.2f\n';
for im = 1:nm
  xyzlabel = member_xyzlabel(im, convar, 1);
  fprintf(fout, '%-8d%-16s', im, xyzlabel{1});
  switch c_g(im)
    case PRM.COLUMN
      ic = idmem2c(im);
      fprintf(fout, fmt1c, ...
        'C', crmax(ic), crimax(ic,1), ' ', crjmax(ic,1));
      fprintf(fout, fmt2c, ...
        crimax(ic,2), ' ', crjmax(ic,2), csimax(ic), csjmax(ic));
    case PRM.GIRDER
      ig = idmem2g(im);
      switch dirBeam(ig)
        case 1
          typelabel = 'GX';
        case 2
          typelabel = 'GY';
      end
      fprintf(fout, fmt1g, ...
        typelabel, brmax(ig), brimax(ig,1), brcmax(ig,1), brjmax(ig,1));
      fprintf(fout, fmt2g, ...
        brimax(ig,2), brcmax(ig,2), brjmax(ig,2), bsimax(ig), bsjmax(ig));
  end
end

% 断面算定表（梁）
fprintf(fout, '\n断面算定表（梁）\n');
fmt0c = '[case %d]\n';
for ilc=1:nlc
  fprintf(fout, fmt0c, ilc);

  fprintf(fout, '%-8s', 'No.');
  fprintf(fout, '%-7s%-8s%-8s', 'σ/fb', '', '');
  fprintf(fout, '%-8s', 'Lb');
  fprintf(fout, '%-8s%-8s%-8s', 'M', '', '');
  fprintf(fout, '%-7s%-8s%-8s', 'σ', '', '');
  fprintf(fout, '%-8s%-8s%-8s', 'fb', '', '');

  fprintf(fout, '\n');
  fprintf(fout, '%-8s', '');
  fprintf(fout, '%-8s%-8s%-8s', 'i', 'c', 'j');
  fprintf(fout, '%-8s%', '');
  fprintf(fout, '%-8s%-8s%-8s', 'i', 'c', 'j');
  fprintf(fout, '%-8s%-8s%-8s', 'i', 'c', 'j');
  fprintf(fout, '%-8s%-8s%-8s', 'i', 'c', 'j');
  fprintf(fout, '\n');
  for im = 1:nm
    switch c_g(im)
      case PRM.GIRDER
        ig = idmem2g(im);
        fprintf(fout, '%-8d%', im);
        fprintf(fout, '%-8.2f%-8.2f%-8.2f', ...
          bri(ig,ilc), brc(ig,ilc), brj(ig,ilc));
        fprintf(fout, '%-8.0f', Lb(ig));
        fprintf(fout, '%-8.0f%-8.0f%-8.0f', [1.d-6 1.d-6 1.d-6].*...
          [rs(12*(ilc-1)+5,im), Mc(ilc,im), rs(12*(ilc-1)+11,im)]);
        fprintf(fout, '%-8.0f%-8.0f%-8.0f', ...
          st(12*(ilc-1)+5,im), stc(ilc,im), st(12*(ilc-1)+11,im));
        fprintf(fout, '%-8.0f%-8.0f%-8.0f', fbb(3*(ilc-1)+(1:3),ig));
        fprintf(fout, '\n');
    end
  end
  fprintf(fout, '\n');
end

% 断面算定表（柱）
fprintf(fout, '\n断面算定表（柱）\n');
fmt0c = '[case %d]\n';
for ilc=1:nlc
  fprintf(fout, fmt0c, ilc);
  fprintf(fout, '%-8s%-8s%-8s', 'No.', 'Comb-ij');
  fprintf(fout, '%-8s%-8s', '', 'Lc');
  fprintf(fout, '%-8s%-8s', 'Lk/Lc', 'lambda');
  fprintf(fout, '%-8s%-8s%-8s', 'N', 'Mi', 'Mj');
  fprintf(fout, '%-7s%-7s%-7s', 'σc', 'σbi', 'σbj');
  fprintf(fout, '%-8s%-8s', 'fc', 'fb');
  fprintf(fout, '%-7s%-7s%-7s%', 'σc/fc', 'σbi/fb', 'σbj/fb');
  fprintf(fout, '\n');
  if ilc==1
    iiilc = 1;
  else
    iiilc = 2;
  end
  for im = 1:nm
    switch c_g(im)
      case PRM.COLUMN
        ic = idmem2c(im);
        for idir = 1:2
          switch idir
            case 1
              fprintf(fout, '%-8d%', im);
              fprintf(fout, '%-8.2f%', cri(ic,ilc));
              fprintf(fout, '%-8s%-8.0f', 'x', Lm(im));
              fprintf(fout, '%-8.2f%-8.0f', kcx(ic), lambday(im));
              fprintf(fout, '%-8.0f%-8.0f%-8.0f', ...
                [1.d-3; 1.d-6; 1.d-6].*rs(12*(ilc-1)+[1 5 11], im));
              fprintf(fout, '%-8.0f%-8.0f%-8.0f', ...
                st(12*(ilc-1)+[1 5 11],im));
              fprintf(fout, '%-8.0f%-8.0f%', fc(iiilc,im), fbc(iiilc,ic));
              fprintf(fout, '%-8.2f%-8.2f%-8.2f', ...
                abs(ratio(12*(ilc-1)+[1 5 11],im)));
            case 2
              fprintf(fout, '%-8s', '');
              fprintf(fout, '%-8.2f%', crj(ic,ilc));
              fprintf(fout, '%-8s%-8s', 'y', '');
              fprintf(fout, '%-8.2f%-8.0f%', kcy(ic), lambdaz(im));
              fprintf(fout, '%-8s%-8.0f%-8.0f', '', ...
                [1.d-6; 1.d-6].*rs(12*(ilc-1)+[6 12], im));
              fprintf(fout, '%-8s%-8.0f%-8.0f', '', ...
                st(12*(ilc-1)+[6 12],im));
              fprintf(fout, '%-8s%-8.0f', '', fbc(iiilc,ic));
              fprintf(fout, '%-8s%-8.2f%-8.2f', '', ...
                abs(ratio(12*(ilc-1)+[6 12],im)));
          end
          fprintf(fout, '\n');
        end
        % fprintf(fout, ...
        %   '  柱\t%d\t%-5.2f\t%-5.2f\t%-5.2f\t%-5.2f\t%-5.2f\n', ...
        %   im, crmax(ic), crimax(ic,1), crimax(ic,2), ...
        %   crjmax(ic,1), crjmax(ic,2));
    end
  end
  fprintf(fout, '\n');
end

% --- たわみ ---
deflection_angle = result.deflection_angle;
fprintf(fout, '\n梁たわみ\n');
fprintf(fout, ' Type\tNo.\tたわみ角\n');
for ig = 1:ng
  fprintf(fout, '  G\t%d\t1/%-6.0f\n', ...
    idg2mem(ig), 1/deflection_angle(ig));
end

% --- 層間変形角 ---
drift_angle = result.drift_angle;
fprintf(fout, '\n層間変形角\n');
%fprintf(fout, ' Type\tNo.\t層間変形角\n');
fmt1 = ' Type\tNo.';
fmt2 = '  層 \t%d';
for ilc=1:nlc-1
  fmt1 = [fmt1 '\tcase%d'];
  fmt2 = [fmt2 '\t1/%-5.0f'];
end
fmt1 = [fmt1 '\n']; fmt2 = [fmt2 '\n'];
drift_angle = reshape(drift_angle, nfl, nlc-1);
fprintf(fout, fmt1, 2:nlc);
for i = 1:nfl
  fprintf(fout, fmt2, i, 1./drift_angle(i,:));
end

% --- 幅厚比 ---
nrg = length(repg);
%wid_thick = reshape(result.wid_thick,2,[])'+1;
%wid_c = result.wid_c;
wtratio = result.wtratio;
fprintf(fout, '\n幅厚比\n');
fprintf(fout, '  Type\tNo.\tウェブ\tフランジ\n');
for irg = 1:nrg
  ig = repg(irg);
  im = idg2mem(ig);
  fprintf(fout, '   G\t%d\t%-6.1f\t%-6.1f\n', ...
    im, [wtratio.g.dtw(irg) wtratio.g.btf(irg)]);
end
fprintf(fout, '\n');
fprintf(fout, '  Type\tNo.\t柱板厚\t\n');
nrc = length(repc);
for irc = 1:nrc
  ic = repc(irc);
  im = idc2mem(ic);
  fprintf(fout, '   C\t%d\t%-6.1f\n', ...
    im, wtratio.c.bt(irc));
end

% --- 柱梁耐力比 ---
rps = reshape(result.rps,2,[])+1;
fprintf(fout, '\n柱梁耐力比(ΣMpc/ΣMpb)\n');
fprintf(fout, '  Type\tNo.\tX\tY\n');
for i = 1:length(rps)
  fprintf(fout, '  節点\t%d\t%-6.2f\t%-6.2f\n', idRpsNode(i), 1.5./rps(:,i));
end

  function xyzlabel = node_xyzlabel(id)
    fmt = '|%2d%2d%2d |';
    xyzlabel = sprintf(fmt, idnode2coord(:,id));
  end

end
