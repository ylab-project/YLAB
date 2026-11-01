function idme2sec = mapMemberToSection(~, member)
%mapMemberToSection - 現在の部材に対応する断面番号を返す
%
%   idme2sec = mapMemberToSection(~, member)
%   は、member.property.idsecを部材の並びを変えずに返す。
%
%   入力引数:
%     ~ - 固定した断面対応の管理オブジェクト
%     member - 現在の解析部材。property.idsecを参照する。
%
%   出力引数:
%     idme2sec - 部材順の断面番号 [nme×1]

idme2sec = member.property.idsec;

return
end
