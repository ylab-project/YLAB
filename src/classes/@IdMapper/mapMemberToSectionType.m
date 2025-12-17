function idme2stype = mapMemberToSectionType(obj)
%mapMemberToSectionType 全部材の断面タイプマッピングを取得
%   idme2stype = mapMemberToSectionType(obj) は、全部材に対する
%   断面タイプマッピングを返します。
%
%   出力引数:
%     idme2stype - 部材→断面タイプ [nme×1]
%
%   例:
%     idme2stype = mapper.mapMemberToSectionType();
%
%   参考:
%     mapMemberToSection, lookupSectionType

% 部材→断面→断面タイプの2段階変換
idme2sec = obj.mapMemberToSection();
idme2stype = obj.idsec2stype_(idme2sec);

return
end