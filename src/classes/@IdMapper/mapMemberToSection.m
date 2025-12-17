function idme2sec = mapMemberToSection(obj)
%mapMemberToSection 全部材の断面IDマッピングを取得
%   idme2sec = mapMemberToSection(obj) は、全部材に対する
%   断面IDマッピングを返します。
%
%   出力引数:
%     idme2sec - 部材→断面ID [nme×1]
%
%   例:
%     idme2sec = mapper.mapMemberToSection();
%
%   参考:
%     mapMemberToSectionType, IdMapper

idme2sec = obj.idme2sec_;

return
end