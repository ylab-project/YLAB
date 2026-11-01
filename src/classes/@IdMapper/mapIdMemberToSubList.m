function idme2sublist = mapIdMemberToSubList(obj, idsec2slist, member)
%mapIdMemberToSubList - 現在の部材のサブリスト番号を求める
%
%   idme2sublist = mapIdMemberToSubList(obj, idsec2slist, member)
%   は、採用したリスト内断面をサブリスト番号へ変換し、部材順に返す。
%
%   入力引数:
%     obj - 固定した断面対応の管理オブジェクト
%     idsec2slist - 断面リストと候補断面の番号 [nsec×2]
%     member - 現在の解析部材。property.idsecを参照する。
%
%   出力引数:
%     idme2sublist - 部材順のサブリスト番号 [nme×1]

idSectionToSubList = zeros(obj.nsec, 1);
nlist = length(obj.idsublistCell);  % ローカル変数として計算

for ilist = 1:nlist
  isTarget = idsec2slist(:,1) == ilist;
  if any(isTarget)
    idsublist = obj.idsublistCell{ilist};  % 保存されたidsublist
    idSectionToSubList(isTarget) = idsublist(idsec2slist(isTarget,2));
  end
end

idme2sublist = idSectionToSubList(member.property.idsec);

return
end
