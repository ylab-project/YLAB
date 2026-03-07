function lbcn = calc_nominal_lb_column(lmc, nominal_column, ...
  lr_col, js, je, is_girder, onfg_col, idmc2m)
%calc_nominal_lb_column - 名目柱部材の補剛間隔を計算する
%
%   lbcn = calc_nominal_lb_column(lmc,
%     nominal_column, lr_col, js, je, is_girder,
%     onfg_col, idmc2m) は、セグメント境界の
%   横補剛点を判定し、非補剛境界ではセグメントを
%   結合して補剛間隔を算出する。
%
%   入力引数:
%     lmc            - セグメント芯間距離 [nmc×1]
%     nominal_column - 名目柱部材の情報を含む構造体
%     lr_col         - 方向別剛域長 [nmc×2]
%     js             - 全部材始端節点番号 [nme×1]
%     je             - 全部材終端節点番号 [nme×1]
%     is_girder      - 該当方向の梁マスク [nme×1]
%     onfg_col       - 基礎梁接続フラグ [nmc×1]
%     idmc2m         - 柱セグメント→全部材番号
%
%   出力引数:
%     lbcn (table): 名目柱部材の補剛間隔テーブル
%       is: 開始端補剛間隔
%       ie: 終了端補剛間隔
%       max: 最大補剛間隔

nnmc = size(nominal_column.idmec, 1);
idnmc2mc = nominal_column.idmec;

clr = lmc - sum(lr_col, 2);
lbcn_ = calc_with_bracing(clr, nnmc, idnmc2mc, js, je, ...
  is_girder, onfg_col, idmc2m);

lbcn = array2table(lbcn_, 'VariableNames', {'is','ie','max'});

return
end

%--------------------------------------------------------------
function lbcn_ = calc_with_bracing(clr, nnmc, idnmc2mc, ...
  js, je, is_girder, onfg_col, idmc2m)
%calc_with_bracing - 横補剛点を考慮した補剛間隔計算
%
%   lbcn_ = calc_with_bracing(clr, nnmc,
%     idnmc2mc, js, je, is_girder, onfg_col,
%     idmc2m) は、セグメント境界の横補剛点を判定し、
%   非補剛境界ではセグメントの clr を合算する。
%
%   入力引数:
%     clr        - セグメントのlr控除後長さ [nmc×1]
%     nnmc       - 名目柱数
%     idnmc2mc   - 名目柱→セグメント対応表
%     js         - 全部材始端節点番号 [nme×1]
%     je         - 全部材終端節点番号 [nme×1]
%     is_girder  - 該当方向の梁マスク [nme×1]
%     onfg_col   - 基礎梁接続フラグ [nmc×1]
%     idmc2m     - 柱セグメント→全部材番号
%
%   出力引数:
%     lbcn_ - [nnmc×3] (is, ie, max)

lbcn_ = zeros(nnmc, 3);
for inmc = 1:nnmc
  ncol = nnz(idnmc2mc(inmc,:));
  imcs = idnmc2mc(inmc, 1:ncol);

  if ncol == 1
    lbcn_(inmc,:) = clr(imcs(1));
    continue
  end

  % セグメントを横補剛区間に結合
  spans = merge_spans(clr, imcs, ncol, js, je, is_girder, onfg_col, ...
    idmc2m);

  lbcn_(inmc,1) = spans(1);
  lbcn_(inmc,2) = spans(end);
  lbcn_(inmc,3) = max(spans);
end

return
end

%--------------------------------------------------------------
function spans = merge_spans(clr, imcs, ncol, js, je, ...
  is_girder, onfg_col, idmc2m)
%merge_spans - セグメントを横補剛区間に結合する
%
%   spans = merge_spans(clr, imcs, ncol, js, je,
%     is_girder, onfg_col, idmc2m) は、
%   セグメント境界の横補剛点を判定し、非補剛境界
%   ではセグメントのclrを合算した区間長を返す。
%
%   入力引数:
%     clr        - セグメントのlr控除後長さ
%     imcs       - 名目柱内のセグメント番号列
%     ncol       - セグメント数
%     js, je     - 全部材始端・終端節点番号
%     is_girder  - 該当方向の梁マスク
%     onfg_col   - 基礎梁接続フラグ
%     idmc2m     - 柱セグメント→全部材番号
%
%   出力引数:
%     spans - 横補剛区間ごとの長さ [可変長]

% 区間の初期値: 最初のセグメント
current = clr(imcs(1));
spans = zeros(ncol, 1);
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
    % 補剛点: 区間を確定
    ns = ns + 1;
    spans(ns) = current;
    current = clr(imcs(k+1));
  else
    % 非補剛: 次のセグメントと合算
    current = current + clr(imcs(k+1));
  end
end

% 最後の区間
ns = ns + 1;
spans = spans(1:ns);
spans(ns) = current;

return
end
