function [conwtg, conwtc, wtratio] = calc_wtratio( ...
  secdim, Fs, idsrep2s, idsrep2stype, grank, crank, ...
  isSNsec, options)
%calc_wtratio - 幅厚比の計算と幅厚比ランクの判定
nsec = length(Fs);

% 代表断面番号の抜き出し
idwfsrep = idsrep2s(idsrep2stype==PRM.WFS);
idhssrep = idsrep2s(idsrep2stype==PRM.HSS);

% H形鋼
H = secdim(idwfsrep,1);
B = secdim(idwfsrep,2);
tw = secdim(idwfsrep,3);
tf = secdim(idwfsrep,4);
Fwfs = Fs(idwfsrep);
isSNH = isSNsec(idwfsrep) & options.consider_SNH_WTRATIO;
grankrep = grank(idwfsrep);
[btf, dtw, conwtg, gdrank] = wtratioH( ...
  H, B, tw, tf, Fwfs, grankrep, isSNH);
wtratio.g = table(btf, dtw);
wtratio.g.drank = gdrank;

% 角形鋼管
D = secdim(idhssrep,1);
t = secdim(idhssrep,2);
Fhss = Fs(idhssrep);
crankrep = crank(idhssrep);
[bt, conwtc, cdrank] = wtratioBox(D, t, Fhss, crankrep);
wtratio.c = table(bt);
wtratio.c.drank = cdrank;

% 判定ランクを全断面ベクトルに展開
drank_sec = zeros(nsec, 1);
drank_sec(idwfsrep) = gdrank;
drank_sec(idhssrep) = cdrank;
wtratio.drank_sec = drank_sec;

return
end
