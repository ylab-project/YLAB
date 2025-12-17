function [brbsec, repbrbs, id] = ...
  findNearestSectionBrb(obj, xvar, idslist, options)
%findNearestSectionBrb BRB断面の最近傍選択
%   [brbsec, repbrbs, id] = findNearestSectionBrb(obj, xvar, idslist,
%     options) は、変数値から最近傍のBRB断面を選択します。
%
%   断面選択アルゴリズム:
%     1. 完全一致チェック: 目標値（V1,V2）と候補断面を比較
%     2. 最近傍選択: ユークリッド距離が最小となる断面を選択
%
%   データ取り扱いルール:
%     - xvar: 設計変数（V1=降伏軸力, V2=サブ番号）
%     - secdimlist: 断面リストデータ
%       - 列1: 製品番号（101400=UB400, 101490=UB490）
%       - 列2: 降伏軸力 [tonf]
%       - 列3: サブ番号（1,2,3等）
%       - 列4: 単位重量 [N/mm]
%     - BRB断面はisvalidチェックを行わない（全断面が有効）
%     - repbrbs, brbsec: 出力（4列全て）
%
%   入力引数:
%     xvar      - 設計変数ベクトル [nxvar×1]
%     idslist   - 断面リストID (スカラー)
%     options   - オプション構造体（BRBでは未使用）
%
%   出力引数:
%     brbsec  - BRB断面寸法 [nbrbs×4]
%     repbrbs - 代表BRB断面 [nrepbrbs×4]
%     id      - ID構造体（.slist, .section）

% 共通定数と配列の取得
nrepbrbs = obj.idMapper_.nrepbrbs;
idbrbs2repbrbs = obj.idMapper_.idbrbs2repbrbs;
idrepbrbs2brbs = obj.idMapper_.idrepbrbs2brbs;

% 代表断面の断面リストIDを取得
idsec2stype = obj.idMapper_.idsec2stype;
idSectionList = obj.idMapper_.idSectionList;
isBrb = (idsec2stype == PRM.BRB);
idbrbs2sec = find(isBrb);
idrepbrbs2sec = idbrbs2sec(idrepbrbs2brbs);
idrepbrbs2slist = idSectionList(idrepbrbs2sec);

% 代表断面の変数IDを取得
idrepbrbs2var = obj.idMapper_.idrepbrbs2var;

% 断面リストの寸法データと有効フラグを取得
secdimlist_all = obj.standardAccessor_.getSectionDimension(idslist);
% BRB断面の処理（注：BRBはisvalidチェックを行わない）
secdimlist = secdimlist_all;  % 全断面をそのまま使用

% 寸法値の事前計算（ループ外で一度だけ）
V1_values = secdimlist(:, PRM.SECLIST_BRB_NY);       % 降伏軸力
V2_values = secdimlist(:, PRM.SECLIST_BRB_SUBTYPE);  % サブ番号

% 計算準備
repbrbs = zeros(nrepbrbs, 4);  % 4列に変更（3-4列目は断面リストデータ）
repbrbs(idrepbrbs2slist==idslist, 1:2) = ...
  xvar(idrepbrbs2var(idrepbrbs2slist==idslist, 1:2));
id.slist = zeros(nrepbrbs, 1);
id.section = zeros(nrepbrbs, 1);

% 断面の検索
for id_ = 1:nrepbrbs
  % 断面と断面リストが対応しないときはスキップ
  if idrepbrbs2slist(id_) ~= idslist
    continue
  end
  
  % 設計変数から目標値を取得
  V1_target = xvar(idrepbrbs2var(id_, 1));
  V2_target = xvar(idrepbrbs2var(id_, 2));
  
  % 完全一致をチェック
  exact_match = (V1_target == V1_values) & ...
                (V2_target == V2_values);
  
  if any(exact_match)
    idx_found = find(exact_match, 1);
  else
    % 最も近い断面を検索（距離の2乗和）
    distances = (V1_values - V1_target).^2 + ...
                (V2_values - V2_target).^2;
    [~, idx_found] = min(distances);
  end
  
  % 結果を保存（4列全てをコピー）
  repbrbs(id_, 1:4) = secdimlist(idx_found, 1:4);
  id.slist(id_) = idslist;
  id.section(id_) = idx_found;
end

% BRB断面の抽出
brbsec = repbrbs(idbrbs2repbrbs, :);
id.slist = id.slist(idbrbs2repbrbs);
id.section = id.section(idbrbs2repbrbs);

return
end