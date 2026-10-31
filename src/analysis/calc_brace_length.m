function [lm_brace, Lx_all, Lz_all] = calc_brace_length(member_brace, node)
%calc_brace_length - 解析節点間のブレース部材長を算出する
%
%   [lm_brace, Lx_all, Lz_all] = calc_brace_length(member_brace, node)
%   は、確定した解析節点間の距離を求める。梁レベルによる構造階高の
%   更新と柱の分割は座標へ反映済みであり、ここでは加算しない。
%
%   入力引数:
%     member_brace - 接続節点と形状を持つブレースデータ
%     node         - 解析に使用する節点座標
%
%   出力引数:
%     lm_brace - ブレース部材長 [nmeb×1] (mm)
%     Lx_all   - 水平距離 [nmeb×1] (mm)
%     Lz_all   - 鉛直距離 [nmeb×1] (mm)

Lx_all = calc_brace_Lx(member_brace, node);
Lz_all = node.z(member_brace.idnode2) - node.z(member_brace.idnode1);
lm_brace = sqrt(Lx_all.^2 + Lz_all.^2);

return
end
