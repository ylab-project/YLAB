function stype = lookupSectionType(obj, idsec)
%lookupSectionType 断面IDから断面タイプを参照
%   stype = lookupSectionType(obj, idsec) は、断面IDに対応する
%   断面タイプを参照します。
%
%   入力引数:
%     idsec - 断面ID (スカラーまたは配列)
%
%   出力引数:
%     stype - 断面タイプ (PRM.WFS, PRM.HSS等)
%
%   例:
%     stype = mapper.lookupSectionType(10);
%     stype = mapper.lookupSectionType([1 5 10]);
%
%   参考:
%     lookupSectionListId, IdMapper

if isempty(idsec)
  stype = [];
  return;
end

% 範囲チェック
valid_mask = idsec > 0 & idsec <= obj.nsec;
stype = zeros(size(idsec));

if any(valid_mask)
  stype(valid_mask) = obj.idsec2stype_(idsec(valid_mask));
end

return
end