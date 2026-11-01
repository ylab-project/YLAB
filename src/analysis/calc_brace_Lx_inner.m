function Lx_inner_all = calc_brace_Lx_inner(member_brace, ...
  member_column, node, Dc_col)
%calc_brace_Lx_inner - ブレース両端の柱面間の水平距離を算出
%
%   Lx_inner_all = calc_brace_Lx_inner(member_brace, member_column,
%     node, Dc_col) は、calc_brace_Lx の節点間水平距離から、両端に
%   取り付く柱の構面方向の幅の半分を控除する。幅が0の柱は節点を
%   端点のまま扱う。座屈長の柱面控除と積算用の内法長で共用する。
%
%   入力引数:
%     member_brace  - ブレース部材テーブル（端点・構面方向・端点柱）
%     member_column - 柱部材テーブル（idnode1, idnode2）
%     node          - 節点テーブル（x, y）
%     Dc_col        - 構面方向の柱幅 [nmec×2]（X方向、Y方向）(mm)。
%                     控除はその半分で、控除しない柱は0
%
%   出力引数:
%     Lx_inner_all - 柱面間の水平距離 [nmeb×1] (mm)

Lx_all = calc_brace_Lx(member_brace, node);
nmeb = numel(member_brace.idme);
idmec1 = member_brace.idmec1;
idmec2 = member_brace.idmec2;
idir = member_brace.idir;
idnode1 = member_brace.idnode1;
idnode2 = member_brace.idnode2;
idnode1_col = member_column.idnode1;
idnode2_col = member_column.idnode2;
Lx_inner_all = zeros(nmeb, 1);
for ib = 1:nmeb
  % 端点側へ伸びる柱を接続形態・階番号に依存せず選ぶ。下端(idnode1)は
  % 上昇柱、上端(idnode2)は下降柱を採用し、多層ブレースで上下端の階が
  % 離れても各端点の柱幅を正しく控除する。
  Dc = Dc_col(:, idir(ib));
  D1 = col_depth_at_brace_end(idmec1(ib, :), idnode1_col, idnode1(ib), Dc);
  D2 = col_depth_at_brace_end(idmec2(ib, :), idnode2_col, idnode2(ib), Dc);
  Lx_inner_all(ib) = Lx_all(ib) - D1 / 2 - D2 / 2;
end

return
end

function D = col_depth_at_brace_end(idc_raw, idnode_col, innode, Dc)
%col_depth_at_brace_end - ブレース端点に接続する柱の幅を返す
%
%   D = col_depth_at_brace_end(idc_raw, idnode_col, innode, Dc) は、
%   候補柱のうち、端節点 idnode_col がブレース端点 innode に一致する
%   最初の柱の構面方向の幅を返す。下端には柱の idnode1、上端には
%   idnode2 を渡すことで、端点側へ伸びる柱だけを選ぶ。
%
%   入力引数:
%     idc_raw    - 柱部材ID（0含む）
%     idnode_col - 柱の照合する端節点番号 [nmec×1]
%     innode     - ブレース端点の節点番号
%     Dc         - 構面方向の柱幅 [nmec×1]
%
%   出力引数:
%     D - 構面方向の柱幅 (mm)。該当なしは0

idc = idc_raw(idc_raw > 0);
ic = idc(find(idnode_col(idc) == innode, 1));
D = 0;
if ~isempty(ic)
  D = Dc(ic);
end

return
end
