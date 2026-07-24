function [lbc_nominal, lbc_nominal_bk] = calc_nominal_lb_column( ...
  lmc, lmc_bk, nominal_column, js, je, is_girder, onfg_col, idmc2m)
%calc_nominal_lb_column - 名目柱部材の補剛間隔を計算する
%
%   [lbc_nominal, lbc_nominal_bk] = calc_nominal_lb_column(
%     lmc, lmc_bk, nominal_column, js, je, is_girder,
%     onfg_col, idmc2m) は、セグメント境界の横補剛点を判定し、
%   非補剛境界ではセグメントを結合して補剛間隔を算出する。
%   横補剛点の判定は lm 値に依存しないため、控除前 lmc と
%   控除後 lmc_bk の両系統を 1 回の判定走査で同時に算出する。
%
%   入力引数:
%     lmc            - セグメント芯間距離（控除前）[nmc×1]
%                      Lb1/Lb2 表示用
%     lmc_bk         - セグメント芯間距離（端部控除後）[nmc×1]
%                      Lk 算定用
%     nominal_column - 名目柱部材の情報を含む構造体
%     js             - 全部材始端節点番号 [nme×1]
%     je             - 全部材終端節点番号 [nme×1]
%     is_girder      - 該当方向の梁マスク [nme×1]
%     onfg_col       - 基礎梁接続フラグ [nmc×1]
%     idmc2m         - 柱セグメント→全部材番号
%
%   出力引数:
%     lbc_nominal    - 控除前補剛間隔 [nnmc×4 double]
%     lbc_nominal_bk - 控除後補剛間隔 [nnmc×4 double]
%       列順: is, ie, max, count
%         is:    開始端補剛間隔（最下端区間 = Lb1）
%         ie:    終了端補剛間隔（最上端区間 = Lb2）
%         max:   最大補剛間隔
%         count: 横補剛区間数（補剛数 = count - 1）

nnmc = size(nominal_column.idmec, 1);
idnmc2mc = nominal_column.idmec;

[lbc_nominal, lbc_nominal_bk] = calc_with_bracing(lmc, lmc_bk, ...
  nnmc, idnmc2mc, js, je, is_girder, onfg_col, idmc2m);

return
end

%--------------------------------------------------------------
function [lbc, lbc_bk] = calc_with_bracing(lmc, lmc_bk, nnmc, ...
  idnmc2mc, js, je, is_girder, onfg_col, idmc2m)
%calc_with_bracing - 横補剛点を考慮した補剛間隔計算（2系統同時）
%
%   [lbc, lbc_bk] = calc_with_bracing(lmc, lmc_bk, nnmc,
%     idnmc2mc, js, je, is_girder, onfg_col, idmc2m) は、
%   セグメント境界の横補剛点判定を 1 回行い、控除前と控除後の
%   両系統 lmc/lmc_bk を同じインデックスで合算する。
%
%   入力引数:
%     lmc, lmc_bk - セグメント芯間距離 2 系統 [nmc×1]
%     nnmc        - 名目柱数
%     idnmc2mc    - 名目柱→セグメント対応表
%     js, je      - 全部材始端・終端節点番号 [nme×1]
%     is_girder   - 該当方向の梁マスク [nme×1]
%     onfg_col    - 基礎梁接続フラグ [nmc×1]
%     idmc2m      - 柱セグメント→全部材番号
%
%   出力引数:
%     lbc, lbc_bk - [nnmc×4] (is, ie, max, count)

lbc = zeros(nnmc, 4);
lbc_bk = zeros(nnmc, 4);
for inmc = 1:nnmc
  ncol = nnz(idnmc2mc(inmc,:));
  imcs = idnmc2mc(inmc, 1:ncol);

  if ncol == 1
    lbc(inmc,1:3) = lmc(imcs(1));
    lbc(inmc,4) = 1;
    lbc_bk(inmc,1:3) = lmc_bk(imcs(1));
    lbc_bk(inmc,4) = 1;
    continue
  end

  % 横補剛区間に結合（lmc と lmc_bk を同じ境界判定で並列合算）
  [spans, spans_bk] = merge_spans(lmc, lmc_bk, imcs, ncol, ...
    js, je, is_girder, onfg_col, idmc2m);

  lbc(inmc,1) = spans(1);
  lbc(inmc,2) = spans(end);
  lbc(inmc,3) = max(spans);
  lbc(inmc,4) = length(spans);
  lbc_bk(inmc,1) = spans_bk(1);
  lbc_bk(inmc,2) = spans_bk(end);
  lbc_bk(inmc,3) = max(spans_bk);
  lbc_bk(inmc,4) = length(spans_bk);
end

return
end

%--------------------------------------------------------------
function [spans, spans_bk] = merge_spans(lmc, lmc_bk, imcs, ncol, ...
  js, je, is_girder, onfg_col, idmc2m)
%merge_spans - セグメントを横補剛区間に結合する（2系統同時）
%
%   [spans, spans_bk] = merge_spans(lmc, lmc_bk, imcs, ncol,
%     js, je, is_girder, onfg_col, idmc2m) は、
%   名目柱内のセグメント境界について横補剛点の有無を判定し、
%   非補剛境界では前区間に合算して横補剛区間長の列ベクトルを
%   返す。境界判定は lmc 値に依存しないため、1 回の走査で
%   制御フローを共有し、lmc と lmc_bk を同じインデックスで
%   合算する。
%
%   入力引数:
%     lmc, lmc_bk - セグメント芯間距離 2 系統 [nmc×1]
%     imcs        - 当該名目柱のセグメント番号配列 [1×ncol]
%     ncol        - 当該名目柱のセグメント数
%     js, je      - 全部材始端・終端節点番号 [nme×1]
%     is_girder   - 該当方向の梁マスク [nme×1]
%     onfg_col    - 基礎梁接続フラグ [nmc×1]
%     idmc2m      - 柱セグメント→全部材番号
%
%   出力引数:
%     spans, spans_bk - 横補剛区間長の列ベクトル [ns×1]
%                       （ns ≤ ncol、最下端=spans(1), 最上端=spans(end)）

current = lmc(imcs(1));
current_bk = lmc_bk(imcs(1));
spans = zeros(ncol, 1);
spans_bk = zeros(ncol, 1);
ns = 0;

for k = 1:ncol-1
  % 境界ノード = k番目セグメントの上端
  ime_k = idmc2m(imcs(k));
  node = je(ime_k);

  % 横補剛点の判定
  has_girder = any((js == node | je == node) & is_girder);
  has_fg = onfg_col(imcs(k+1));
  is_braced = has_girder || has_fg;

  if is_braced
    ns = ns + 1;
    spans(ns) = current;
    spans_bk(ns) = current_bk;
    current = lmc(imcs(k+1));
    current_bk = lmc_bk(imcs(k+1));
  else
    current = current + lmc(imcs(k+1));
    current_bk = current_bk + lmc_bk(imcs(k+1));
  end
end

% 最後の区間
ns = ns + 1;
spans = spans(1:ns);
spans_bk = spans_bk(1:ns);
spans(ns) = current;
spans_bk(ns) = current_bk;

return
end
