function section_column = set_section_column_rc_block(dbc, com)
%set_section_column_rc_block - RC柱断面データの読み込み
%
%   section_column = set_section_column_rc_block(dbc, com) は、入力
%   データの「RC柱断面」ブロックを読み込み、RC柱の断面情報テーブルを
%   返す。S柱断面と同じテーブル構造を採用する。
%
%   入力引数:
%     dbc - データブロックコンテナ
%     com - 共通オブジェクト (story/baseline/material 等)
%
%   出力引数:
%     section_column - RC柱断面テーブル [n×14]
%       主要列は set_section_column_block と同じ。subindex_raw は
%       出力用の生値（'-' のまま）、subindex は内部参照用（'-' は
%       空文字に置換）。
%
%   備考:
%     - RC柱は最適化対象外のため idvar=0、id_section_list=0 とする。
%     - 入力ブロックが空の場合は空のテーブルを返す。

data = dbc.get_data_block('RC柱断面');
if isempty(data)
  % RC柱断面がない場合は空のテーブルを返す
  section_column = table();
  return;
end

n = size(data,1);

% 階名
floor_name = cell(n,1);
for i=1:n
  floor_name{i} = tochar(data{i,1});
end

% 層番号（S柱断面と同じ方法）
idstory = zeros(n,1);
iddd = 1:com.nstory;
for i=1:n
  idx = strcmp(com.story.floor_name, floor_name{i});
  if any(idx)
    idstory(i) = iddd(idx);
  else
    error('階 %s が見つかりません (RC柱断面)', floor_name{i});
  end
end
idznominal = com.baseline.z.idnominal(idstory);

% 符号
name = cell(n,1);
for i=1:n
  name{i} = tochar(data{i,2});
end

% 添字
%   subindex     : 内部参照（full_name 構築）用。'-' は空文字に置換
%   subindex_raw : 出力用。入力時の生値を保持（'-' のまま）
subindex = cell(n,1);
subindex_raw = cell(n,1);
for i=1:n
  v = data{i,3};
  if isnumeric(v)
    v = num2str(v);
  end
  subindex_raw{i} = v;
  if strcmp(v, '-')
    subindex{i} = '';
  else
    subindex{i} = v;
  end
end

% 断面リスト
full_name = cell(n,1);
idmaterial = zeros(n,1);
id_section_list = zeros(n,1);  % 最適化対象外
type = zeros(n,1);
type_name = cell(n,1);
iddd = 1:com.nma;
for i=1:n
  full_name{i} = [subindex{i} name{i}];
  idmaterial(i) = iddd(matches(com.material.name, data{i,7}));
  type(i) = PRM.RCRS;  % RC矩形断面
  type_name{i} = 'RCRS';
end

% 設計変数番号（最適化対象外のため0）
mvar = PRM.MAX_NSVAR;
idvar = zeros(n,mvar);

% 寸法指定
dimension = zeros(n,mvar);
for i=1:n
  % Dx×Dy（形状は□なので正方形または矩形）
  dimension(i,1:2) = [data{i,5} data{i,6}];
  % 荷重剛性用Dx×Dy
  dimension(i,3:4) = dimension(i,1:2);
  if isnumeric(data{i,8}) && ~ismissing(data{i,8}) && data{i,8}>0
    dimension(i,3) = data{i,8};
  end
  if isnumeric(data{i,9}) && ~ismissing(data{i,9}) && data{i,9}>0
    dimension(i,4) = data{i,9};
  end
end

% 部材種別（RC柱はランク対象外）
rank = PRM.RANK_NONE * ones(n, 1);

% 結果の保存（S柱断面と同じテーブル構造）
section_column = table(name, subindex, subindex_raw, full_name, ...
  floor_name, id_section_list, type_name, idstory, type, idmaterial, ...
  idznominal, idvar, rank, dimension);

return
end
