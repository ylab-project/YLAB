function [nwhead, nwbody] = write_cell_nodal_weight(com, result)
%write_cell_nodal_weight - 節点重量表のセル配列を生成（SS7互換）
%
%   [nwhead, nwbody] = write_cell_nodal_weight(com, result) は、
%   節点重量表をヘッダ部とボディ部のセル配列で返す。床自重の有無に
%   応じて 1 行/節点（13列）または 2 行/節点（14列、概算軸力TL付き）
%   モードに切替える。KBRACE-MID 節点の自重はグリッド節点に再配分
%   してから集計する。
%
%   入力引数:
%     com    - 共通オブジェクト（.node, .nnode, .nblx, .nbly, .nstory,
%              .fnode, .faddnode, .support.idnode 等）
%     result - 結果構造体（.sw, .felement 等）
%
%   出力引数:
%     nwhead - ヘッダ部 [2×ncol] cell（項目名行・単位行）
%     nwbody - ボディ部 [nrow×ncol] cell（節点別の重量行）
%
%   備考:
%     - 基礎重量は支点節点の節点外力（-fnode-faddnode）として計上。
%     - 概算軸力列（13列目）は常に空出力。
%     - 概算軸力TL（14列目、2 行モードのみ）は同 (X,Y) グリッドの
%       最上階からの合計値の累積として計算。

% 定数
nn = com.nnode;
nblx = com.nblx;
nbly = com.nbly;
nstory = com.nstory;

% 共通配列（すべて (nnode, 6) / (nnode, 6, nlc)）
node = com.node;
sw = result.sw;
feqvec = result.felement(:, :, 1);  % G+P ケース
fnode = com.fnode(:, :, 1);
faddnode = com.faddnode(:, :, 1);
idsup2n = com.support.idnode;
has_new = result.element_weight.has_new_input;
% 要素荷重が無いモデルでは classified は全ゼロで、控除も恒等になる
classified = result.element_weight.nodal;
feqvec = feqvec - result.element_weight.analysis_felement(:, :, 1);

% KBRACE-MID節点の自重と要素荷重をグリッド節点に再配分
[feqvec, fg_r, fw_r, fc_r, f_r, classified] = ...
  redistribute_kbrace_mid(com, feqvec, sw.fg, sw.fw, sw.fc, sw.f, ...
  classified);
sw.fg = fg_r;
sw.fw = fw_r;
sw.fc = fc_r;
sw.f = f_r;

% 旧入力の床自重またはL.L寄与があれば上下2行で出力する
% 閾値は fmt() の表示打切りと一致させる（節点力はN単位）
fmt_threshold_kn = 0.05;
ll_all = reshape(sum(classified(:, 3, PRM.ELOAD_CASE_LL, :), 4), nn, 1);
has_floor = any(abs(feqvec(:, 3)) >= fmt_threshold_kn * 1000) ...
  || any(abs(ll_all) >= fmt_threshold_kn * 1000);

% --- ヘッダ ---
if has_floor
  nwhead = {'X軸', 'Y軸', '層', '床自重', '梁自重', '壁自重', ...
    '特殊荷重', '柱自重', '補正', 'ﾌﾚｰﾑ外', '基礎重量', '合計', ...
    '概算軸力', '概算軸力TL'; '', '', '', 'kN', 'kN', 'kN', 'kN', ...
    'kN', 'kN', 'kN', 'kN', 'kN', 'kN', 'kN'};
  ncol = 15;  % 14データ列 + marker列
  nwbody = cell(nn*2, ncol);
else
  nwhead = {'X軸', 'Y軸', '層', '床自重', '梁自重', '壁自重', ...
    '特殊荷重', '柱自重', '補正', 'ﾌﾚｰﾑ外', '基礎重量', '合計', ...
    '概算軸力'; '', '', '', 'kN', 'kN', 'kN', 'kN', 'kN', 'kN', ...
    'kN', 'kN', 'kN', 'kN'};
  ncol = 14;  % 13データ列 + marker列
  nwbody = cell(nn, ncol);
end

