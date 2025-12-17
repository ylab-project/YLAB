function [conwtg, conwtc, wtratio] = ...
  calc_wtratio(secdim, Fs, idsrep2s, idsrep2stype, grank, isSNsec, options)
% 代表断面番号の抜き出し
idwfsrep = idsrep2s(idsrep2stype==PRM.WFS);
idhssrep = idsrep2s(idsrep2stype==PRM.HSS);

% H形鋼
H = secdim(idwfsrep,1);
B = secdim(idwfsrep,2);
tw = secdim(idwfsrep,3);
tf = secdim(idwfsrep,4);
Fwfs = Fs(idwfsrep);
isSNH = isSNsec(idwfsrep)&options.consider_SNH_WTRATIO;
grankrep = grank(idwfsrep);
% [btf, dtw, conwtg] = wtratioH(H, B, tw, tf, Fwfs, ...
%   options.coptions.rank_girder, isSNH);
[btf, dtw, conwtg] = wtratioH(H, B, tw, tf, Fwfs, grankrep, isSNH);
wtratio.g = table(btf,dtw);

% 角形鋼管
D = secdim(idhssrep,1);
t = secdim(idhssrep,2);
Fhss = Fs(idhssrep);
[bt, conwtc] = wtratioBox(D, t, Fhss, options.coptions.rank_column);
wtratio.c = table(bt);
end
