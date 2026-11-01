function idme2stype = mapMemberToSectionType(obj, member)
%mapMemberToSectionType - 現在の部材に対応する断面種別を返す
%
%   idme2stype = mapMemberToSectionType(obj, member)
%   は、memberの断面番号を用いて固定した断面種別を参照する。
%
%   入力引数:
%     obj - 固定した断面対応の管理オブジェクト
%     member - 現在の解析部材。property.idsecを参照する。
%
%   出力引数:
%     idme2stype - 部材順の断面種別 [nme×1]

idme2sec = obj.mapMemberToSection(member);
idme2stype = obj.idsec2stype_(idme2sec);

return
end
