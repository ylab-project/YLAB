function vtype = lookupVariableType(obj, idvar)
%lookupVariableType 変数IDから変数タイプを参照
%   vtype = lookupVariableType(obj, idvar) は、変数IDに対応する
%   変数タイプを参照します。
%
%   入力引数:
%     idvar - 変数ID (スカラーまたは配列)
%
%   出力引数:
%     vtype - 変数タイプ (入力と同じサイズ)
%
%   例:
%     vtype = mapper.lookupVariableType(5);
%     vtype = mapper.lookupVariableType([1 3 5]);
%
%   参考:
%     IdMapper

if isempty(idvar)
  vtype = [];
  return;
end

% 範囲チェック
valid_mask = idvar > 0 & idvar <= obj.nxvar;
vtype = zeros(size(idvar));

if any(valid_mask)
  vtype(valid_mask) = obj.idvar2vtype_(idvar(valid_mask));
end

return
end