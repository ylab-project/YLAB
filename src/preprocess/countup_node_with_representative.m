function [idnode1, idnode2] = countup_node_with_representative(com)
%countup_node_with_representative - 部材の節点番号を代表節点に置換
%
%   [idnode1, idnode2] = countup_node_with_representative(com) は、
%   節点同一化により柱が存在しない端部でも正しくフェイス位置等を
%   計算するため、部材の節点番号を代表節点番号に置換した配列を返す。
%
%   入力引数:
%     com - 共通オブジェクト（node.idrep, member.property等を含む）
%
%   出力引数:
%     idnode1 - 代表節点に置換後の節点1番号 [nmember×1]
%     idnode2 - 代表節点に置換後の節点2番号 [nmember×1]
%
%   備考:
%     - node.idrep(in) > 0 の場合、節点inは代表節点idrep(in)に同一化されている
%     - この関数はparse_frame_data.mの冒頭で呼び出すことを想定
%     - read_frame_data.m完了後に呼び出す必要がある（idrep設定済み前提）

% 代表節点情報の取得
idrep = com.node.idrep;

% 部材の節点番号を取得
idnode1 = com.member.property.idnode1;
idnode2 = com.member.property.idnode2;

% 代表節点への置換マスク
mask1 = idrep(idnode1) > 0;
mask2 = idrep(idnode2) > 0;

% 節点番号を代表節点に置換
idnode1(mask1) = idrep(idnode1(mask1));
idnode2(mask2) = idrep(idnode2(mask2));

return
end
