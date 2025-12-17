function [isthrough, idconnected] = ...
  set_member_girder_through_kbrace_block(com)
%set_member_girder_through_kbrace_block - Kブレース分割梁の通し情報を作成
%
% Kブレースによって生成された梁分割（KBRACE1/2）を探索し、
% 通し梁フラグと接続先情報を算出する。
%
% 入力:
%   com: 共通データ構造体（member.girder/type/nodeを含む）
%
% 出力:
%   isthrough: 通し接合フラグ [nmeg×3] logical
%     列1: 左端（i端）が通し接合か
%     列2: 右端（j端）が通し接合か
%     列3: 中央部が通しか（列1または列2がtrue）
%   idconnected: 梁の接続関係 [nmeg×1]
%     正値: 右側で接続する梁（KBRACE2）のインデックス
%     0: Kブレース分割梁でない
%
% See also: set_member_girder_through_block, set_member_brace_block

% 出力配列の初期化
nmeg = com.nmeg;
isthrough = false(nmeg,3);
idconnected = zeros(nmeg,1);

% 共通配列の取得
node = com.node;
member_girder = com.member.girder;

% Kブレース分割で追加された中間節点を検索
idnode_brace = find(node.type == PRM.NODE_BRACE_FOR_GIRDER);
if isempty(idnode_brace)
  return
end

% 中間節点ごとに左右の分割梁ペアを探索
nb = numel(idnode_brace);
for ib = 1:nb
  idnode = idnode_brace(ib);

  % KBRACE1（左側梁）: 右端(idnode2)が中間節点に接続
  ig1 = find(...
    member_girder.type == PRM.GIRDER_FOR_KBRACE1 ...
    & member_girder.idnode2 == idnode, 1);

  % KBRACE2（右側梁）: 左端(idnode1)が中間節点に接続
  ig2 = find(...
    member_girder.type == PRM.GIRDER_FOR_KBRACE2 ...
    & member_girder.idnode1 == idnode, 1);

  % ペアが見つからない場合はスキップ
  if isempty(ig1) || isempty(ig2)
    continue
  end

  % 通し接合フラグを設定
  % ig1（左側梁）: 右端と中央を通しとしてマーク
  % ig2（右側梁）: 左端と中央を通しとしてマーク
  isthrough(ig1,[2 3]) = true;
  isthrough(ig2,[1 3]) = true;

  % 接続関係を記録（左側梁→右側梁）
  idconnected(ig1) = ig2;
end

return
end
