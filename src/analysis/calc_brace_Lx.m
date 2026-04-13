function Lx_all = calc_brace_Lx(member_brace, node)
%calc_brace_Lx - ブレース水平距離を算出
%
%   Lx_all = calc_brace_Lx(member_brace, node) は、
%   ブレース両端の水平距離をベクトル演算で算出する。
%
%   入力引数:
%     member_brace - ブレース部材テーブル
%     node         - 節点テーブル (x, y)
%
%   出力引数:
%     Lx_all - 水平距離 [nmeb×1]

dx = node.x(member_brace.idnode2) ...
  - node.x(member_brace.idnode1);
dy = node.y(member_brace.idnode2) ...
  - node.y(member_brace.idnode1);
Lx_all = sqrt(dx.^2 + dy.^2);

return
end
