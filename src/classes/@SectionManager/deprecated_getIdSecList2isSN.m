function isSN = deprecated_getIdSecList2isSN(secmgr, idslist)
%deprecated_getIdSecList2isSN 【非推奨】断面リストからSN材フラグを取得
%   このメソッドは非推奨です。代わりに
%   propertyCalculator.extractSectionListIsSN を使用してください。
%
%   isSN = deprecated_getIdSecList2isSN(secmgr, idslist) は、
%   指定された断面リストIDに対応するSN材フラグを返します。
%
%   入力引数:
%     idslist - 断面リストID (スカラー整数、1～nlist)
%
%   出力引数:
%     isSN - SN材フラグ配列 [1×nsecOfList] 論理値配列
%
%   参考:
%     extractSectionListIsSN

% 旧実装を保持
isSN = secmgr.secList.isSN{idslist};

return
end