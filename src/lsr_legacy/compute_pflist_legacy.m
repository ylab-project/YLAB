function [pflist, flist, clist, vlist, isexec] = ...
  compute_pflist_legacy(pffun, xlist, com, options, cache)
%COMPUTE_PFLIST 候補断面を評価する
% 概要: 戦略を切り替えて compute_individual を実行する。
% 入力: pffun - ペナルティ関数
%        xlist - 候補断面配列
%        com - 共通構造体（部材、節点、層、断面等の情報）
%        options - オプション構造体（並列戦略、表示設定等）
%        cache - キャッシュ構造体（既計算結果の再利用）
% 出力: pflist - ペナルティ付き目的関数値の配列
%        flist - 純粋な目的関数値の配列
%        clist - 制約関数値の配列（各行が1断面、各列が1制約）
%        vlist - 制約違反量の配列
%        isexec - 解析実行フラグ（true=新規計算、false=キャッシュ利用）

% 制約数と違反数をオプションから取得
numc = options.numc;     % 制約関数の数
numvio = options.numvio;  % 制約違反の数
lsize = size(xlist, 1);   % 評価する断面候補の数

% 出力配列を事前割当（メモリ効率化）
flist = zeros(lsize, 1);         % 目的関数値
pflist = zeros(lsize, 1);         % ペナルティ付き目的関数値
clist = zeros(lsize, numc);      % 制約関数値
vlist = zeros(lsize, numvio);    % 制約違反量
isexec = false(lsize, 1);        % 実行フラグ

% 空配列の場合は早期リターン
if lsize == 0
  return
end

% 並列実行戦略を決定（auto, sequential, parfor, parfeval）
strategy = resolve_strategy(options, lsize);

% 表示モードの取得（進捗表示用）
display_mode = '';
if isfield(options, 'display')
  display_mode = char(options.display);
end

% 戦略に応じた評価関数を実行
switch strategy
  case 'sequential'
    % 逐次実行（並列化なし）
    % fprintf('  strategy=sequential: lsize=%d\n', lsize);
    % evaluate_sequential();

  case 'parfor'
    % 従来のparfor並列実行
    pool = gcp('nocreate');
    nworkers = 0;
    if ~isempty(pool)
      nworkers = pool.NumWorkers;
    end
    % fprintf('  parfor stat: lsize=%d workers=%d\n', lsize, nworkers);
    % evaluate_parfor();

  case 'parfeval'
    % ブロック化parfeval並列実行（新戦略）
    evaluate_parfeval();

  otherwise
    error('compute_pflist:UnknownStrategy', ...
      '不明な並列戦略: %s', strategy);
end