innn = 1:nn;
irow = 0;
for iy = 1:nbly
  for ix = 1:nblx
    axial_sum_tl = 0;  % 概算軸力TL（合計の累積、2 行モードのみ使用）
    for i = 1:nstory
      ist = nstory-i+1;
      in = innn(node.idx==ix & node.idy==iy & node.idstory==ist);
      % ブレース用柱分割節点をスキップ
      in = in(node.type(in) ~= PRM.NODE_BRACE_FOR_COLUMN);
      if isempty(in)
        continue
      end
      % 同一化された節点はスキップ
      if node.idrep(in) > 0
        continue
      end
      % PZ成分を旧入力、L.L、D.Lの重量分類へ分ける
      legacy_floor = feqvec(in, 3) * 1.d-3;
      ll_type = reshape(classified(in, 3, PRM.ELOAD_CASE_LL, :), ...
        1, []) * 1.d-3;
      dl_type = reshape(classified(in, 3, PRM.ELOAD_CASE_DL, :), ...
        1, []) * 1.d-3;
      fg_ = sw.fg(in, 3) * 1.d-3;
      fw_ = sw.fw(in, 3) * 1.d-3;
      fc_ = sw.fc(in, 3) * 1.d-3;
      nf_ = (fnode(in, 3) + faddnode(in, 3)) * 1.d-3;
      % 旧入力の節点外力分類だけは現行規則を維持する
      if any(idsup2n == in)
        legacy_foundation = -nf_;
      else
        legacy_foundation = 0;
        legacy_floor = legacy_floor - nf_;
      end
      upper_floor = legacy_floor + ll_type(PRM.ELOAD_TYPE_FLOOR);
      upper_special = ll_type(PRM.ELOAD_TYPE_SPECIAL);
      upper_total = legacy_floor + sum(ll_type);
      lower_floor = dl_type(PRM.ELOAD_TYPE_FLOOR);
      lower_wall = dl_type(PRM.ELOAD_TYPE_WALL);
      lower_special = dl_type(PRM.ELOAD_TYPE_SPECIAL);
      lower_correction = dl_type(PRM.ELOAD_TYPE_CORRECTION);
      lower_frameoutside = dl_type(PRM.ELOAD_TYPE_FRAME_OUT);
      lower_foundation = legacy_foundation ...
        + dl_type(PRM.ELOAD_TYPE_FOUNDATION);
      total_ = legacy_floor + sum(ll_type) + sum(dl_type) ...
        + sw.f(in, 3) * 1.d-3 + legacy_foundation;
      axial_sum_tl = axial_sum_tl + total_;
      if has_floor
        % 2 行/節点モード: 1 行目は継続行（末尾に CONT_MARKER）
        irow = irow + 1;
        nwbody{irow,1} = node.xname{in};
        nwbody{irow,2} = node.yname{in};
        nwbody{irow,3} = node.zname{in};
        nwbody{irow,4} = fmt(upper_floor);
        nwbody{irow,7} = fmt(upper_special);
        if has_new
          nwbody{irow,12} = fmt(upper_total);
        end
        nwbody{irow,ncol} = PRM.CONT_MARKER;
        % 2行目へD.L分類と自重を出力する
        irow = irow + 1;
        nwbody{irow,4} = fmt(lower_floor);
        nwbody{irow,5} = fmt(fg_);
        nwbody{irow,6} = fmt(lower_wall + fw_);
        nwbody{irow,7} = fmt(lower_special);
        nwbody{irow,8} = fmt(fc_);
        nwbody{irow,9} = fmt(lower_correction);
        nwbody{irow,10} = fmt(lower_frameoutside);
        nwbody{irow,11} = fmt(lower_foundation);
        nwbody{irow,12} = fmt(total_);
        nwbody{irow,14} = fmt(axial_sum_tl);
      else
        % 1 行/節点モード（概算軸力列は空出力）
        irow = irow + 1;
        merged = ll_type + dl_type;
        nwbody{irow,1} = node.xname{in};
        nwbody{irow,2} = node.yname{in};
        nwbody{irow,3} = node.zname{in};
        nwbody{irow,4} = fmt(legacy_floor + merged(PRM.ELOAD_TYPE_FLOOR));
        nwbody{irow,5} = fmt(fg_);
        nwbody{irow,6} = fmt(fw_ + merged(PRM.ELOAD_TYPE_WALL));
        nwbody{irow,7} = fmt(merged(PRM.ELOAD_TYPE_SPECIAL));
        nwbody{irow,8} = fmt(fc_);
        nwbody{irow,9} = fmt(merged(PRM.ELOAD_TYPE_CORRECTION));
        nwbody{irow,10} = fmt(merged(PRM.ELOAD_TYPE_FRAME_OUT));
        nwbody{irow,11} = fmt(legacy_foundation ...
          + merged(PRM.ELOAD_TYPE_FOUNDATION));
        nwbody{irow,12} = fmt(total_);
      end
    end
  end
end
nwbody = nwbody(1:irow,:);

return

  function s = fmt(v)
  %fmt - 0は空欄、それ以外は小数1桁で切り上げ書式化
  %
  %   s = fmt(v) は、数値 v が |v| < fmt_threshold_kn なら空文字、
  %   それ以外は SS7 互換の切り上げ（絶対値方向）で小数1桁の文字列を
  %   返す。しきい値はメイン関数の fmt_threshold_kn を参照する。
  %
  %   入力引数:
  %     v - 数値（kN 単位想定）
  %
  %   出力引数:
  %     s - 書式化文字列
    if abs(v) < fmt_threshold_kn
      s = '';
    else
      % 絶対値方向の切り上げ（SS7 出力に合わせる）
      rounded = sign(v) * ceil(abs(v) * 10) / 10;
      s = sprintf('%.1f', rounded);
    end

    return
  end
end
