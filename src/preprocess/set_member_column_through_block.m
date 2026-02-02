function [isthrough, idconnected] = ...
  set_member_column_through_block(dbc, com)
%set_member_column_through_block - 通し柱データを読み込み
%   柱端部の接続情報を設定
%
% 「通し柱」データブロックから通し柱の位置を読み込み、
% 該当する柱端部を通し接合としてマークする。
% ブレース分割節点も通し柱位置として扱う。
%
% 入力:
%   dbc: データブロックコントローラ
%   com: 共通データ構造体
%
% 出力:
%   isthrough: 通し接合フラグ [nmec×2] logical
%     列1: 柱脚が通し接合か
%     列2: 柱頭が通し接合か
%   idconnected: 柱の接続関係 [nmec×1]
%     -1: 通し柱チェーンの開始（最下層の柱）
%     正値: 下階で接続する柱のインデックス
%     0: 通し柱でない
%
% データブロック形式（通し柱）:
%   列1: 層名, 列2: X通り, 列3: Y通り
%
% See also: set_member_column_p1_block, set_member_column_p2_block

% データブロックの読み込み
data = dbc.get_data_block('通し柱');
n = size(data,1);

% 共通配列の取得
baseline = com.baseline;
node = com.node;
column_idx = com.member.column.idx;  % 柱のX通り番号 [nmec×2]
column_idy = com.member.column.idy;  % 柱のY通り番号 [nmec×2]
column_idz = com.member.column.idz;  % 柱のZ座標番号 [nmec×2]
nmec = com.nmec;                     % 柱部材数

% 層名・通り名の抽出
story_name = cell(n,1);
coord_name = cell(n,2);
for i=1:n
  story_name{i} = tochar(data{i,1});       % 列1: 層名
  coord_name(i,:) = tochar(data(i,2:3));   % 列2-3: X通り, Y通り
end

% 通り番号への変換
[idx, idy, idz] = find_idxyz_node(story_name, coord_name, baseline);

% ブレース分割節点の追加
% ブレースにより柱が分割される位置も通し柱として扱う
idxb = node.idx(node.type==PRM.NODE_BRACE_FOR_COLUMN);
idyb = node.idy(node.type==PRM.NODE_BRACE_FOR_COLUMN);
idzb = node.idz(node.type==PRM.NODE_BRACE_FOR_COLUMN);
idx = [idx; idxb];
idy = [idy; idyb];
idz = [idz; idzb];
n = length(idx);

% 2パス方式による通し接合の設定
% 入力データの処理順序に依存せず、チェーンを正しく構築する
%
% パス1: 通し接合フラグ(isthrough)のみを設定
% パス2: チェーン最下層から上へ辿ってidconnectedを設定

isthrough = false(nmec,2);    % 通し接合フラグ
idconnected = zeros(nmec,1);  % 接続関係

% パス1: 通し接合フラグの設定
for i=1:n
  for j=1:2
    % 柱端部(j)が通し柱位置(i)と一致する柱を検索
    mask = (column_idx(:,j)==idx(i)) & (column_idy(:,j)==idy(i)) ...
      & (column_idz(:,j)==idz(i));
    id = find(mask);
    if ~isempty(id)
      isthrough(id,j) = true;
    end
  end
end

% パス2: チェーンの構築（チェーン最下層から上へ辿る）
% チェーン最下層: 柱頭が通し接合、柱脚が非通し接合
iddd = 1:nmec;
for ic=1:nmec
  if isthrough(ic,2) && ~isthrough(ic,1)
    % チェーン最下層を発見、上へ辿る
    idcur = ic;
    for iter=1:1000  % 無限ループ防止
      % 上階の柱を検索
      % 条件: 柱脚が現在の柱頭と同じ位置、かつ柱脚が通し接合
      mask = (column_idx(:,1)==column_idx(idcur,2)) & ...
        (column_idy(:,1)==column_idy(idcur,2)) & ...
        (column_idz(:,1)==column_idz(idcur,2)) & ...
        isthrough(:,1);
      idnext = iddd(mask);
      if isempty(idnext)
        % チェーン終端（最上階）
        idconnected(idcur) = -1;
        break;
      else
        % 上階柱への参照を設定
        idconnected(idcur) = idnext(1);
        idcur = idnext(1);
      end
    end
  end
end

return
end

