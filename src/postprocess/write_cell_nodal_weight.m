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
%     - 概算軸力列は空出力。概算軸力TL は同 (X,Y) グリッドの
%       最上階からの累積合計（2 行モードのみ）として計算。

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

% KBRACE-MID節点の自重をグリッド節点に再配分
[feqvec, fg_r, fw_r, fc_r, f_r] = redistribute_kbrace_mid( ...
  com, feqvec, sw.fg, sw.fw, sw.fc, sw.f);
sw.fg = fg_r;
sw.fw = fw_r;
sw.fc = fc_r;
sw.f = f_r;

% 床自重（feqvec PZ成分）の有無でモード切替
% - 1つでも床自重があれば 2 行/節点モード（14列、概算軸力TL付き）
% - 全節点で床自重0なら 1 行/節点モード（13列）
% 閾値 50 N は fmt() の 0.05 kN 表示打切りに対応（これ未満は非表示）
has_floor = any(abs(feqvec(:, 3)) >= 50);

% --- ヘッダ ---
if has_floor
  nwhead = {'X軸', 'Y軸', '層', '床自重', '梁自重', '壁自重', ...
    '特殊荷重', '柱自重', '補正', 'ﾌﾚｰﾑ外', '基礎重量', '合計', ...
    '概算軸力', '概算軸力TL'; '', '', '', 'kN', 'kN', 'kN', 'kN', ...
    'kN', 'kN', 'kN', 'kN', 'kN', 'kN', 'kN'};
  ncol = 15;  % 14データ列 + <RE>列
  nwbody = cell(nn*2, ncol);
else
  nwhead = {'X軸', 'Y軸', '層', '床自重', '梁自重', '壁自重', ...
    '特殊荷重', '柱自重', '補正', 'ﾌﾚｰﾑ外', '基礎重量', '合計', ...
    '概算軸力'; '', '', '', 'kN', 'kN', 'kN', 'kN', 'kN', 'kN', ...
    'kN', 'kN', 'kN', 'kN'};
  ncol = 14;  % 13データ列 + <RE>列
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
      % PZ (列3) のみ参照
      floor_ = feqvec(in, 3) * 1.d-3;
      fg_ = sw.fg(in, 3) * 1.d-3;
      fw_ = sw.fw(in, 3) * 1.d-3;
      fc_ = sw.fc(in, 3) * 1.d-3;
      nf_ = (fnode(in, 3) + faddnode(in, 3)) * 1.d-3;
      total_ = floor_ + sw.f(in, 3) * 1.d-3 - nf_;
      % 節点外力（-nf_）は支点節点では基礎重量として計上、
      % それ以外は床自重に加算（水平ブレース等の寄与として）
      if any(idsup2n == in)
        foundation_ = -nf_;
      else
        foundation_ = 0;
        floor_ = floor_ + (-nf_);
      end
      axial_sum_tl = axial_sum_tl + total_;
      if has_floor
        % 2 行/節点モード
        % 1 行目: 節点名 + 床自重
        irow = irow + 1;
        nwbody{irow,1} = node.xname{in};
        nwbody{irow,2} = node.yname{in};
        nwbody{irow,3} = node.zname{in};
        nwbody{irow,4} = fmt(floor_);
        % 2 行目: 梁/壁/柱/基礎/ﾌﾚｰﾑ外 + 合計 + 概算軸力TL + <RE>
        % 概算軸力列(13)は空出力
        irow = irow + 1;
        nwbody{irow,5} = fmt(fg_);
        nwbody{irow,6} = fmt(fw_);
        nwbody{irow,8} = fmt(fc_);
        nwbody{irow,11} = fmt(foundation_);
        nwbody{irow,12} = fmt(total_);
        nwbody{irow,14} = fmt(axial_sum_tl);
        nwbody{irow,ncol} = '<RE>';
      else
        % 1 行/節点モード（概算軸力列は空出力）
        irow = irow + 1;
        nwbody{irow,1} = node.xname{in};
        nwbody{irow,2} = node.yname{in};
        nwbody{irow,3} = node.zname{in};
        nwbody{irow,4} = fmt(floor_);
        nwbody{irow,5} = fmt(fg_);
        nwbody{irow,6} = fmt(fw_);
        nwbody{irow,8} = fmt(fc_);
        nwbody{irow,11} = fmt(foundation_);
        nwbody{irow,12} = fmt(total_);
        nwbody{irow,ncol} = '<RE>';
      end
    end
  end
end
nwbody = nwbody(1:irow,:);

return
end

function s = fmt(v)
%fmt - 0は空欄、それ以外は小数1桁で書式化
%
%   s = fmt(v) は、数値 v が |v| < 0.05 なら空文字、それ以外は
%   小数1桁の文字列を返す。
%
%   入力引数:
%     v - 数値（kN 単位想定）
%
%   出力引数:
%     s - 書式化文字列
  if abs(v) < 0.05
    s = '';
  else
    s = sprintf('%.1f', v);
  end

  return
end
