classdef data_block_class < handle
  %data_block_class - 入力 CSV をブロック単位に分類するクラス
  %
  %   CSV を読み込み、name= 行と <data> 行でデータブロックに分割し、
  %   ラベル指定でのブロック取得と行位置付きエラー通知を提供する。
  %
  %   ブロック番号は2系統あり、ラベル番号 (bcdata、labels の添字)
  %   は同名ブロックを合算し、ブロック通し番号 (blockdata、name=
  %   行の出現順) は同名ブロックを区別する。get_data_block は前者、
  %   get_data_blocks は後者の単位で取得する。
  %
  %   data_block_class プロパティ:
  %     labels        - 有効なブロックラベル一覧
  %     modelname     - 「モデル名」行の値 (なければ '')
  %     comment       - 「説明」行の値 (なければ {''})
  %     cdata         - スキップ行除去後の全セルデータ
  %     bcdata        - 各行のラベル番号 (labels の添字、0:登録ブロック外)
  %     casedata      - 各行のケースラベル
  %     origrows      - 各行の元 CSV 行番号
  %     blockdata     - 各行のブロック通し番号 (name= 行の出現順)
  %     blocklabels   - ブロック通し番号順のラベル一覧
  %     blockheaders  - ブロック通し番号順の name= 行 (ヘッダ行)
  %     blockorigrows - ブロック通し番号順の name= 行の元 CSV 行番号
  %     checkLabel    - 未登録ラベルをエラーにするか
  %     modeSS7       - SS7 連携モード。true では name= 行の後、
  %                     <data> 行が来るまでデータ行と見なさない
  %
  %   data_block_class メソッド:
  %     readCsvFile         - CSV を読み込みブロックに分類
  %     get_num_data_lines  - 指定ラベルのデータ行数
  %     get_data_block      - 指定ラベルのデータブロック取得
  %     get_data_blocks     - 同名ブロックを属性・元 CSV 行番号付きで取得
  %     get_data_block_rows - ブロック内各行の cdata 行番号
  %     throw_dat_err       - ブロック内行位置付きエラー
  %     bid                 - 'name=<ラベル>' に対応するラベル番号
  properties
    labels(1,:) cell
    modelname(1,:) char
    comment(:,1) cell
    cdata(:,:) cell
    bcdata(:,1) double
    casedata(:,1) cell
    origrows(:,1) double
    blockdata(:,1) double
    blocklabels(:,1) cell
    blockheaders(:,1) cell
    blockorigrows(:,1) double
    checkLabel(1,1) logical = true
    modeSS7(1,1) logical = false
  end
  methods
    function obj = data_block_class
      %data_block_class - 空のインスタンスを生成するコンストラクタ
      %
      %   obj = data_block_class は、プロパティが既定値のままの空の
      %   インスタンスを返す。
      %
      %   出力引数:
      %     obj - data_block_class インスタンス
    end
    function readCsvFile(obj, input, labels)
      %readCsvFile - CSV を読み込みブロック単位に分類する
      %
      %   obj.readCsvFile(input, labels) は、input の CSV を空行・
      %   コメント行・全カンマ行を除いて読み込み、name= 行と <data>
      %   行でブロックに分割し、各行のラベル番号 (bcdata)・ブロック
      %   通し番号 (blockdata)・ケースラベル (casedata)・元 CSV 行番号
      %   (origrows) を保持する。
      %
      %   入力引数:
      %     input  - CSV ファイルパス
      %     labels - 有効なブロックラベル一覧 (cell)

      % readlines ベースでスキップ対象行を判定
      % - スキップ対象は空行・コメント行・全カンマ行
      % - readcell の出力はコメント行が詰められ、元 CSV 行番号も
      %   持たないので、この段階で元 CSV 行番号を確定する
      stripped = strtrim(readlines(input));

      % 末尾空行を 1 つ削って readcell と行数を整合させる
      % - readcell は常にファイル末尾の改行 1 つを trim する
      % - readlines は末尾改行で空行を 1 つ多く生成する
      if ~isempty(stripped) && strlength(stripped(end)) == 0
        stripped(end) = [];
      end

      % readcell からドロップされる行の判定
      % - ドロップは CommentStyle='%' の先頭%行のみ (空行・全カンマ
      %   行は下記 EmptyLineRule='read' で保持)
      % - クォート付き %行を誤判定しないよう、クォート除去前の
      %   stripped で判定する
      is_dropped_by_readcell = startsWith(stripped, '%');

      % 先頭クォート除去後に %始まりの行も is_skip に含める意図的設計。
      % SS7 連携入力 CSV が装飾セクション区切りに使うクォート付%行
      % ("% ====== ..." 等) を装飾コメントとしてスキップするため
      has_quote = startsWith(stripped, '"');
      stripped(has_quote) = extractAfter(stripped(has_quote), 1);
      no_comma = strtrim(replace(stripped, ',', ''));
      is_skip = (strlength(no_comma) == 0) | startsWith(no_comma, '%');
      obj.origrows = find(~is_skip);

      % readcell によるセル配列の作成
      opts = detectImportOptions(input);
      opts.Delimiter = {','};
      opts.DataLines = [1,inf];
      opts.CommentStyle = '%';

      % EmptyLineRule='read' を明示し、全 missing 行を保持して
      % is_skip で後段除去する。default の skip は CSV 規模・列数
      % 推定によって全カンマ行の trim 可否が変わり、readcell 行数と
      % origrows の対応が不安定になるため
      opts.EmptyLineRule = 'read';
      obj.cdata = readcell(input, opts);

      % readcell 出力を readlines の元行に対応付け、is_skip で再フィルタ
      % して obj.cdata と obj.origrows を一致させる
      map_cdata_to_lines = find(~is_dropped_by_readcell);
      assert(length(map_cdata_to_lines) == size(obj.cdata,1), ...
        'readcell 出力行数と readlines の対応が取れません (%d vs %d)', ...
        length(map_cdata_to_lines), size(obj.cdata,1));
      obj.cdata(is_skip(map_cdata_to_lines),:) = [];
      obj.labels = labels;

      assert(length(obj.origrows) == size(obj.cdata,1), ...
        'origrows と cdata の行数が一致しません (%d vs %d)', ...
        length(obj.origrows), size(obj.cdata,1));

      % モデル名・説明の取得。任意入力のため、該当行や値が取得でき
      % ない場合は catch で既定値へ落とす
      try
        istarget = matches(obj.cdata(:,1), 'モデル名');
        obj.modelname = obj.cdata{find(istarget, 1, 'last'), 2};
      catch
        obj.modelname = '';
      end
      try
        istarget = matches(obj.cdata(:,1), '説明');
        obj.comment = obj.cdata(istarget, 2);
      catch
        obj.comment = {''};
      end

      % ブロック分類ループ
      % - name= 行をブロックとして登録する
      % - 各データ行へラベル番号・ケース・ブロック通し番号を割り当てる
      % - checkLabel 時は未登録の name= をエラーにする
      nlines = size(obj.cdata, 1);
      obj.bcdata = zeros(nlines, 1);
      obj.casedata = cell(nlines, 1);
      obj.blockdata = zeros(nlines, 1);
      obj.blocklabels = cell(0, 1);
      obj.blockheaders = cell(0, 1);
      obj.blockorigrows = zeros(0, 1);
      bid = 0;
      block_id = 0;
      caselabel = [];
      isdata = true;
      for iline = 1:nlines
        isheader = false;
        first_value = obj.cdata{iline, 1};
        if ischar(first_value)
          if startsWith(first_value, 'name=')
            isheader = true;
            bid = 0;
            block_id = block_id + 1;
            obj.blocklabels{block_id, 1} = extractAfter(first_value, 5);
            obj.blockheaders{block_id, 1} = obj.cdata(iline, :);
            obj.blockorigrows(block_id, 1) = obj.origrows(iline);
            caselabel = read_legacy_case_label(obj.cdata(iline, :));
            if obj.modeSS7
              % SS7 連携 CSV は name= 行と <data> 行の間に項目行・
              % 単位行が挟まるため、<data> 行までデータ行と見なさない
              isdata = false;
            end
          elseif contains(first_value, '<data>')
            isheader = true;
            isdata = true;
          end
          block_bid = obj.bid(first_value);
          if block_bid > 0
            bid = block_bid;
          elseif isheader && obj.checkLabel
            if startsWith(first_value, 'name=')
              error('(%d) "%s" は登録されたキーワードではありません', ...
                iline, first_value);
            end
          end
        end
        if ~isheader && isdata
          obj.bcdata(iline) = bid;
          obj.casedata{iline} = caselabel;
          obj.blockdata(iline) = block_id;
        end
      end
    end
    function num = get_num_data_lines(obj, label)
      %get_num_data_lines - 指定ラベルのデータ行数を返す
      %
      %   num = obj.get_num_data_lines(label) は、label のブロックに
      %   属するデータ行数を返す。
      %
      %   入力引数:
      %     label - ブロックラベル
      %
      %   出力引数:
      %     num - データ行数
      bid = obj.bid(['name=' label]);
      num = sum(+(obj.bcdata==bid));
    end
    function cdata = get_data_block(obj, label, caselabel)
      %get_data_block - 指定ラベルのデータブロックを取得
      %
      %   cdata = obj.get_data_block(label) は、label のブロックの
      %   データ行を抽出し、ブロック定義に従って正規化して返す。
      %   caselabel を指定すると、前方一致するケースに限定して返す。
      %
      %   入力引数:
      %     label     - ブロックラベル
      %     caselabel - ケースラベル前方一致フィルタ (任意)
      %
      %   出力引数:
      %     cdata - 該当行を抽出し正規化したセル配列
      bid = obj.bid(['name=' label]);
      switch nargin
        case 2
          cdata = obj.cdata(obj.bcdata==bid,:);
        case 3
          cdata = obj.cdata(obj.bcdata==bid & strncmp(caselabel, ...
            obj.casedata, length(caselabel)),:);
      end
      cdata = obj.normalize_data_block(label, cdata);
    end
    function blocks = get_data_blocks(obj, label)
      %get_data_blocks - 同名ブロックを属性と元CSV行付きで取得する
      %
      %   blocks = obj.get_data_blocks(label) は、label と同名の全
      %   ブロックを name= 行の出現順に返す。データ行はブロック定義
      %   に従って正規化する。
      %
      %   入力引数:
      %     label - ブロックラベル
      %
      %   出力引数:
      %     blocks - 同名ブロックごとの構造体配列。フィールドは data
      %              (正規化済みデータ行)、rows (cdata 行番号)、origrows
      %              (元 CSV 行番号)、attributes (ヘッダ属性)、header
      %              (name= 行)、header_origrow (name= 行の元 CSV 行番号)
      empty_block = struct('data', {}, 'rows', {}, 'origrows', {}, ...
        'attributes', {}, 'header', {}, 'header_origrow', {});
      blocks = empty_block;
      if isempty(obj.blocklabels)
        return
      end

      block_ids = find(strcmp(obj.blocklabels, label));
      bid = obj.bid(['name=' label]);
      for index = 1:length(block_ids)
        block_id = block_ids(index);
        rows = find(obj.blockdata == block_id & obj.bcdata == bid);
        block.data = obj.normalize_data_block(label, obj.cdata(rows, :));
        block.rows = rows;
        block.origrows = obj.origrows(rows);
        block.header = obj.blockheaders{block_id};
        block.attributes = parse_block_attributes(block.header);
        block.header_origrow = obj.blockorigrows(block_id);
        blocks(end + 1, 1) = block; %#ok<AGROW>
      end

      return
    end
    function rows = get_data_block_rows(obj, label)
      %get_data_block_rows - ブロック内各行の cdata 行番号を返す
      %
      %   rows = obj.get_data_block_rows(label) は、label のブロック
      %   に属する行の cdata 行番号を返す。throw_dat_err での元 CSV
      %   行番号解決に使用する。
      %
      %   入力引数:
      %     label - ブロックラベル
      %
      %   出力引数:
      %     rows - cdata 上の行番号ベクトル
      bid = obj.bid(['name=' label]);
      rows = find(obj.bcdata == bid);
    end
    function throw_dat_err(obj, label, block_row, cat, id, varargin)
      %throw_dat_err - ブロック内行位置付きのエラーを発生
      %
      %   obj.throw_dat_err(label, block_row, cat, id, ...) は、
      %   ブロック内行番号から元 CSV 行番号を解決し、両者をメッセージ
      %   引数の先頭に加えて throw_err へ委譲する。
      %
      %   入力引数:
      %     label     - ブロックラベル
      %     block_row - ブロック内行番号 (1始まり)
      %     cat       - エラーカテゴリ (throw_err に渡す)
      %     id        - エラー識別子 (throw_err に渡す)
      %     varargin  - エラーメッセージ用の追加引数
      data_rows = obj.get_data_block_rows(label);
      csv_row = obj.origrows(data_rows(block_row));
      throw_err(cat, id, block_row, csv_row, varargin{:});
    end
    function ret = bid(obj, label)
      %bid - ラベル文字列に対応するラベル番号を返す
      %
      %   ret = obj.bid(label) は、obj.labels の i 番目が label と
      %   'name=' 付きで一致すれば i、なければ 0 を返す。
      %
      %   入力引数:
      %     label - 'name=<ラベル>' 形式の文字列
      %
      %   出力引数:
      %     ret - ラベル番号 (一致した labels の添字)、なければ 0
      ret = 0;
      for i=1:length(obj.labels)
        if strcmp(label, ['name=' obj.labels{i}])
          ret = i;
          break
        end
      end
    end
  end
  methods(Access = private)
    function cdata = normalize_data_block(~, label, cdata)
      %normalize_data_block - ブロック定義に従ってセル値を正規化する
      %
      %   cdata = obj.normalize_data_block(label, cdata) は、ラベルの
      %   ブロック形式定義に従い、不足列を missing で補完し、C 列を
      %   char 化、D 列を数値3状態へ正規化する。要素荷重は継続指定の
      %   整形も行う。形式未定義のラベルは無変換で返す。
      %
      %   入力引数:
      %     label - ブロックラベル
      %     cdata - 正規化前のデータ行セル配列
      %
      %   出力引数:
      %     cdata - 正規化後のデータ行セル配列
      fmt = get_data_block_format(label);
      if isempty(fmt) || isempty(cdata)
        return
      end
      if strcmp(label, '要素荷重')
        cdata = normalize_element_load_continuation(cdata);
      end

      nfmt = length(fmt);
      if size(cdata, 2) < nfmt
        cdata(:, end+1:nfmt) = {missing};
      end

      for icol = find(fmt == 'C')
        cdata(:, icol) = cellfun(@tochar, cdata(:, icol), ...
          'UniformOutput', false);
      end
      for icol = find(fmt == 'D')
        cdata(:, icol) = cellfun(@normalize_numeric_cell, ...
          cdata(:, icol), 'UniformOutput', false);
      end

      return
    end
  end
