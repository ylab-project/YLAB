classdef data_block_class < handle
  %data_block_class - 入力 CSV をブロック単位に分類するクラス
  %
  %   CSV を読み込み、name= 行と <data> 行でデータブロックに分割し、
  %   ラベル指定でのブロック取得と行位置付きエラー通知を提供する。
  %
  %   data_block_class プロパティ:
  %     labels     - 有効なブロックラベル一覧
  %     modelname  - 「モデル名」行の値
  %     comment    - 「説明」行の値
  %     cdata      - スキップ行除去後の全セルデータ
  %     bcdata     - 各行のブロック番号 (0:非データ行)
  %     casedata   - 各行のケースラベル
  %     origrows   - 各行の元 CSV 行番号
  %     checkLabel - 未登録ラベルをエラーにするか
  %     modeSS7    - SS7 連携モードか
  %
  %   data_block_class メソッド:
  %     readCsvFile         - CSV を読み込みブロックに分類
  %     get_num_data_lines  - 指定ラベルのデータ行数
  %     get_data_block      - 指定ラベルのデータブロック取得
  %     get_data_block_rows - ブロック内各行の cdata 行番号
  %     throw_dat_err       - ブロック内行位置付きエラー
  %     bid                 - ラベルに対応するブロック番号
  properties
    labels(1,:) cell
    modelname(1,:) char
    comment(:,1) cell
    cdata(:,:) cell
    bcdata(:,1) double
    casedata(:,1) cell
    origrows(:,1) double
    checkLabel(1,1) logical = true
    modeSS7(1,1) logical = false
  end
  methods
    function obj = data_block_class
      %data_block_class - 空のインスタンスを生成するコンストラクタ
      %
      %   出力引数:
      %     obj - data_block_class インスタンス
    end
    function readCsvFile(obj, input, labels)
      %readCsvFile - CSV を読み込みブロック単位に分類する
      %
      %   input の CSV を空行・コメント行を除いて読み込み、name= 行と
      %   <data> 行でブロックに分割する。ブロック番号・ケース・元行番号
      %   を各プロパティに保持する。
      %
      %   入力引数:
      %     input  - CSV ファイルパス
      %     labels - 有効なブロックラベル一覧 (cell)
      % readlines ベースでスキップ対象行（空行・コメント行・全カンマ
      % 行）を判定。readcell は空行・コメント行を詰めて行番号が失われ
      % るので、元 CSV 行番号を保持するためにこの段階で判定する
      stripped = strtrim(readlines(input));
      % readcell は常にファイル末尾の改行 1 つを trim する一方、
      % readlines は末尾改行で空行を 1 つ多く生成する。両者の行数を
      % 整合させるため、末尾空行を常に 1 つ削る (末尾空行が 0 個の
      % CSV は対象外)
      if ~isempty(stripped) && strlength(stripped(end)) == 0
        stripped(end) = [];
      end
      % readcell からドロップされる行は CommentStyle='%' の先頭%行のみ
      % (下記 EmptyLineRule='read' で空行・全カンマ行は保持)。クォート
      % 付き %行を誤判定しないよう、クォート除去前の stripped で判定
      is_dropped_by_readcell = startsWith(stripped, '%');
      % has_quote/extractAfter で先頭クォート除去後に %始まりを is_skip
      % 判定対象に含めるのは、SS7 連携入力 CSV の装飾セクション区切り
      % ("% ====== ..." 等のクォート付%行) を装飾コメントとして統一的
      % にスキップする意図的設計 (参照: コミット b015ebb)
      has_quote = startsWith(stripped, '"');
      stripped(has_quote) = extractAfter(stripped(has_quote), 1);
      no_comma = strtrim(replace(stripped, ',', ''));
      is_skip = (strlength(no_comma) == 0) | startsWith(no_comma, '%');
      obj.origrows = find(~is_skip);

      % 値配列とCell配列の作成
      opts = detectImportOptions(input);
      opts.Delimiter = {','};
      opts.DataLines = [1,inf];
      opts.CommentStyle = '%';
      % 全 missing 行を保持し、is_skip で後段除去する。default の skip
      % は CSV 規模・列数推定によって全カンマ行の trim 可否が変わり、
      % readcell 行数と origrows の対応が不安定になるため明示
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

      % モデルデータ
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

      % ブロック番号の判別
      nlines = size(obj.cdata, 1);
      obj.bcdata = zeros(nlines,1);
      obj.casedata = cell(nlines,1);
      bid = 0;
      caselabel = [];
      isdata = true;
      for iline=2:nlines
        isheader = false;
        if ischar(obj.cdata{iline,1})
          if contains(obj.cdata{iline,1},'name=')
            isheader = true;
            bid = 0;
            if ischar(obj.cdata{iline,2})
              if contains(obj.cdata{iline,2},'case=')
                caselabel = obj.cdata{iline,2}(6:end);
              else
                caselabel = [];
              end
            else
              caselabel = [];
            end
            if (obj.modeSS7)
              isdata = false;
            end
          end
          if contains(obj.cdata{iline,1},'<data>')
            isheader = true;
            isdata = true;
          end
        end
        if obj.bid(obj.cdata{iline,1})>0
          bid = obj.bid(obj.cdata{iline,1});
        elseif isheader&&obj.checkLabel
          error('(%d) "%s" は登録されたキーワードではありません', ...
            iline, obj.cdata{iline,1});
        end
        if (~isheader&&isdata)
          obj.bcdata(iline) = bid;
          obj.casedata{iline} = caselabel;
        end
      end
    end
    function num = get_num_data_lines(obj, label)
      %get_num_data_lines - 指定ラベルのデータ行数を返す
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
      %   caselabel を指定すると、前方一致するケースに限定して返す。
      %
      %   入力引数:
      %     label     - ブロックラベル
      %     caselabel - ケースラベル前方一致フィルタ (任意)
      %
      %   出力引数:
      %     cdata - 該当行を抽出した cell 配列
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
    function rows = get_data_block_rows(obj, label)
      %get_data_block_rows - ブロック内各行の cdata 行番号を返す
      %
      %   throw_dat_err での元 CSV 行番号解決に使用する。
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
      %   ブロック内行番号から元 CSV 行番号を解決し、両方を先頭引数と
      %   して throw_err に委譲する。
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
      %bid - ラベル文字列に対応するブロック番号を返す
      %
      %   obj.labels の i 番目が label と 'name=' 付きで一致すれば i、
      %   なければ 0 を返す。
      %
      %   入力引数:
      %     label - 'name=<ラベル>' 形式の文字列
      %
      %   出力引数:
      %     ret - 一致した添字、なければ 0
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
      fmt = get_data_block_format(label);
      if isempty(fmt) || isempty(cdata)
        return
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
