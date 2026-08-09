function member_column = set_member_column_p2_block(~, com, ~)
%set_member_column_p2_block - 柱部材に断面・節点・変数番号を設定(P2)
%
%   member_column = set_member_column_p2_block(~, com, ~) は、
%   P1ブロックで作成された柱部材テーブルに対し、断面マッチングと
%   節点番号の割り当てを行います。無効な節点を持つ柱は削除されます。
%
%   入力引数:
%     第1引数 - 未使用（呼び出し側互換のため）
%     com     - 共通データ構造体（member.column, section.column,
%               story.idnominal, node, nsecc を参照）
%     第3引数 - 未使用（呼び出し側互換のため）
%
%   出力引数:
%     member_column - 柱部材テーブル。以下のフィールドを追加・更新:
%                       .idsecc  - 断面番号
%                       .idnode1 - 柱脚節点番号
%                       .idnode2 - 柱頭節点番号
%                       .idvar   - 変数番号 [n×MAX_NSVAR]
%                       .cz_std  - 通り心ベース方向余弦Z成分
%                                  （斜め柱の投影補正用）
%
%   参考:
%     set_member_column_p1_block, find_idnode_from_idxyz

% 共通配列の取得
member_column  = com.member.column;   % P1で作成された柱部材テーブル
% 柱断面テーブル（ループ内のtable参照を避けるため構造体化）
section_column = table2struct(com.section.column, 'ToScalar', true);
idz2zn = com.story.idnominal;         % 柱配置階→通常階の対応表
n = size(member_column,1);            % 柱部材数

% 断面番号の設定
section_name = member_column.section_name;
idstory = member_column.idstory;
idzn = idz2zn(idstory);
idsecc = zeros(n,1);
for i=1:n
  idsecc(i) = select_section_id(section_column, section_name{i}, ...
    idstory(i), idzn(i));
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
% 節点が見つからない(=0)柱は、接続する他の柱から節点を継承するか削除する
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

% 通り心ベース方向余弦のZ成分（斜め柱の投影補正用）
cz_std = calc_column_standard_cosine_z(idnode1, idnode2, node);

% 結果をテーブルに格納し、無効な柱を除去
member_column.idsecc = idsecc;
member_column.idnode1 = idnode1;
member_column.idnode2 = idnode2;
member_column.idvar = idvar;
member_column.cz_std = cz_std;
member_column = member_column(~isremoved,:);

return
end
