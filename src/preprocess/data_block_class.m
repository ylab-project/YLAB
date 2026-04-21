classdef data_block_class < handle
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
    %---
    function obj = data_block_class
    end
    function readCsvFile(obj, input, labels)
      % readlines ベースでスキップ対象行（空行・コメント行・全カンマ行）を判定
      % readcell は空行・コメント行を詰めて行番号が失われるので、元 CSV
      % 行番号を保持するためにこの段階で判定する
      lines = readlines(input);
      stripped = strtrim(lines);
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
      obj.cdata = readcell(input, opts);

      % readcell は空行・先頭%行を strip するが、クォート付%行や全カンマ
      % 行は残るため、readcell 出力を readlines の元行に対応付け、is_skip
      % で再フィルタして obj.cdata と obj.origrows を一致させる
      raw = strtrim(lines);
      is_dropped_by_readcell = (strlength(raw) == 0) | startsWith(raw, '%');
      map_cdata_to_lines = find(~is_dropped_by_readcell);
      assert(length(map_cdata_to_lines) == size(obj.cdata,1), ...
        'readcell 出力行数と readlines の対応が取れません (%d vs %d)', ...
        length(map_cdata_to_lines), size(obj.cdata,1));
      obj.cdata(is_skip(map_cdata_to_lines),:) = [];
      obj.labels = labels;

      assert(length(obj.origrows) == size(obj.cdata,1), ...
        'origrows と cdata の行数が一致しません (%d vs %d)', ...
        length(obj.origrows), size(obj.cdata,1));

      %モデルデータ
      n = size(obj.cdata,1); iddd = 1:n;
      try
        istarget = matches(obj.cdata(:,1),'モデル名');
        id = iddd(istarget); id = id(end);
        obj.modelname = obj.cdata{id,2};
      catch ex
        obj.modelname = '';
      end
      try
        istarget = matches(obj.cdata(:,1),'説明');
        id = iddd(istarget);
        obj.comment = obj.cdata(id,2);
      catch ex
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
        % obj.cdata{iline,1}
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
      % ' の処理
      % obj.cdata = cellfun(@replaceQuotes, obj.cdata, 'UniformOutput', false);
      function out = replaceQuotes(x)
        if ischar(x) || isstring(x)  % 文字列の場合のみ処理
          out = strrep(x, '''', '''''');
        else
          out = x; % 数値やその他のデータはそのまま
        end
      end
    end
    %---
    function num = get_num_data_lines(obj, label)
      bid = obj.bid(['name=' label]);
      num = sum(+(obj.bcdata==bid));
    end
    %---
    function cdata = get_data_block(obj, label, caselabel)
      bid = obj.bid(['name=' label]);
      switch nargin
        case 2
          cdata = obj.cdata(obj.bcdata==bid,:);
        case 3
          cdata = obj.cdata(obj.bcdata==bid &...
            strncmp(caselabel, obj.casedata, length(caselabel)),:);
      end
    end
    %---
    function rows = get_data_block_rows(obj, label)
    %get_data_block_rows - ブロック内の各行が cdata のどの行に対応するか
      bid = obj.bid(['name=' label]);
      rows = find(obj.bcdata == bid);
    end
    %---
    function throw_dat_err(obj, label, block_row, cat, id, varargin)
    %throw_dat_err - ブロック内行位置付きのエラーを発生
    %
    %   obj.throw_dat_err(label, block_row, cat, id, varargin) は、
    %   指定されたブロック内行番号から元 CSV 行番号を解決し、
    %   ブロック内行と CSV 行の両方をエラーメッセージの先頭引数として
    %   throw_err に委譲する。
      data_rows = obj.get_data_block_rows(label);
      csv_row = obj.origrows(data_rows(block_row));
      throw_err(cat, id, block_row, csv_row, varargin{:});
    end
    %---
    function ret = bid(obj, label)
      ret = 0;
      for i=1:length(obj.labels)
        if strcmp(label, ['name=' obj.labels{i}])
          ret = i;
          break
        end
      end
    end
    %---
  end
end
