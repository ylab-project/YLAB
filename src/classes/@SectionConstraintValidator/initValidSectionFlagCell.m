function initValidSectionFlagCell(obj)
%initValidSectionFlagCell 有効断面フラグセルを初期化
%   initValidSectionFlagCell(obj) は、断面リストごとの有効性フラグを
%   初期化します。WFS断面は2次元配列、HSS/BRB断面は1次元配列として
%   初期化されます。初期状態では全ての断面を有効とします。
%
%   例:
%     validator.initValidSectionFlagCell();
%
%   参考:
%     extractValidSectionFlags, SectionConstraintValidator

% secListの確認
if obj.isSecListEmpty()
  error('SectionConstraintValidator:InitValidSectionFlagCell', ...
    'secListが空です');
end

% nwfsを内部で計算
nwfs_ = obj.nwfs;
if nwfs_ < 1
  % WFS断面が存在しない場合も処理を継続
  nwfs_ = 1;
end

% 初期化
nlist_ = obj.nlist;
nsecOfList = obj.secList_.nsecOfList;
sectionType = obj.secList_.section_type;

% cell配列の初期化
obj.validSectionFlagCell_ = cell(nlist_, 1);

% 断面タイプごとに適切なサイズで初期化
for i = 1:nlist_
  switch sectionType(i)
    case PRM.WFS
      % WFS断面: 2次元配列 (nwfs x nsecOfList)
      obj.validSectionFlagCell_{i} = ...
        true(nwfs_, nsecOfList(i));
      
    case PRM.HSS
      % HSS断面: 1次元配列 (1 x nsecOfList)
      obj.validSectionFlagCell_{i} = ...
        true(1, nsecOfList(i));
      
    case PRM.BRB
      % BRB断面: 1次元配列 (1 x nsecOfList)
      obj.validSectionFlagCell_{i} = ...
        true(1, nsecOfList(i));
      
    otherwise
      % その他: デフォルトで1次元配列
      obj.validSectionFlagCell_{i} = ...
        true(1, nsecOfList(i));
  end
end

return
end