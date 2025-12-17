function F = deprecated_getIdSecList2F(secmgr, idslist)
%deprecated_getIdSecList2F 【非推奨】断面リストからF値を取得
%   このメソッドは非推奨です。代わりに
%   propertyCalculator.extractSectionListMaterialF を使用してください。
%
%   F = deprecated_getIdSecList2F(secmgr, idslist) は、
%   指定された断面リストIDに対応するF値を返します。
%
%   入力引数:
%     idslist - 断面リストID (スカラー整数、1～nlist)
%
%   出力引数:
%     F - F値配列 [1×nsecOfList] [MPa]
%
%   参考:
%     extractSectionListMaterialF

% 旧実装を保持（deprecated_getIdSecList2Materialを使用）
idmat = deprecated_getIdSecList2Material(secmgr, idslist);
F = secmgr.material.F(idmat);

return
end