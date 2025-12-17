function isvalid = extractValidSectionFlags(obj, idsList, idPhase)
%extractValidSectionFlags 指定断面リストの有効フラグを抽出
%   isvalid = extractValidSectionFlags(obj, idsList, idPhase) は、
%   断面リストIDとフェーズIDに基づいて有効な断面のフラグ配列を返します。
%   WFS断面の場合はフェーズによるフィルタリングも行います。
%
%   入力引数:
%     idsList - 断面リストID (スカラー整数、1～nlist)
%     idPhase - フェーズID (スカラー整数)
%
%   出力引数:
%     isvalid - 有効断面のフラグ配列 (論理値配列)
%               WFS断面: [nwfs×nsecOfList] の論理値行列
%               HSS/BRB断面: [1×nsecOfList] の論理値ベクトル
%
%   例:
%     % 断面リスト1、フェーズ3の有効フラグを取得
%     isvalid = validator.extractValidSectionFlags(1, 3);
%
%   参考:
%     initValidSectionFlagCell, SectionConstraintValidator

if nargin < 3
  error('SectionConstraintValidator:MissingArgument', ...
    ['idPhaseは必須引数です。' ...
     'extractValidSectionFlags(idsList, idPhase)の' ...
     '形式で呼び出してください。']);
end

% 有効断面リストが初期化されていない場合
if isempty(obj.validSectionFlagCell_) || ...
    length(obj.validSectionFlagCell_) < idsList || ...
    isempty(obj.validSectionFlagCell_{idsList})
  obj.initValidSectionFlagCell();
end

slist_type = obj.secList_.section_type(idsList);
switch slist_type
  case PRM.WFS
    istarget = obj.secList_.idphase{idsList} <= idPhase;
    isvalid = obj.validSectionFlagCell_{idsList};
    isvalid = isvalid(:,istarget);
  case PRM.HSS
    isvalid = obj.validSectionFlagCell_{idsList};
  otherwise
    isvalid = obj.validSectionFlagCell_{idsList};
end

return
end