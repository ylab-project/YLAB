function member_column = set_member_column_p2_block(dbc, com, isdummy_node)
%set_member_column_p2_block - 柱部材に断面番号・節点番号・変数番号を設定
%   （P2ブロック処理）
%
% P1ブロックで作成された柱部材テーブルに対し、断面マッチングと
% 節点番号の割り当てを行う。無効な節点を持つ柱は削除される。
%
% 入力:
%   dbc: データブロックコントローラ（インターフェース互換用）
%   com: 共通データ構造体
%   isdummy_node: ダミー節点フラグ（インターフェース互換用）
%
% 出力:
%   member_column: 柱部材テーブル
%     .idsecc  - 断面番号
%     .idnode1 - 柱脚節点番号
%     .idnode2 - 柱頭節点番号
%     .idvar   - 変数番号 [n×MAX_NSVAR]
%
% See also: set_member_column_p1_block, find_idnode_from_idxyz

% 共通配列の取得
member_column  = com.member.column;   % P1で作成された柱部材テーブル
section_column = com.section.column;  % 柱断面テーブル
idz2zn = com.story.idnominal;         % 層番号→公称層番号の変換表
n = size(member_column,1);            % 柱部材数

% 断面番号の設定
% 各柱部材に対応する断面を、断面名と公称層番号で照合して特定する
section_name = member_column.section_name;
idstory = member_column.idstory;
idsecc = zeros(n,1);            % 断面番号の格納先
isvalid = 1:com.nsecc;          % 有効な断面インデックス
idzn = idz2zn(idstory);         % 柱の公称層番号
idz = member_column.idz;        % 柱のZ座標範囲 [下端, 上端]
for i=1:n
  % 断面名(name列)と公称層番号で照合
  idx_name = strcmp(section_column.name, section_name{i}) ...
    & section_column.idznominal==idzn(i);

  % name列で見つからない場合、full_name列でも照合を試みる
  if ~any(idx_name)
    idx_name = strcmp(section_column.full_name, section_name{i});
  end

  if any(idx_name)
    id = isvalid(idx_name);
    if isscalar(id)
      % 一意に特定できた場合
      idsecc(i) = id(1);
    else
      % 複数候補がある場合、柱の配置範囲内の断面に絞り込む
      candidate_stories = section_column.idstory(id);
      z_bottom = idz(i,1) + 1;  % 柱脚の層番号
      z_top = idz(i,2);         % 柱頭の層番号
      in_range = (candidate_stories >= z_bottom) & ...
        (candidate_stories <= z_top);
      valid_candidates = id(in_range);
      if isscalar(valid_candidates)
        idsecc(i) = valid_candidates(1);
      elseif isempty(valid_candidates)
        error('柱断面 %s が配置範囲内に見つかりません (階: %s)', ...
          section_name{i}, member_column.floor_name{i});
      else
        error('柱断面 %s が配置範囲内に複数見つかりました (階: %s)', ...
          section_name{i}, member_column.floor_name{i});
      end
    end
  else
    error('柱断面 %s が見つかりません (階: %s)', ...
      section_name{i}, member_column.floor_name{i});
  end
end

% 節点番号の設定
% 柱の両端(柱脚・柱頭)の座標から対応する節点番号を検索
node = com.node;
idx = member_column.idx;      % X通り番号 [n×2]
idy = member_column.idy;      % Y通り番号 [n×2]
idz = member_column.idz;      % Z座標番号 [n×2]（下端, 上端）
idfloor = member_column.idfloor;
% 柱脚
idnode1 = find_idnode_from_idxyz(idx(:,1), idy(:,1), idz(:,1), node);  
% 柱頭
idnode2 = find_idnode_from_idxyz(idx(:,2), idy(:,2), idz(:,2), node);  

% ダミー節点の処理
% 節点が見つからない(=0)柱に対し、接続する他の柱から節点を継承するか削除する
iddd = 1:n;                   % 部材インデックス
isremoved = false(n,1);       % 削除フラグ
for i=1:n
  if idnode1(i)==0
    % 柱脚節点が無効の場合、同じ位置を柱頭に持つ下階の柱を探す
    id = iddd(idx(i,1) == idx(:,2) & idy(i,1) == idy(:,2) ...
      & idz(i,1) == idz(:,2));

    if isempty(id)
      % 下階の柱が見つからない場合は削除対象
      isremoved(i) = true;
    else
      % 下階の柱から節点情報を継承
      if length(id) > 1
        id = id(1);
      end
      idnode1(i) = idnode1(id);
      member_column.idx(i,1) = idx(id,1);
      member_column.idy(i,1) = idy(id,1);
      member_column.idz(i,1) = idz(id,1);
      member_column.idfloor(i) = idfloor(id);
    end
  end
  if idnode2(i)==0
    % 柱頭節点が無効の場合は削除対象
    isremoved(i) = true;
  end
end

% 変数番号の設定
% 各柱部材に対応する断面の設計変数番号を割り当てる
mvar = PRM.MAX_NSVAR;         % 最大変数数
idvar = zeros(n,mvar);
for i=1:n
  idvar(i,:) = section_column.idvar(idsecc(i),:);
end

% 結果をテーブルに格納し、無効な柱を除去
member_column.idsecc = idsecc;
member_column.idnode1 = idnode1;
member_column.idnode2 = idnode2;
member_column.idvar = idvar;
member_column = member_column(~isremoved,:);

return
end
