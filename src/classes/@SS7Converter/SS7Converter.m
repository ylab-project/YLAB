classdef SS7Converter < handle
  %DATACONVERTER このクラスの概要をここに記述
  %   詳細説明をここに記述

  properties
    dataBlock
    baseline
    girderCMQ
    cantileverCMQ
    % cmqcan
    earthquake
    node
    nodalWeight
    story
    % 定数
    nblx, nbly, nnode, nstory
  end

  %------------------------------------------------------------------------
  methods
    function obj = SS7Converter
      %DATACONVERTER このクラスのインスタンスを作成
      %   詳細説明をここに記述
      addpath('analysis');
      addpath('postprocess');
      addpath('preprocess');
      addpath('util');
    end

    %----------------------------------------------------------------------
    function readSS7Csv(obj, ss7csvfile)
      %METHOD1 このメソッドの概要をここに記述
      %   詳細説明をここに記述
      labels = {'構造階高', '構造スパン', ...
        '節点座標(構造心)', '節点重量表(固定+積載)', ...
        '梁CMoQo表', '片持梁CMoQo表' , ...
        '節点重量表(固定+積載)', '等価節点荷重', ...
        '水平力・重心位置(一次)', ...
        '片持梁応力表'};
      obj.dataBlock = data_block_class;
      obj.dataBlock.checkLabel = false;
      obj.dataBlock.modeSS7 = true;
      obj.dataBlock.readCsvFile(ss7csvfile, labels);
    end
    %----------------------------------------------------------------------
    function convert(obj, csvfile)
      % CSVファイル
      fout = fopen(csvfile, 'w+', 'native', 'Shift_JIS');
      modeSS7 = false;

      % 層・通りの読み出し
      [obj.baseline, obj.story] = obj.extractBaseline();
      obj.nblx = length(obj.baseline.x.name);
      obj.nbly = length(obj.baseline.y.name);
      obj.nstory = length(obj.story.name);

      % 節点の読み出し
      obj.node = obj.extractNode();
      obj.nnode = size(obj.node,1);

      % 梁CMQの読み出し
      obj.girderCMQ = obj.extractGirderCMQ();

      % 片持梁CMQの読み出し
      % obj.cmqcan = obj.extractCantileverCMQ();
      obj.cantileverCMQ = obj.extractCantileverCMQ;

      % 節点重量表の読み出し
      obj.nodalWeight = obj.extractNodalWeight();

      % 等価節点荷重の読み出し
      obj.nodalWeight.feq = obj.extractEqNodalForce();

      % % 片持梁応力表の読み出し
      % obj.nodalWeight.fcan = obj.extractCantileverForce();

      % 地震力の読み出し
      obj.earthquake = obj.extractEarthquakeForce();

      % 等価節点荷重の書き出し
      [nodalLoad, header] = obj.writeCellNodalLoad();
      if ~isempty(nodalLoad)
        fprintf(fout, 'name=節点荷重\n');
        write_csv_from_cell(fout, header, nodalLoad, modeSS7);
        fprintf(fout, ',\n');
      end

      % 追加節点荷重の書き出し
      [addNodalLoad, header] = obj.writeCellAdditiveNodalLoad();
      if ~isempty(addNodalLoad)
        fprintf(fout, 'name=追加節点荷重\n');
        write_csv_from_cell(fout, header, addNodalLoad, modeSS7);
        fprintf(fout, ',\n');
      end

      % 梁要素荷重の書き出し
      [girderLoad, header] = obj.writeCellGirderLoad();
      fprintf(fout, 'name=梁要素荷重\n');
      write_csv_from_cell(fout, header, girderLoad, modeSS7);
      fprintf(fout, '\n');

      % 終了処理
      fclose(fout);
      fclose('all');
    end
  end
  methods(Access=private)
    %----------------------------------------------------------------------
    function [idnode, idir] = findGirderNode(...
        obj, frame_name, a1name, a2name, story_name)

      % 層・通りの検索
      innn = 1:obj.nnode;
      ixxx = 1:obj.nblx;
      iyyy = 1:obj.nbly;
      isss = 1:obj.nstory;
      idfx = ixxx(matches(obj.baseline.x.name, frame_name));
      idfy = iyyy(matches(obj.baseline.y.name, frame_name));
      ids = isss(matches(obj.story.name, story_name));

      % 節点の検索
      if ~isempty(idfx)
        % Xフレーム
        idir = PRM.Y;
        idy1 = iyyy(matches(obj.baseline.y.name, a1name));
        idy2 = iyyy(matches(obj.baseline.y.name, a2name));
        in1 = innn(obj.node.idx==idfx & ...
          obj.node.idy==idy1 & obj.node.idstory==ids);
        in2 = innn(obj.node.idx==idfx & ...
          obj.node.idy==idy2 & obj.node.idstory==ids);
      elseif ~isempty(idfy)
        % Yフレーム
        idir = PRM.X;
        idx1 = ixxx(matches(obj.baseline.x.name, a1name));
        idx2 = ixxx(matches(obj.baseline.x.name, a2name));
        in1 = innn(obj.node.idx==idx1 & ...
          obj.node.idy==idfy & obj.node.idstory==ids);
        in2 = innn(obj.node.idx==idx2 & ...
          obj.node.idy==idfy & obj.node.idstory==ids);
      else
        error('%sは存在しないフレームです', frame_name);
      end
      idnode = [in1 in2];
    end
    %----------------------------------------------------------------------
    function idnode = findIdNode(obj, xname, yname, story_name)
      % 層・通りの検索
      innn = 1:obj.nnode;
      ixxx = 1:obj.nblx;
      iyyy = 1:obj.nbly;
      isss = 1:obj.nstory;
      idx = ixxx(matches(obj.baseline.x.name, xname));
      idy = iyyy(matches(obj.baseline.y.name, yname));
      ids = isss(matches(obj.story.name, story_name));

      % 節点の検索
      idnode = innn(obj.node.idx==idx & ...
        obj.node.idy==idy & obj.node.idstory==ids);
    end
    %----------------------------------------------------------------------
    % function fcan = extractCantileverForce(obj)
    %   % データブロックの取り出し
    %   data = obj.dataBlock.get_data_block('片持梁応力表','G+P');
    % 
    %   % 計算の準備
    %   fcan = zeros(obj.nnode,6);
    %   nrow = size(data,1);
    % 
    %   % 梁CMQの読み出し
    %   for i=1:nrow
    %     % 節点番号の取り出し
    %     idnode = obj.findIdNode(data{i,2}, data{i,3}, data{i,1});
    %     % idir = PRM.X;
    %     if isempty(idnode)
    %       idnode = obj.findIdNode(data{i,3}, data{i,2}, data{i,1});
    %       % idir = PRM.Y;
    %     end
    %     if isempty(idnode)
    %       continue
    %     end
    % 
    %     % 跳出方向の判定
    %     switch data{i,4}
    %       case '上'
    %         idm = 4;
    %         M = -data{i,7};
    %       case '下'
    %         idm = 4;
    %         M = data{i,7};
    %       case '左'
    %         idm = 5;
    %         M = -data{i,7};
    %       case '右'
    %         idm = 5;
    %         M = data{i,7};
    %     end
    % 
    %     % 節点荷重の保存
    %     Q = -data{i,8};
    %     % Q = 0;
    %     fcan(idnode,[3 idm]) = fcan(idnode,[3 idm])+[Q M];
    %   end
    % end
    %----------------------------------------------------------------------
    %----------------------------------------------------------------------
    %----------------------------------------------------------------------
  end
end
