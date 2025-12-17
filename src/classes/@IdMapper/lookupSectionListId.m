function idslist = lookupSectionListId(obj, idsec)
%lookupSectionListId 断面IDから断面リストIDを参照
%   idslist = lookupSectionListId(obj, idsec) は、断面IDに対応する
%   断面リストIDを参照します。
%
%   入力引数:
%     idsec - 断面ID (スカラーまたは配列)
%
%   出力引数:
%     idslist - 断面リストID (入力と同じサイズ)
%
%   例:
%     idslist = mapper.lookupSectionListId(10);
%     idslist = mapper.lookupSectionListId([1 5 10]);
%
%   参考:
%     lookupSectionType, IdMapper

if isempty(idsec)
  idslist = [];
  return;
end

% 範囲チェック
valid_mask = idsec > 0 & idsec <= obj.nsec;
idslist = zeros(size(idsec));

if any(valid_mask)
  idslist(valid_mask) = obj.idSectionList_(idsec(valid_mask));
end

return
end