function [conwtg, conwtc, drank] = calc_wtratio(secdim, Fs, ...
  idsrep2s, idsrep2stype, grank, crank, isSNsec, options)
%calc_wtratio - 幅厚比の計算と幅厚比ランクの判定
%
%   [conwtg, conwtc, drank] = calc_wtratio(secdim, Fs,
%   idsrep2s, idsrep2stype, grank, crank, isSNsec, options) は、
%   代表断面ごとに梁の幅厚比制約 conwtg（H形鋼の梁）と柱の幅厚比制約
%   conwtc（角形鋼管とH形鋼の柱を代表断面の順に並べる）を計算する。
%   H形鋼の柱は梁と同じ寸法列（H,B,tw,tf）に柱用の制限値を使う。
%   第3出力は要求種別に依存しない幅厚比による部材種別で、
%   群種別制約と帳票が使用する。全代表断面の順に返す。
%
%   入力引数:
%     secdim       - 断面寸法 [nsec×7] (mm)
%     Fs           - 断面の基準強度 [nsec×1] (N/mm2)
%     idsrep2s     - 代表断面に対応する断面番号
%     idsrep2stype - 代表断面の形状種別
%     grank, crank - 梁・柱の要求部材種別（断面番号で参照）
%     isSNsec      - SN材の断面かどうか [nsec×1]
%     options      - 計算条件
%
%   出力引数:
%     conwtg - 代表H形梁の幅厚比制約値
%     conwtc - 代表角形鋼管柱・H形柱の幅厚比制約値
%     drank  - 全代表断面の判定種別 [nsrep×1]（未対応は0）

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

% 柱の制約値は代表断面の順で組み立て、柱の位置だけを取り出す
conwtc = zeros(numel(idsrep2s), 1);
conwtc(is_hss) = conwthss;
conwtc(is_cwfs) = conwtcwfs;
conwtc = conwtc(is_hss | is_cwfs);

% 種別は全代表断面の順に格納し、未対応の断面だけを0とする
drank = PRM.RANK_NONE * ones(numel(idsrep2s), 1);
drank(is_wfs) = wfsdrank;
drank(is_hss) = hssdrank;
drank(is_cwfs) = cwfsdrank;

return
end