return

  function evaluate_sequential()
  %EVALUATE_SEQUENTIAL 逐次実行版の評価関数
  % 単一の乱数ストリームを使用して順番に各断面を評価
  % タスクごとにSubstreamを設定して再現性を保証

  % Threefry乱数生成器を作成（高速かつ並列化に適した生成器）
  stream = RandStream('Threefry');
  prev_stream = RandStream.setGlobalStream(stream);

  % 各候補断面を順次評価
  for id = 1:lsize
    % タスクIDごとに異なる乱数系列を使用
    stream.Substream = id;

    % 個別評価関数を呼び出し
    [flist(id), clist(id, :), pflist(id), vlist(id, :), ...
      isexec(id)] = compute_individual(xlist(id, :), pffun, com, ...
      options, cache);
  end

  % 元の乱数ストリームに戻す
  RandStream.setGlobalStream(prev_stream);
  return
  end

  function evaluate_parfor()
  %EVALUATE_PARFOR 従来のparfor並列実行版
  % 各ワーカーに独立した乱数ストリームを供給
  % Substreamによりタスク間の乱数系列の独立性を保証

  % ワーカーごとに乱数ストリームを作成（遅延評価）
  stream_constant = parallel.pool.Constant(@() RandStream('Threefry'));

  % parforループで並列評価（細粒度タスク）
  pool = gcp('nocreate');
  nworkers = 0;
  if ~isempty(pool)
    nworkers = pool.NumWorkers;
  end
  if nworkers > 0
    % fprintf('  strategy=parfor: lsize=%d workers=%d tasks/worker=%.2f\n', ...
    %   lsize, nworkers, lsize / nworkers);
  else
    % fprintf('  strategy=parfor: lsize=%d workers=%d\n', lsize, nworkers);
  end
  parfor id = 1:lsize
    % ワーカーローカルの乱数ストリームを取得
    stream = stream_constant.Value;
    prev_stream = RandStream.setGlobalStream(stream);

    % タスクIDごとに異なる乱数系列
    stream.Substream = id;

    % 個別評価を実行
    [flist(id), clist(id, :), pflist(id), vlist(id, :), ...
      isexec(id)] = compute_individual(xlist(id, :), pffun, com, ...
      options, cache);

    % 元のストリームに戻す
    RandStream.setGlobalStream(prev_stream);
  end

  return
  end

  function evaluate_parfeval()
  %EVALUATE_PARFEVAL ブロック化parfeval並列実行版（新戦略）
  % タスクをワーカー数分のブロックに分割して並列実行
  % 通信オーバーヘッドを削減

  % 並列プールとワーカー数を取得
  pool = gcp();
  num_workers = pool.NumWorkers;

  % タスクをワーカー数分のブロックに分割
  blocks_all = partition_indices(lsize, num_workers);

  % 空でないブロックのみ抽出（タスク数がワーカー数より少ない場合）
  is_active = ~cellfun(@isempty, blocks_all);
  blocks = blocks_all(is_active);
  num_blocks = numel(blocks);

  % ブロックがない場合は早期リターン
  if num_blocks == 0
    return
  end

  % 共有データを並列プール全体で共有（転送は1回のみ）
  if isfield(options, 'com_constant') && ...
      isa(options.com_constant, 'parallel.pool.Constant') && ...
      isvalid(options.com_constant)
    com_constant = options.com_constant;                % 事前生成された構造体データ
  else
    com_constant = parallel.pool.Constant(com);         % フォールバックで生成
  end
  stream_constant = ...
    parallel.pool.Constant(@() RandStream('Threefry')); % 乱数ストリーム

  % 並列タスク（Future）の配列を準備
  futures = parallel.FevalFuture.empty(num_blocks, 0);
  start_times = cell(num_blocks, 1);
  durations = zeros(num_blocks, 1);
  block_sizes = cellfun(@numel, blocks);
  % fprintf('  strategy=parfeval: lsize=%d blocks=%d size=[%d..%d] range=%d\n', ...
  %   lsize, num_blocks, min(block_sizes), max(block_sizes), ...
  %   max(block_sizes) - min(block_sizes));

  % 各ブロックをワーカーに投入
  for iw = 1:num_blocks
    start_times{iw} = tic;
    futures(iw) = parfeval(pool, @evaluate_block, 5, blocks{iw}, ...
      xlist, pffun, com_constant, stream_constant, options, cache);
  end

  % 実行時間計測開始
  if strcmp(display_mode, 'Iter')
    tic_handle = tic;
  end

  % 完了順に結果を収集（動的負荷分散）
  for iw = 1:num_blocks
    % fetchNextで最初に完了したタスクの結果を取得
    [completed, fl_blk, cl_blk, pf_blk, vl_blk, ex_blk] = ...
      fetchNext(futures);
    durations(completed) = toc(start_times{completed});

    % ブロックのインデックスを取得
    ids = blocks{completed};

    % 結果を元の配列の正しい位置に格納
    flist(ids) = fl_blk;
    clist(ids, :) = cl_blk;
    pflist(ids) = pf_blk;
    vlist(ids, :) = vl_blk;
    isexec(ids) = ex_blk;
  end

  % 実行時間を表示
  if strcmp(display_mode, 'Iter')
    fprintf('  parfeval: %dブロック %.1f秒\n', num_blocks, ...
      toc(tic_handle));
  end

  % if num_blocks > 0
  %   fprintf('  parfeval timing: min=%.2fs max=%.2fs range=%.2fs\n', ...
  %     min(durations), max(durations), max(durations) - min(durations));
  % end

  return
  end

  function strategy = resolve_strategy(options_, lsize_)
  %RESOLVE_STRATEGY 並列実行戦略を決定
  % タスク数、ワーカー数、オプション設定に基づいて最適な戦略を選択
  %
  % 戦略選択ロジック:
  % - sequential: 並列化なし、または小規模タスク
  % - parfor: 中規模タスク（ワーカー数×10未満）
  % - parfeval: 大規模タスク（ワーカー数×10以上）

  % ワーカー当たりの最小タスク数（これ未満はparforを使用）
  min_tasks_per_worker = 2;

  % parallel_strategyオプションの取得（デフォルト: 'auto'）
  if ~isfield(options_, 'parallel_strategy') || ...
      isempty(options_.parallel_strategy)
    requested = 'auto';
  else
    requested = char(options_.parallel_strategy);
  end

  % parfeval切替の閾値（1ワーカー当たりの最小タスク数）
  block_factor = 10;
  if isfield(options_, 'parallel_block_factor') && ...
      ~isempty(options_.parallel_block_factor)
    block_factor = options_.parallel_block_factor;
  end

  % 要求された戦略に応じた処理
  switch requested
    case 'auto'
      % === 自動選択モード ===

      % 並列化が無効、またはタスクが1個以下の場合
      if ~options_.do_parallel || lsize_ <= 1
        strategy = 'sequential';
        return
      end

      % 並列プールの確認
      pool = gcp('nocreate');
      if isempty(pool)
        % プールがない場合は逐次実行
        strategy = 'sequential';
        return
      end

      % タスク数 / ワーカー数を基準に戦略を選択
      tasks_per_worker = lsize_ / pool.NumWorkers;

      % 極端に少ない場合は従来のparfor（細粒度並列）
      if tasks_per_worker < min_tasks_per_worker
        strategy = 'parfor';
        return
      end

      if tasks_per_worker < block_factor
        % ワーカー当たりのタスク数が閾値未満: parfor を継続
        strategy = 'parfor';
      else
        % 十分なタスクがある: parfeval（ブロック並列）
        strategy = 'parfeval';
      end

    case {'sequential', 'parfor', 'parfeval'}
      % 明示的に指定された戦略を使用
      strategy = requested;

    otherwise
      % 不明な戦略はエラー
      error('compute_pflist:InvalidStrategy', ...
        '不明な並列戦略: %s（使用可能: auto, sequential, parfor, parfeval）', ...
        requested);
  end

  return
  end
