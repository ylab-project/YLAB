function [section_column, design_variable] = ...
  set_section_column_block(dbc, com, options)
%set_section_column_block - S柱断面ブロックの読み込み
%
%   [section_column, design_variable] = ...
%     set_section_column_block(dbc, com, options) は、入力データの
%   「S柱断面」ブロックを読み込み、S柱の断面情報テーブルと更新後の
%   設計変数構造体を返す。
%
%   入力引数:
%     dbc     - データブロックコンテナ
%     com     - 共通オブジェクト (story/baseline/sectionList 等)
%     options - 実行オプション (coptions.rank_column 等)
%
%   出力引数:
%     section_column  - S柱断面テーブル [n×14]
%       主要列: name, subindex, subindex_raw, full_name, floor_name,
%       id_section_list, type_name, idstory, type, idmaterial,
%       idznominal, idvar, rank, dimension
%     design_variable - 更新された設計変数構造体
%
%   備考:
%     - subindex は内部参照用、subindex_raw は出力用の生値（S梁との
%       対称化のため両方を保持）。
%     - 部材種別（ランク）は列9を正とし、空の場合のみ列7を互換
%       フォールバックとして参照する（次期バージョンで廃止予定）。

data = dbc.get_data_block('S柱断面');
n = size(data,1);
design_variable = com.design.variable;

% 階名
floor_name = cell(n,1);
for i=1:n
  if ~ischar(data{i,1})
    val = tochar(data{i,1});
  else
    val = data{i,1};
  end
  floor_name{i} = tochar(val);
end

% 層番号
idstory = zeros(n,1); iddd = 1:com.nstory;
for i=1:n
  idstory(i) = iddd(matches(com.story.floor_name, floor_name{i}));
end
idznominal = com.baseline.z.idnominal(idstory);

% 符号
name = cell(n,1);
for i=1:n
  name{i} = tochar(data{i,2});
end

% 添字
%   subindex     : 内部参照（full_name 構築）用
%   subindex_raw : 出力用。S梁との対称化のため生値を保持
subindex = cell(n,1);
subindex_raw = cell(n,1);
for i=1:n
  v = data{i,3};
  if isnumeric(v)
    v = num2str(v);
  end
  subindex_raw{i} = v;
  subindex{i} = v;
end

% 断面リスト
section_list_name = cell(n,1);
full_name = cell(n,1);
id_section_list = zeros(n,1); iddd = 1:com.nsectionList;
idmaterial = zeros(n,1);
type = zeros(n,1);
type_name = cell(n,1);
for i=1:n
  full_name{i} = [subindex{i} name{i}];
  section_list_name{i} = tochar(data{i,4});
  idx = strcmp(com.sectionList.name, section_list_name{i});
  if any(idx)
    idsl = iddd(idx);
    id_section_list(i) = idsl(1);
  else
    throw_err('IO', 'SectionListNotFound', section_list_name{i}, ...
      'S柱断面', ['符号: ' full_name{i}]);
  end

  % 同一の鉄骨形状のみ複数リスト指定可
  type_ = unique(com.sectionList.section_type(idsl));
  if length(type_)~=1
    error('同一断面リストに対する鉄骨形状は同一としてください')
  end
  type(i) = com.sectionList.section_type(idsl(1));
  type_name(i) = com.sectionList.section_type_name(idsl(1));
end

% 設計変数番号
mvar = PRM.MAX_NSVAR;
variable = cell(n,mvar);
idvar = zeros(n,mvar);
iddd = 1:PRM.MAX_NVAR;
nvar = com.nvar;
nvrows = sum(~isnan(design_variable.isvar));
for i=1:n
  ndvar = PRM.nvar_of_section_type(type(i));
  cdata = data(i,5:(4+ndvar));
  variable(i,1:ndvar) = tochar(cdata);
  for j=1:ndvar
    idvar_ = iddd(matches(design_variable.name, variable{i,j}));
    if isempty(idvar_)
      % 変数追加
      nvrows = nvrows+1;
      nvar = nvar+1;
      design_variable.name{nvrows} = variable{i,j};
      design_variable.isvar(nvrows) = true;
      design_variable.idvar(nvrows) = nvar;
      idvar_ = nvar;
    end
    idvar(i,j) = idvar_(1);
  end
end

% 寸法指定（断面リストから取得するためゼロで初期化）
dimension = zeros(n,mvar);

% 部材種別（列9を正とし、空なら列7を互換フォールバック）
% 旧仕様は列7指定。当面許容するが次期バージョンで廃止予定
icol_rank_new = 9;
icol_rank_old = 7;
rank = options.coptions.rank_column * ones(n, 1);
warned_old = false;
ncol = size(data, 2);
for i = 1:n
  raw = '';
  if ncol >= icol_rank_new && ~all(ismissing(data{i, icol_rank_new}))
    raw = tochar(data{i, icol_rank_new});
  elseif ncol >= icol_rank_old && ~all(ismissing(data{i, icol_rank_old}))
    cand = tochar(data{i, icol_rank_old});
    % ランク名として解釈できる場合のみ旧仕様として採用
    % WFSの列7=twは数値のため完全一致で誤検出しない
    if any(strcmp(PRM.MEMBER_RANK_NAME, cand))
      raw = cand;
      if ~warned_old
        throw_warn('Input', 'DeprecatedColumnRankColumn');
        warned_old = true;
      end
    end
  end
  if ~isempty(raw)
    idx = find(strcmp(PRM.MEMBER_RANK_NAME, raw), 1);
    if ~isempty(idx), rank(i) = idx; end
  end
end

% 結果の保存
section_column = table(name, subindex, subindex_raw, full_name, ...
  floor_name, id_section_list, type_name, idstory, type, idmaterial, ...
  idznominal, idvar, rank, dimension);

return
end