end

function fmt = get_data_block_format(label)
%get_data_block_format - ラベルに対応する入力ブロック形式を返す
%
%   fmt = get_data_block_format(label) は、PRM.DATA_DEFINITIONS から
%   ラベルに対応する列型の形式文字列を返す。
%
%   入力引数:
%     label - ブロックラベル
%
%   出力引数:
%     fmt - 列型の形式文字列 (C:文字列、D:数値)。未定義ラベルは ''
fmt = '';
labels = PRM.DATA_DEFINITIONS(:, 1);
idx = find(strcmp(label, labels), 1);
if ~isempty(idx)
  fmt = PRM.DATA_DEFINITIONS{idx, 2};
end

return
end

function value = normalize_numeric_cell(value)
%normalize_numeric_cell - セル値を数値入力の3状態へ正規化する
%
%   value = normalize_numeric_cell(value) は、D 列のセル値を、数値
%   (入力あり)、NaN (未入力)、Inf (数値でない入力) の3状態へ正規化
%   する。Inf や -Inf の数値入力も Inf (数値でない入力と同じ扱い)
%   へ畳む。
%
%   入力引数:
%     value - readcell が返したセル値
%
%   出力引数:
%     value - double スカラー
if isnumeric(value) && isscalar(value) && isreal(value)
  if isinf(value)
    value = Inf;
  else
    value = double(value);
  end
