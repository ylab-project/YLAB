function idmat = deprecated_getIdSecList2Material(secmgr, idslist)
%deprecated_getIdSecList2Material 【非推奨】断面リストから材料IDを取得
%   このメソッドは非推奨です。代わりに
%   propertyCalculator.extractSectionListMaterialId を使用してください。
%
%   idmat = deprecated_getIdSecList2Material(secmgr, idslist) は、
%   指定された断面リストIDに対応する材料IDを返します。
%
%   入力引数:
%     idslist - 断面リストID (スカラー整数、1～nlist)
%
%   出力引数:
%     idmat - 材料ID配列 [1×nsecOfList]
%
%   参考:
%     extractSectionListMaterialId

% 旧実装を保持
idmat = secmgr.secList.getIdMaterial(idslist);

return
end