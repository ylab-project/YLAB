function isvalid = extractValidSectionFlags(obj, idsList, idPhase)
%extractValidSectionFlags 指定断面リストの有効フラグを抽出
%   isvalid = extractValidSectionFlags(obj, idsList) は、現在フェーズ用に
%   保存した有効断面フラグを返します。
%
%   isvalid = extractValidSectionFlags(obj, idsList, idPhase) は、指定した
%   フェーズについて正本から有効断面フラグを動的に抽出します。
%
%   入力引数:
%     idsList - 断面リストID (スカラー整数、1～nlist)
%     idPhase - フェーズID (スカラー整数、省略可能)
%
%   出力引数:
%     isvalid - 有効断面のフラグ配列 (論理値配列)
%
%   参考:
%     initValidSectionFlagCell, updateValidSectionFlagCell

if nargin < 3
  isvalid = obj.currentValidSectionFlagCell_{idsList};
  return
end

slistType = obj.secList_.section_type(idsList);
switch slistType
  case {PRM.WFS, PRM.HSS, PRM.HSR}
    isTarget = obj.secList_.idphase{idsList} <= idPhase;
    isvalid = obj.validSectionFlagCell_{idsList}(:, isTarget);
  otherwise
    isvalid = obj.validSectionFlagCell_{idsList};
end

return
end