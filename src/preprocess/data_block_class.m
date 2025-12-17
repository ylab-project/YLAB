classdef data_block_class < handle
  properties
    labels(1,:) cell
    modelname(1,:) char
    comment(:,1) cell
    cdata(:,:) cell
    bcdata(:,1) double
    casedata(:,1) cell
    checkLabel(1,1) logical = true
    modeSS7(1,1) logical = false
  end
  methods
    %---
    function obj = data_block_class
    end
    function readCsvFile(obj, input, labels)
      % 値配列とCell配列の作成
      opts = detectImportOptions(input);
      opts.Delimiter = {','};
      opts.DataLines = [1,inf];
      opts.CommentStyle = '%';
      obj.cdata = readcell(input, opts);
      [nc,mc] = size(obj.cdata);
      iscommentline = false(1,nc);
      for i=1:nc
        iscommentline(i) = true;
        for j=1:mc
          cdata_ = obj.cdata{i,j};
          if ~ismissing(cdata_)
            if ~isnumeric(cdata_) && ~ischar(cdata_)
              cdata_ = sprintf('%s',cdata_);
            end
            if ischar(cdata_) && ~isempty(cdata_) && cdata_(1)=='%'
              if j==1
                iscommentline(i) = true;
                break
              else
                % for jj=j:mc
                %   obj.cdata{i,jj} = [];
                % end
                break
              end
            end
            iscommentline(i) = false;
          end
        end
      end
      obj.cdata(iscommentline,:) = [];
      obj.labels = labels;

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
