classdef reportManager < handle
  %REPORT_MANAGER_CLASS このクラスの概要をここに記述
  %   詳細説明をここに記述

  properties
    font_size = '9pt'
    font_family = 'Times New Roman'
    tableEntriesInnerMargin = '5px'
    idfig = 0
    workdir
  end

  properties(Dependent)
    figname
  end

  methods
    %----------------------------------------------------------------------
    function obj = reportManager()
    end
    %----------------------------------------------------------------------
    function ret = get.figname(obj)
      ret = fullfile(obj.workdir, sprintf('fig%d', feature('getpid')));
    end
    %----------------------------------------------------------------------
    function table = createTable(obj, labels)
      import mlreportgen.report.*
      import mlreportgen.dom.*
      table = FormalTable();
      table.TableEntriesInnerMargin = obj.tableEntriesInnerMargin;
      table.Style = {FontSize(obj.font_size), ...
        FontFamily(obj.font_family), ...
        ResizeToFitContents(true)};
       % table.TableEntriesStyle = [ table.TableEntriesStyle {Width("1in")}];
       table.TableEntriesHAlign = "center";
       % table.Header.RowSep = "Solid";
       bo = Border();
       bo.BottomStyle = 'solid';
       bo.Width = '0.5pt';
       table.Header.Style = {bo};
      obj.appendTableHeader(table, labels)
    end
    %----------------------------------------------------------------------
    function paragraph = print(obj, s)
      import mlreportgen.report.*
      import mlreportgen.dom.*
      paragraph = Paragraph(s);
      paragraph.Style = {FontSize(obj.font_size), ...
        FontFamily(obj.font_family)};
    end
    %----------------------------------------------------------------------
    function robj = appendFigure(obj, robj, fig, caption)
      import mlreportgen.report.*
      import mlreportgen.dom.*
      obj.idfig = obj.idfig+1;
      name = sprintf('%s-%d.pdf', obj.figname, obj.idfig);
      exportgraphics(fig, name, 'ContentType', 'vector');
      if isa(robj, 'mlreportgen.report.TitlePage')
        robj.Image = Image(name);
      else
        if nargin==3
          caption = '';
        end
        im = Image(name);

        % 図の追加
        para = Paragraph(im);
        para.Style = [para.Style ...
          {OuterMargin("0pt","0pt","16pt","0pt") KeepWithNext(true)}];
        para.HAlign = 'center';
        append(robj, para);
        
        % キャプションの追加
        para = Paragraph(caption);
        para.Style = [para.Style {OuterMargin("0pt","0pt","8pt","0pt")}];
        para.HAlign = 'center';
        append(robj, para);
        % append(robj, im);
        append(robj, LineBreak());
      end
      delete(fig)
    end
  end
  methods(Static)
    %----------------------------------------------------------------------
    function appendTableHeader(table, labels)
      import mlreportgen.report.*
      import mlreportgen.dom.*
      import reportManager.*
      [nrows, ncols] = size(labels);
      for i = 1:nrows
        headRow = TableRow();
        for j = 1:ncols
          % append(headRow, TableEntry(labels{k}));
          if ischar(labels{i,j})
            label = Paragraph(labels{i,j});
          else
            label = labels{i,j};
          end
          if isempty(label)
            label = "";
          end
          append(headRow, TableEntry(label));
        end
        append(table.Header, headRow);
      end
      append_top_border(table.Header);
    end
    %----------------------------------------------------------------------
    function append_entry(row, fmt, s)
      import mlreportgen.report.*
      import mlreportgen.dom.*
      import reportManager.*
      if ischar(s)
        append(row, TableEntry(sprintf(fmt, s)));
        return
      end
      if isnumeric(s)
        for k_=1:length(s)
          append(row, TableEntry(sprintf(fmt, s(k_))));
        end
        return
      end
      if iscell(s)
        for k_=1:length(s)
          append(row, TableEntry(sprintf(fmt, s{k_})));
        end
        return
      end
    end
    %----------------------------------------------------------------------
    function appned_multi_entry(table, fmt, s)
      import mlreportgen.report.*
      import mlreportgen.dom.*
      import reportManager.*
      n = length(s);
      ncols = double(table.NCols);
      nrows = ceil(n/ncols);
      for i=1:nrows
        row = TableRow();
        append_entry(row, fmt, ...
          s(((i-1)*ncols+1):(min(i*ncols,n))));
        append(table, row);
      end      
    end
    %----------------------------------------------------------------------
    function append_top_border(robj)
      import mlreportgen.report.*
      import mlreportgen.dom.*
      import reportManager.*
      if ~isempty(robj.Style)
        bo = robj.Style{1};
      else
        bo = Border();
      end
      bo.TopStyle = 'solid';
      bo.Width = '0.5pt';
      robj.Style = [robj.Style {bo}];
    end
    % %----------------------------------------------------------------------
    % function append_bottom_border(robj)
    %   import mlreportgen.report.*
    %   import mlreportgen.dom.*
    %   import reportManager.*
    %   if ~isempty(robj.Style)
    %     bo = robj.Style{1};
    %   else
    %     bo = Border();
    %   end
    %   bo.BottomStyle = 'solid';
    %   bo.Width = '0.5pt';
    %   robj.Style = {bo};
    % end
    %----------------------------------------------------------------------
    function append_bottom_border(robj)
      import mlreportgen.report.*
      import mlreportgen.dom.*
      import reportManager.*
      if isa(robj,'mlreportgen.dom.FormalTable')
        row = robj.Body.Children(end);
      else
        row = robj;
      end
      if ~isempty(row.Style)
        bo = robj.Style{1};
      else
        bo = Border();
      end
      bo.BottomStyle = 'solid';
      bo.Width = '0.5pt';
      row.Style = {bo};
    end
  end
end

