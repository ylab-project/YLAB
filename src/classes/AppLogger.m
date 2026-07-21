classdef AppLogger < handle
%AppLogger - 全ライフタイム保持のロギング機構
%
%   1回のチューニング実行で生成した記録を context キー
%   (trial/phase/iteration) 単位で保持し、必要時に MAT へ書き出す。
%   collect が false のとき record は no-op となり、本番では
%   ゼロコストになる。
%
%   備考:
%     - handle クラス。groot appdata に保持し、受け渡し不要で
%       get_logger により参照する。
%     - persist が true のとき flush_iteration が context キーを
%       変数名として1反復1変数の MAT を追記する。

  properties
    collect (1,1) logical = false
    persist (1,1) logical = false
    % verbose=false のとき persist は2次元生配列を外した lean 版を書く
    verbose (1,1) logical = false
    file_path (1,:) char = ''
  end

  properties (Access = private)
    keys = {}
    groups = {}
    contexts = {}
  end

  methods
    function obj = AppLogger(collect, persist, file_path)
    %AppLogger - コンストラクタ
    %
    %   obj = AppLogger(collect, persist, file_path) は、収集フラグ
    %   collect、保存フラグ persist、保存先 file_path を設定した
    %   ロガーを生成する。引数省略時は無効ロガー(collect=false)。
    %
    %   入力引数:
    %     collect   - 記録を蓄積するか (1,1 logical)
    %     persist   - MAT へ保存するか (1,1 logical)
    %     file_path - 保存先 MAT パス (char)
    %
    %   出力引数:
    %     obj - AppLogger インスタンス
      if nargin >= 1
        obj.collect = collect;
      end
      if nargin >= 2
        obj.persist = persist;
      end
      if nargin >= 3
        obj.file_path = file_path;
      end
      return
    end

    function tf = isEnabled(obj)
    %isEnabled - 収集が有効かを返す
    %
    %   tf = isEnabled(obj) は、収集フラグ collect を返す。
    %
    %   入力引数:
    %     obj - AppLogger インスタンス
    %
    %   出力引数:
    %     tf - 収集有効なら true (1,1 logical)
      tf = obj.collect;
      return
    end

    function record(obj, context, group, payload)
    %record - 1グループの記録を context キーで蓄積する
    %
    %   record(obj, context, group, payload) は、collect が true の
    %   ときだけ、context (trial/phase/iteration) をキーに payload を
    %   group 名で蓄積する。collect が false のとき何もしない。
    %
    %   入力引数:
    %     obj     - AppLogger インスタンス
    %     context - idtrial/idphase/iteration を持つ構造体
    %     group   - 記録グループ名 (char)
    %     payload - 蓄積するデータ
      if ~obj.collect
        return
      end
      key = obj.context_key(context);
      idx = obj.find_key(key);
      if idx == 0
        obj.keys{end+1} = key;
        obj.contexts{end+1} = context;
        obj.groups{end+1} = struct();
        idx = numel(obj.keys);
      end
      group_struct = obj.groups{idx};
      group_struct.(group) = payload;
      obj.groups{idx} = group_struct;
      return
    end

    function flush_iteration(obj, context)
    %flush_iteration - 1反復分を組み立て、必要なら MAT へ保存する
    %
    %   flush_iteration(obj, context) は、collect が true のとき、
    %   context に対応する蓄積グループから1反復レコードを組み立てる。
    %   persist が true なら context キーを変数名として MAT へ追記
    %   する。蓄積がなければ何もしない。
    %
    %   入力引数:
    %     obj     - AppLogger インスタンス
    %     context - idtrial/idphase/iteration を持つ構造体
      if ~obj.collect
        return
      end
      key = obj.context_key(context);
      idx = obj.find_key(key);
      if idx == 0
        return
      end
      record_out = obj.build_record(obj.contexts{idx}, obj.groups{idx});
      if obj.persist
        obj.persist_record(key, record_out);
      end
      return
    end

    function record_out = get_record(obj, context)
    %get_record - context に対応する組み立て済みレコードを返す
    %
    %   record_out = get_record(obj, context) は、context の蓄積から
    %   1反復レコードを組み立てて返す。テストの照会に使う。蓄積が
    %   なければ空構造体を返す。
    %
    %   入力引数:
    %     obj     - AppLogger インスタンス
    %     context - idtrial/idphase/iteration を持つ構造体
    %
    %   出力引数:
    %     record_out - 組み立てた1反復レコード (struct)
      idx = obj.find_key(obj.context_key(context));
      if idx == 0
        record_out = struct();
        return
      end
      record_out = obj.build_record(obj.contexts{idx}, obj.groups{idx});
      return
    end

    function save_iteration(obj, context, record)
    %save_iteration - 組み立て済みレコードを context キー名で保存する
    %
    %   save_iteration(obj, context, record) は、persist が true の
    %   とき、record を context キー(trial/phase/iteration)を変数名と
    %   して MAT へ追記する。group 蓄積を介さない直接保存経路で、移行
    %   期に既存 create_diagnostic の出力をそのまま書き出すのに使う。
    %
    %   入力引数:
    %     obj     - AppLogger インスタンス
    %     context - idtrial/idphase/iteration を持つ構造体
    %     record  - 保存する組み立て済みレコード (struct)
      if ~obj.persist
        return
      end
      obj.persist_record(obj.context_key(context), record);
      return
    end

    function reset(obj)
    %reset - 蓄積した記録をすべて破棄する
    %
    %   reset(obj) は、蓄積済みのキー・グループ・context を空にする。
    %
    %   入力引数:
    %     obj - AppLogger インスタンス
      obj.keys = {};
      obj.groups = {};
      obj.contexts = {};
      return
    end
  end

  methods (Access = private)
    function key = context_key(~, context)
    %context_key - context から一意なキー文字列を作る
    %
    %   key = context_key(~, context) は、idtrial/idphase/iteration
    %   から trial/phase/iteration 形式のキー文字列を作る。
    %
    %   入力引数:
    %     context - idtrial/idphase/iteration を持つ構造体
    %
    %   出力引数:
    %     key - キー文字列 (char)
      key = sprintf('trial_%04d_phase_%04d_iteration_%04d', ...
        context.idtrial, context.idphase, context.iteration);
      return
    end

    function idx = find_key(obj, key)
    %find_key - 蓄積済みキーの位置を返す（なければ0）
    %
    %   idx = find_key(obj, key) は、keys の中で key に一致する要素の
    %   位置を返す。一致がなければ 0 を返す。
    %
    %   入力引数:
    %     obj - AppLogger インスタンス
    %     key - 検索するキー文字列 (char)
    %
    %   出力引数:
    %     idx - 一致位置。なければ 0
      idx = 0;
      for i = 1:numel(obj.keys)
        if strcmp(obj.keys{i}, key)
          idx = i;
          return
        end
      end
      return
    end

    function record_out = build_record(~, context, group_struct)
    %build_record - context とグループから1反復レコードを組み立てる
    %
    %   record_out = build_record(~, context, group_struct) は、
    %   context の識別子 (idtrial/idphase/iteration) と蓄積グループを
    %   1つの構造体へ統合する。
    %
    %   入力引数:
    %     context      - idtrial/idphase/iteration を持つ構造体
    %     group_struct - group 名をフィールドに持つ構造体
    %
    %   出力引数:
    %     record_out - 統合した1反復レコード (struct)
      record_out = group_struct;
      record_out.idtrial = context.idtrial;
      record_out.idphase = context.idphase;
      record_out.iteration = context.iteration;
      return
    end

    function out = lean_record(obj, in)
    %lean_record - 2次元の生配列フィールドを再帰的に除いた版を返す
    %
    %   out = lean_record(obj, in) は、in の各フィールドを走査し、
    %   数値・論理の2次元行列（スカラーでもベクトルでもない配列）を
    %   除去する。struct フィールドは再帰的に処理する。既定 persist
    %   の lean 化（核＋1次元のみ保存）に使う。
    %
    %   入力引数:
    %     obj - AppLogger インスタンス
    %     in  - 元の1反復レコード (struct)
    %
    %   出力引数:
    %     out - 2次元配列を除いたレコード (struct)
      out = in;
      names = fieldnames(in);
      for i = 1:numel(names)
        value = in.(names{i});
        if isstruct(value)
          out.(names{i}) = obj.lean_record(value);
        elseif (isnumeric(value) || islogical(value)) && ~isvector(value)
          out = rmfield(out, names{i});
        end
      end
      return
    end

    function persist_record(obj, key, record_out)
    %persist_record - 1反復レコードを context キー名で MAT へ追記する
    %
    %   persist_record(obj, key, record_out) は、file_path の MAT へ
    %   key を変数名として record_out を保存する。既存ファイルには
    %   追記し、無ければ -v7.3 で新規作成する。
    %
    %   入力引数:
    %     obj        - AppLogger インスタンス
    %     key        - 保存する変数名 (char)
    %     record_out - 保存する1反復レコード (struct)
      if ~obj.verbose
        record_out = obj.lean_record(record_out);
      end
      [folder, name, extension] = fileparts(obj.file_path);
      if isempty(extension)
        extension = '.mat';
      end
      if isempty(folder)
        folder = pwd;
      end
      if ~isfolder(folder)
        mkdir(folder);
      end
      output_path = fullfile(folder, [name extension]);
      payload = struct();
      payload.(key) = record_out;
      if isfile(output_path)
        save(output_path, '-struct', 'payload', '-append');
      else
        save(output_path, '-struct', 'payload', '-v7.3');
      end
      return
    end
  end
end
