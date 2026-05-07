function section_girder = set_section_rc_girder_block(dbc, com)
%set_section_rc_girder_block - RC梁断面ブロックの読み込み
%
%   section_girder = set_section_rc_girder_block(dbc, com) は、入力
%   データの「RC梁断面」ブロックを読み込み、RC梁の断面情報テーブルを
%   返す。S梁断面と同じテーブル構造を採用する。
%
%   入力引数:
%     dbc - データブロックコンテナ
%     com - 共通オブジェクト
%
%   出力引数:
%     section_girder - RC梁断面テーブル [n×15]
%       主要列: name, subindex, subindex_raw, story_name, full_name,
%       id_section_list, type_name, idstory, type, idmaterial, idz,
%       idznominal, idvar, dimension, rank
%
%   備考:
%     - RC梁は最適化対象外のため idvar=0。
%     - subindex_raw は出力用の生値、subindex は内部参照用
%       （'-' は層番号に置換）。

data = dbc.get_data_block('RC梁断面');
n = size(data,1);

% 層名
story_name = cell(n,1);
for i=1:n
  story_name{i} = tochar(data{i,1});
end

% 層・Z通り番号
idstory = zeros(n,1); idds = 1:com.nstory;
idz = zeros(n,1); iddz = com.story.idz;
for i=1:n
  idstory(i) = idds(matches(com.story.name, story_name{i}));
  idz(i) = iddz(matches(com.story.name, story_name{i}));
end
idznominal = com.baseline.z.idnominal(idz);

% 符号
name = cell(n,1);
for i=1:n
  name{i} = tochar(data{i,2});
end

% 添字
%   subindex     : 内部参照（full_name 構築）用。'-' は層番号に置換
%   subindex_raw : 出力用。入力時の生値を保持（'-' のまま）
subindex = cell(n,1);
subindex_raw = cell(n,1);
for i=1:n
  [subindex{i}, subindex_raw{i}] = make_subindex(data{i,3}, idstory(i));
end

% 断面リスト
full_name = cell(n,1);
idmaterial = zeros(n,1);
id_section_list = zeros(n,1);
type = zeros(n,1);
type_name = cell(n,1);
iddd = 1:com.nma;
for i=1:n
  full_name{i} = [subindex{i} name{i}];
  idmaterial(i) = iddd(matches(com.material.name, data{i,6}));
  type(i) = PRM.RCRS;
end

% 設計変数番号
mvar = PRM.MAX_NSVAR;
idvar = zeros(n,mvar);

% 寸法指定
dimension = zeros(n,mvar);
for i=1:n
  % b×D(1:2)
  dimension(i,1:2) = [data{i,4} data{i,5}];
  % 荷重剛性用b×D(3:4)
  dimension(i,3:4) = dimension(i,1:2);
  if data{i,7}>0
    dimension(i,3) = data{i,7};
  end
  if data{i,8}>0
    dimension(i,4) = data{i,8};
  end
end

% 部材種別
rank = zeros(n,1);

% 結果の保存
section_girder = table(name, subindex, subindex_raw, story_name, ...
  full_name, id_section_list, type_name, idstory, type, idmaterial, ...
  idz, idznominal, idvar, dimension, rank);
return
end
