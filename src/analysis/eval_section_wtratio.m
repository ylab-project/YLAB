function [conwt, drank] = eval_section_wtratio(secdim, com, ...
  options, Fs, isSNsec, grank, crank, is_wtcon)
%eval_section_wtratio - 候補断面の幅厚比制約と種別を評価する
%
%   [conwt, drank] = eval_section_wtratio(secdim, com, ...
%     options, Fs, isSNsec, grank, crank, is_wtcon) は、
%   写像済み候補の材料と実効要求から代表断面ごとの評価値を返す。
%
%   入力引数:
%     secdim      - 写像済み断面寸法 [nsec×7] (mm)
%     com         - 部材・断面・材料と要求種別
%     options     - 共通オプション
%     Fs, isSNsec - 計算済みの断面材料F値とSN材判定 [nsec×1]
%     grank, crank, is_wtcon - 実効要求種別と対象 [nsec×1]
%
%   出力引数:
%     conwt    - 代表断面順の幅厚比制約 [nsrep×1]（無効・未対応は0）
%     drank    - 代表断面順の補正前種別 [nsrep×1]（未対応は0）

idsrep2s = com.section.representative.idsec;
stype = com.section.representative.section_type;
[conwt, drank] = calc_wtratio(secdim, Fs, idsrep2s, ...
  stype, grank, crank, isSNsec, options);
is_target = is_wtcon(idsrep2s) & drank > PRM.RANK_NONE;
conwt(is_target) = conwt(is_target) + ...
  options.coptions.alfa_section_wt_ratio;
conwt(~is_target) = 0;

return
end
