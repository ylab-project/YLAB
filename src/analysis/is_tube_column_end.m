function is_tube = is_tube_column_end(member, ng_node1, ng_node2)
%is_tube_column_end - 角形鋼管柱だけに接続する梁端を判定する
%
%   is_tube = is_tube_column_end(member, ng_node1, ng_node2) は、
%   各梁端に接続する上下の柱がすべて角形鋼管の場合にtrueを返す。
%   H形鋼柱を含む対象端は基準解説書による検定とする。
%   検定対象の判定はexclude_joint_bearing_strengthで行う。
%
%   入力引数:
%     member - 柱の節点番号と部材断面タイプを含む部材情報
%     ng_node1, ng_node2 - 名目梁の左端・右端節点番号 [nng×1]
%
%   出力引数:
%     is_tube - 角形鋼管柱だけが接続する端 [nng×2]

col = member.column;
is_hss = member.property.section_type(col.idme) == PRM.HSS;
nodes = [ng_node1 ng_node2];
is_tube = ismember(nodes, [col.idnode1(is_hss); col.idnode2(is_hss)]) ...
  & ~ismember(nodes, [col.idnode1(~is_hss); col.idnode2(~is_hss)]);

return
end