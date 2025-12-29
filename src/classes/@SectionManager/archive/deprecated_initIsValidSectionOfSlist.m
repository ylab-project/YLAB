function deprecated_initIsValidSectionOfSlist(secmgr)
% deprecated_initIsValidSectionOfSlist 有効断面リストの初期化（非推奨）
%
% この関数は非推奨です。代わりにinitValidSectionFlagCellを
% 使用してください。
%
% See also: initValidSectionFlagCell

% 非推奨警告
warning('SectionManager:DeprecatedMethod', ...
  ['deprecated_initIsValidSectionOfSlist は非推奨です。' ...
  '代わりに initValidSectionFlagCell を使用してください。']);

% 計算の準備
nwfs = secmgr.nwfs;
nlist = secmgr.secList.nlist;
slist_type = secmgr.secList.section_type;

% 断面適合性の初期化
nsecOfSlist = secmgr.secList.nsecOfList;
secmgr.isValidSectionOfSlist_ = cell(nlist,1);
for i=1:nlist
  switch slist_type(i)
    case PRM.WFS
      secmgr.isValidSectionOfSlist_{i} = true(nwfs,nsecOfSlist(i));
    case PRM.HSS
      secmgr.isValidSectionOfSlist_{i} = true(1,nsecOfSlist(i));
  end
end
end

