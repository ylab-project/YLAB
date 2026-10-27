function updateGlobalBounds(obj)
%updateGlobalBounds - 現在フェーズの設計変数の上下限を更新する
%
%   updateGlobalBounds(obj) は、現在フェーズの断面規格値と変数対応から
%   全断面リストの上下限を統合して保持する。候補の寸法や有効断面フラグ
%   には依存しないため、構築時とフェーズ設定時に更新する。
%
%   入力引数:
%     obj - SectionConstraintValidatorオブジェクト
%
%   出力引数:
%     なし

obj.lb = obj.getGlobalLowerBounds();
obj.ub = obj.getGlobalUpperBounds();

return
end
