function createPropertyCalculator(secmgr, secList, material, idsec2mat)
%createPropertyCalculator - 断面の材料・係数の計算を初期化する
%
%   createPropertyCalculator(secmgr, secList, material, ...
%   idsec2mat)
%   は、断面リストと材料対応から性能計算オブジェクトを作り、
%   secmgrのpropertyCalculator_に設定する。
%
%   入力引数:
%     secmgr - 計算オブジェクトを設定する断面管理
%     secList - 材料・係数を含む断面リスト
%     material - 材料定数を持つ構造体
%     idsec2mat - 各断面の既定材料番号 [nsec×1]
%
%   出力引数:
%     なし。secmgr.propertyCalculator_へ設定する。

secmgr.propertyCalculator_ = SectionPropertyCalculator(secList, ...
  material, idsec2mat);

return
end