end

%--------------------------------------------------------------------------
function [fval, cvec, pfval, vio, isexec] = compute_individual( ...
  xvar, pffun, com, options, cache)

secmgr = com.secmgr;
section = com.section;
member = com.member;
baseline = com.baseline;
node = com.node;
story = com.story;
floor = com.floor;

id = [];
isexec = false;
if options.do_cache && ~isempty(cache.xlist)
  [ddd, iddd] = pdist2(cache.xlist, xvar, ...
    'fastsquaredeuclidean', 'Smallest', 1);
  iscached = (ddd == 0);
  if any(iscached)
    id = iddd(iscached);
    id = id(1);
    fval = cache.flist(id);
    cvec = cache.clist(id, :);
  end
end

if isempty(id)
  cvec = analysis_constraint(xvar, com, options);
  fval = objective_lsr(xvar, secmgr, baseline, node, section, ...
    member, story, floor, options);
  isexec = true;
end

[pfval, vio] = pffun(fval, cvec);
return
end

%--------------------------------------------------------------------------
function blocks = partition_indices(total_size, num_workers)

validateattributes(total_size, {'numeric'}, ...
  {'scalar', 'positive', 'integer'});
validateattributes(num_workers, {'numeric'}, ...
  {'scalar', 'positive', 'integer'});

base_size = floor(total_size / num_workers);
remainder = mod(total_size, num_workers);

block_sizes = repmat(base_size, num_workers, 1);
block_sizes(1:remainder) = block_sizes(1:remainder) + 1;

end_indices = cumsum(block_sizes);
start_indices = [1; end_indices(1:end - 1) + 1];

blocks = cell(num_workers, 1);
for w = 1:num_workers
  blocks{w} = start_indices(w):end_indices(w);
end

return
end

%--------------------------------------------------------------------------
function [flist_block, clist_block, pflist_block, vlist_block, ...
  isexec_block] = evaluate_block(indices, xlist, pffun, ...
  com_constant, stream_constant, options, cache)
%EVALUATE_BLOCK ワーカーでブロック内タスクを連続実行
% parfeval戦略でワーカーに割り当てられたブロックを処理
%
% 入力:
%   indices - このブロックが処理するインデックス配列
%   xlist - 全断面候補の配列
%   pffun - ペナルティ関数ハンドル
%   com_constant - 共有された共通構造体（Constant）
%   stream_constant - 共有された乱数ストリーム（Constant）
%   options - オプション構造体
%   cache - キャッシュ構造体
% 出力:
%   flist_block - ブロック内の目的関数値
%   clist_block - ブロック内の制約関数値
%   pflist_block - ブロック内のペナルティ付き目的関数値
%   vlist_block - ブロック内の違反量
%   isexec_block - ブロック内の実行フラグ

% オプションから制約数を取得
numc = options.numc;      % 制約関数の数
numvio = options.numvio;  % 制約違反の数
block_size = numel(indices);  % このブロックのサイズ

% 結果配列の事前割当（メモリ効率化）
flist_block = zeros(block_size, 1);
clist_block = zeros(block_size, numc);
pflist_block = zeros(block_size, 1);
vlist_block = zeros(block_size, numvio);
isexec_block = false(block_size, 1);

% 空ブロックの場合は早期リターン
if block_size == 0
  return
end

% Constantから実際の値を取得
com = com_constant.Value;          % 共通構造体
stream = stream_constant.Value;    % 乱数ストリーム

% 現在のグローバル乱数ストリームを保存して切り替え
prev_stream = RandStream.setGlobalStream(stream);

% ブロック内のタスクを順次処理（ワーカー内では並列化しない）
for k = 1:block_size
  idx = indices(k);  % グローバルインデックス

  % タスクごとに異なる乱数系列を使用（再現性の保証）
  % 全戦略で同じSubstreamを使用することで結果の一貫性を保つ
  stream.Substream = idx;

  % 個別評価関数を呼び出し
  [flist_block(k), clist_block(k, :), pflist_block(k), ...
    vlist_block(k, :), isexec_block(k)] = ...
    compute_individual(xlist(idx, :), pffun, com, options, cache);
end

% 元の乱数ストリームに戻す
RandStream.setGlobalStream(prev_stream);
return
end
