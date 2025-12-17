function [isthrough, idconnected] = ...
  set_member_girder_through_block(dbc, com)
%set_member_girder_through_block - 通し梁データを読み込み梁端部の接続情報を設定
%
% 「通し梁」データブロックから通し梁の位置を読み込み、
% 該当する梁端部を通し接合としてマークする。
%
% 入力:
%   dbc: データブロックコントローラ
%   com: 共通データ構造体
%
% 出力:
%   isthrough: 通し接合フラグ [nmeg×3] logical
%     列1: 左端（i端）が通し接合か
%     列2: 右端（j端）が通し接合か
%     列3: 中央部が通しか（列1または列2がtrue）
%   idconnected: 梁の接続関係 [nmeg×1]
%     正値: 左側で接続する梁のインデックス
%     0: 通し梁でない
%
% データブロック形式（通し梁）:
%   列1: 階名, 列2: X通り, 列3: Y通り, 列4: 架構名
%
% See also: set_member_girder_p1_block, set_member_column_through_block

% データブロックの読み込み
data = dbc.get_data_block('通し梁');
n = size(data,1);

% 共通配列の取得
baseline = com.baseline;
girder_idx = com.member.girder.idx;    % 梁のX通り番号 [nmeg×2]
girder_idy = com.member.girder.idy;    % 梁のY通り番号 [nmeg×2]
girder_idz = com.member.girder.idz;    % 梁のZ座標番号 [nmeg×2]
girder_idir = com.member.girder.idir;  % 梁の方向（X/Y）
nmeg = com.nmeg;                       % 梁部材数

% 階名・通り名・架構名の抽出
story_name = cell(n,1);
coord_name = cell(n,2);
frame_name = cell(n,1);
for i=1:n
  story_name{i} = tochar(data{i,1});       % 列1: 階名
  coord_name(i,:) = tochar(data(i,2:3));   % 列2-3: X通り, Y通り
  frame_name{i} = tochar(data{i,4});       % 列4: 架構名（方向決定用）
end

% 通り番号・方向への変換
[idx, idy, idz, idir] = find_idxyz_node(...
  story_name, coord_name, baseline, frame_name);

% 通し接合の検索
% 各通し梁位置について、左端(j=1)と右端(j=2)が一致する梁を探す
isthrough = false(nmeg,3);    % 通し接合フラグ [左端, 右端, 中央]
idconnected = zeros(nmeg,1);  % 接続関係
iddd = 1:nmeg;                % 梁インデックス
for i=1:n
  idg = zeros(1,2);           % 一致した梁ID [左端側, 右端側]
  for j=1:2
    % 梁端部(j)が通し梁位置(i)と一致し、かつ方向も一致する梁を検索
    id = iddd(girder_idx(:,j) == idx(i) ...
      & girder_idy(:,j) == idy(i) ...
      & girder_idz(:,j) == idz(i) ...
      & girder_idir == idir(i));
    if ~isempty(id)
      idg(j) = id;
      isthrough(id,j) = true;  % 該当端を通しとしてマーク
      isthrough(id,3) = true;  % 中央部も通しとしてマーク
    end
  end
  % 同じ位置で左端と右端が見つかった場合、接続関係を設定
  % idg(1): 右側の梁（この位置が左端）
  % idg(2): 左側の梁（この位置が右端）
  if all(idg>0)
    idconnected(idg(2)) = idg(1);  % 左側梁から右側梁への参照
  end
end

return
end
