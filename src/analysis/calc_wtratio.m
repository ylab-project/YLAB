function [conwt, drank] = calc_wtratio(secdim, Fs, idsrep2s, ...
  idsrep2stype, grank, crank, isSNsec, options)
%calc_wtratio - 幅厚比の計算と幅厚比ランクの判定
%
%   [conwt, drank] = calc_wtratio(secdim, Fs,
%   idsrep2s, idsrep2stype, grank, crank, isSNsec, options) は、
%   H形鋼の梁、角形鋼管とH形鋼の柱を評価し、幅厚比制約と部材種別を
%   全代表断面の順に返す。未対応断面は両出力とも0とする。
%   H形鋼の柱は梁と同じ寸法列（H,B,tw,tf）に柱用の制限値を使う。
%   部材種別は要求種別に依存せず、群種別制約と帳票が使用する。
%
%   入力引数:
%     secdim       - 断面寸法 [nsec×7] (mm)
%     Fs           - 断面の基準強度 [nsec×1] (N/mm2)
%     idsrep2s     - 代表断面に対応する断面番号 [nsrep×1]
%     idsrep2stype - 代表断面の形状種別 [nsrep×1]
%     grank, crank - 梁・柱の要求部材種別 [nsec×1]
%     isSNsec      - SN材の断面かどうか [nsec×1]
%     options      - 計算条件
%
%   出力引数:
%     conwt - 全代表断面の幅厚比制約値 [nsrep×1]（未対応は0）
%     drank - 全代表断面の判定種別 [nsrep×1]（未対応は0）

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

% 制約値と種別は全代表断面順に格納し、未対応の断面は0とする
conwt = zeros(numel(idsrep2s), 1);
conwt(is_wfs) = conwtg;
conwt(is_hss) = conwthss;
conwt(is_cwfs) = conwtcwfs;

drank = PRM.RANK_NONE * ones(numel(idsrep2s), 1);
drank(is_wfs) = wfsdrank;
drank(is_hss) = hssdrank;
drank(is_cwfs) = cwfsdrank;

return
end
