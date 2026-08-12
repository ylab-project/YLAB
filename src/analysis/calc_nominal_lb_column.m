function [lbc_nominal, lbc_nominal_bk] = calc_nominal_lb_column( ...
  lmc, lmc_bk, nominal_column, braced)
%calc_nominal_lb_column - 名目柱部材の補剛間隔を計算する
%
%   [lbc_nominal, lbc_nominal_bk] = calc_nominal_lb_column(
%     lmc, lmc_bk, nominal_column, braced) は、前処理で確定した
%   方向別補剛点トポロジーに従い、補剛点でない内部境界で隣接
%   セグメントを結合して補剛間隔を求める。補剛点の判定は断面寸法に
%   依存しないため、控除前 lmc と控除後 lmc_bk へ同じトポロジーを
%   適用し、それぞれの物理的な区間長を生成する。
%
%   入力引数:
%     lmc            - セグメント芯間距離（控除前）[nmc×1]
%                      Lb1/Lb2 表示用
%     lmc_bk         - セグメント芯間距離（端部控除後）[nmc×1]
%                      Lk 算定用
%     nominal_column - 名目柱部材の情報を含む構造体
%     braced         - 内部境界が補剛点か [nnmc×(maxseg-1) logical]
%
%   出力引数:
%     lbc_nominal    - 控除前補剛間隔 [nnmc×4 double]
%     lbc_nominal_bk - 控除後補剛間隔 [nnmc×4 double]
%       列順: is, ie, max, count
%         is:    開始端補剛間隔（最下端区間 = Lb1）
%         ie:    終了端補剛間隔（最上端区間 = Lb2）
%         max:   最大補剛間隔
%         count: 横補剛区間数（補剛数 = count - 1）

idnmc2mc = nominal_column.idmec;
nnmc = size(idnmc2mc, 1);

lbc_nominal = zeros(nnmc, 4);
lbc_nominal_bk = zeros(nnmc, 4);
for inmc = 1:nnmc
  nseg = nnz(idnmc2mc(inmc, :));
  imcs = idnmc2mc(inmc, 1:nseg);
  is_braced = braced(inmc, 1:nseg-1);
  lbc_nominal(inmc, :) = summarize_bracing(lmc(imcs), is_braced);
  lbc_nominal_bk(inmc, :) = summarize_bracing(lmc_bk(imcs), is_braced);
end

return
end

%--------------------------------------------------------------
function lbc = summarize_bracing(seg_length, is_braced)
%summarize_bracing - セグメント長から帳票用の補剛間隔を集約する
%
%   lbc = summarize_bracing(seg_length, is_braced) は、補剛点でない
%   内部境界で隣接セグメント長を1パスで合算し、開始端、終了端、
%   最大および区間数を1行へ集約する。
%
%   入力引数:
%     seg_length - 名目柱内のセグメント長 [nseg×1]
%     is_braced  - 内部境界が補剛点か [1×(nseg-1) logical]
%
%   出力引数:
%     lbc - 補剛間隔 [1×4]（is, ie, max, count）

% 補剛点の境界だけ区間番号を進め、同一区間のセグメントを合算する
group = cumsum([1; is_braced(:)]);
spans = accumarray(group, seg_length(:));
lbc = [spans(1) spans(end) max(spans) length(spans)];

return
end
