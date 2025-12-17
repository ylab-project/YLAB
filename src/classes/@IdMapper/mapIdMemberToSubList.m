function idme2sublist = mapIdMemberToSubList(obj, idsec2slist)
%mapIdMemberToSubList 部材→サブリストIDマッピングを動的計算
%
%   idsec2slistの第2列（断面ID）が動的に変化するため、
%   実行時に毎回計算する必要がある
%
% 構文
%   idme2sublist = obj.mapIdMemberToSubList(idsec2slist)
%
% 入力引数
%   idsec2slist - 断面リストID/断面IDペア [nsec×2]
%                 第1列: 断面リストID (1〜nlist)
%                 第2列: リスト内での断面ID
%
% 出力引数
%   idme2sublist - 部材→サブリストIDマッピング [nme×1]
%
% 例
%   idsec2slist = SectionManager.getSectionListMapping(secdim);
%   idme2sublist = idMapper.mapIdMemberToSubList(idsec2slist);
%
% 参照
%   IdMapper, SectionManager.getIdMemberToSubList

idSectionToSubList = zeros(obj.nsec, 1);
nlist = length(obj.idsublistCell);  % ローカル変数として計算

for ilist = 1:nlist
  isTarget = idsec2slist(:,1) == ilist;
  if any(isTarget)
    idsublist = obj.idsublistCell{ilist};  % 保存されたidsublist
    idSectionToSubList(isTarget) = idsublist(idsec2slist(isTarget,2));
  end
end

idme2sublist = idSectionToSubList(obj.idme2sec_);
end