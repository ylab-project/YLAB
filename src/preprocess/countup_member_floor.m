function idfloor = countup_member_floor(com)
%countup_member_floor - 部材が跨ぐ階の数え上げ
%
%   idfloor = countup_member_floor(com) は、各部材が鉛直方向に跨ぐ階の
%   番号を数え上げる。部材両端の節点の高さに対し、階の位置z
%   (com.floor.idz) が 下端 < z <= 上端 となる階を跨ぐ階とする。
%   通し柱や多層にわたる梁は複数の階を持ち、両端が同じ高さの梁は
%   跨ぐ階を持たない。断面寸法に依存しない幾何判定なので前処理で
%   確定し、柱・梁群の種別の集計と制約で階上端の直下を横切る柱・梁を
%   採るために用いる。
%
%   入力引数:
%     com - 共通オブジェクト（member.property, node, floor を参照）
%
%   出力引数:
%     idfloor - 部材ごとの跨ぐ階の番号 [nme×k]（昇順に左詰め、余りは0）

mp = com.member.property;
idz = com.node.idz;
ids = com.node.type == PRM.NODE_BRACE_FOR_COLUMN;
idz(ids) = com.story.idz(com.node.idstory(ids));
idz1 = idz(mp.idnode1);
idz2 = idz(mp.idnode2);
bottom = min(idz1, idz2);
top = max(idz1, idz2);
floor_idz = com.floor.idz(:)';
in_floor = floor_idz > bottom & floor_idz <= top;

% 跨ぐ階の番号を部材ごとに左詰めで並べる
nme = numel(bottom);
ncol = max([1; sum(in_floor, 2)]);
idfloor = zeros(nme, ncol);
for ime = find(any(in_floor, 2))'
  ifl = find(in_floor(ime, :));
  idfloor(ime, 1:numel(ifl)) = ifl;
end

return
end
