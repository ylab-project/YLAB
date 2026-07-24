function [conwtg, conwtc, wtratio] = calc_wtratio( ...
  secdim, Fs, idsrep2s, idsrep2stype, grank, crank, ...
  isSNsec, options)
%calc_wtratio - 幅厚比の計算と幅厚比ランクの判定
%
%   [conwtg, conwtc, wtratio] = calc_wtratio(secdim, Fs,
%   idsrep2s, idsrep2stype, grank, crank, isSNsec, options) は、
%   梁・柱の幅厚比制約 conwtg・conwtc を計算する。第3出力 wtratio は
%   帳票用の判定ランク構造体であり、要求された場合だけ組み立てる。
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

% 角形鋼管
D = secdim(idhssrep,1);
t = secdim(idhssrep,2);
Fhss = Fs(idhssrep);
crankrep = crank(idhssrep);
[bt, conwtc, cdrank] = wtratioBox(D, t, Fhss, crankrep);

% 帳票用の判定ランク構造体は要求時だけ組み立てる（候補評価では
% conwtg・conwtc だけ使うため、table 生成を省いて反復を軽くする）
if nargout >= 3
  wtratio.g = table(btf, dtw);
  wtratio.g.drank = gdrank;
  wtratio.c = table(bt);
  wtratio.c.drank = cdrank;
  drank_sec = zeros(nsec, 1);
  drank_sec(idwfsrep) = gdrank;
  drank_sec(idhssrep) = cdrank;
  wtratio.drank_sec = drank_sec;
end

return
end
