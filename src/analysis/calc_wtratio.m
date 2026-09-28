function [conwtg, conwtc, wtratio] = calc_wtratio(secdim, Fs, ...
  idsrep2s, idsrep2stype, grank, crank, isSNsec, options)
%calc_wtratio - 幅厚比の計算と幅厚比ランクの判定
%
%   [conwtg, conwtc, wtratio] = calc_wtratio(secdim, Fs,
%   idsrep2s, idsrep2stype, grank, crank, isSNsec, options) は、
%   代表断面ごとに梁の幅厚比制約 conwtg（H形鋼の梁）と柱の幅厚比制約
%   conwtc（角形鋼管とH形鋼の柱を代表断面の順に並べる）を計算する。
%   H形鋼の柱は梁と同じ寸法列（H,B,tw,tf）に柱用の制限値を使う。
%   第3出力 wtratio は帳票用の判定ランク（.drank_sec [nsec×1]）で、
%   要求された場合だけ組み立てる。
nsec = length(Fs);
isSNH = isSNsec & options.consider_SNH_WTRATIO;

% 代表断面の種別と断面番号
is_wfs = idsrep2stype == PRM.WFS;
is_hss = idsrep2stype == PRM.HSS;
is_cwfs = ismember(idsrep2stype, [PRM.CWFS PRM.CWFSI]);
idwfsrep = idsrep2s(is_wfs);
idhssrep = idsrep2s(is_hss);
idcwfsrep = idsrep2s(is_cwfs);

% H形鋼の梁（表12.3・12.4）
[~, ~, conwtg, wfsdrank] = wtratioH(secdim(idwfsrep,1), ...
  secdim(idwfsrep,2), secdim(idwfsrep,3), secdim(idwfsrep,4), ...
  Fs(idwfsrep), grank(idwfsrep), isSNH(idwfsrep), PRM.GIRDER);

% 角形鋼管の柱（表12.1）
[~, conwthss, hssdrank] = wtratioBox(secdim(idhssrep,1), ...
  secdim(idhssrep,2), Fs(idhssrep), crank(idhssrep));

% H形鋼の柱（表12.1・12.2）。X方向強軸・Y方向強軸とも寸法列は同じ
[~, ~, conwtcwfs, cwfsdrank] = wtratioH(secdim(idcwfsrep,1), ...
  secdim(idcwfsrep,2), secdim(idcwfsrep,3), secdim(idcwfsrep,4), ...
  Fs(idcwfsrep), crank(idcwfsrep), isSNH(idcwfsrep), PRM.COLUMN);

% 柱の制約値は断面番号の作業配列に書いてから代表断面の順に取り出す
conwt_sec = zeros(nsec, 1);
conwt_sec(idhssrep) = conwthss;
conwt_sec(idcwfsrep) = conwtcwfs;
conwtc = conwt_sec(idsrep2s(is_hss | is_cwfs));

% 帳票用の判定ランクは要求時だけ組み立てる（候補評価では
% conwtg・conwtc だけ使う）
if nargout >= 3
  drank_sec = zeros(nsec, 1);
  drank_sec(idwfsrep) = wfsdrank;
  drank_sec(idhssrep) = hssdrank;
  drank_sec(idcwfsrep) = cwfsdrank;
  wtratio.drank_sec = drank_sec;
end

return
end