elseif isempty(value) || (isscalar(value) && ismissing(value))
  value = NaN;
else
  value = Inf;
end

return
end

function caselabel = read_legacy_case_label(header)
%read_legacy_case_label - 旧API用に第2セルのcase属性を取得する
%
%   caselabel = read_legacy_case_label(header) は、name= 行の第2セル
%   が 'case=' で始まる場合にその属性値を返す。
%
%   入力引数:
%     header - name= 行のセル配列 (1行)
%
%   出力引数:
%     caselabel - case 属性値の char。属性がなければ []
caselabel = [];
if size(header, 2) < 2 || ~ischar(header{2})
  return
end
if startsWith(header{2}, 'case=')
  caselabel = extractAfter(header{2}, 5);
end

return
end

function attributes = parse_block_attributes(header)
%parse_block_attributes - nameセル以外のキーと値を順序非依存で取得する
%
%   attributes = parse_block_attributes(header) は、name= 行の第2セル
%   以降から 'キー=値' 形式のセルを抽出し、キーと値の組を返す。
%
%   入力引数:
%     header - name= 行のセル配列 (1行)
%
%   出力引数:
%     attributes - {キー, 値} の組のセル配列 [属性数×2]
attributes = cell(0, 2);
for icol = 2:size(header, 2)
  value = tochar(header{icol});
  separator = strfind(value, '=');
  if isempty(separator)
    continue
  end
  position = separator(1);
  key = strtrim(value(1:position - 1));
  if isempty(key)
    continue
  end
  attributes(end + 1, :) = {key, strtrim(value(position + 1:end))}; ...
    %#ok<AGROW>
end

return
end

function cdata = normalize_element_load_continuation(cdata)
%normalize_element_load_continuation - 継続指定Tを25列目へ移す
%
%   cdata = normalize_element_load_continuation(cdata) は、要素荷重
%   ブロックを25列へ補完し、21列目以降にある継続指定 'T' を25列目
%   へ移して途中の列を未入力 (missing) にする。
%
%   入力引数:
%     cdata - 要素荷重ブロックのデータ行セル配列
%
%   出力引数:
%     cdata - 25列に整えたセル配列
ncol = 25;
if size(cdata, 2) < ncol
  cdata(:, end + 1:ncol) = {missing};
end
for irow = 1:size(cdata, 1)
  tail = string(cdata(irow, 21:ncol));
  offset = find(matches(tail, 'T'), 1);
  if isempty(offset)
    continue
  end
  first = 20 + offset;
  cdata(irow, first:24) = {missing};
  cdata{irow, 25} = 'T';
end

return
end
