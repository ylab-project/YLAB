function [pflist, flist, clist, vlist, isexec] = ...
  compute_pflist(pffun, xlist, sdlist, com, options, cache, ...
  evaluation_ids)
%compute_pflist - 候補断面を並列評価
%
%   [pflist, flist, clist, vlist, isexec] = ...
%     compute_pflist(pffun, xlist, sdlist, com, options, cache, ...
%     evaluation_ids) は、候補を逐次・並列で評価する。
%
%   入力引数:
%     pffun          - ペナルティ関数ハンドル
%     xlist          - 候補断面配列 [lsize×nvar]
%     sdlist - xlistと対の写像済み断面寸法 [nsec×7×lsize]
%     com - 共通構造体（worker配布用com.constantを含む）
%     options - オプション構造体（並列戦略、表示設定等）
%     cache   - キャッシュ構造体（既計算結果の再利用）
%     evaluation_ids - 候補ごとの安定したSubstream番号（省略可）
%
%   出力引数:
%     pflist - ペナルティ付き目的関数値 [lsize×1]
%     flist  - 純粋な目的関数値 [lsize×1]
%     clist  - 制約関数値 [lsize×numc]（各行が1断面、各列が1制約）
%     vlist  - 制約違反量 [lsize×numvio]
%     isexec - 解析実行フラグ [lsize×1] (true=新規計算, false=キャッシュ)

% パラメータの取得
numc = options.numc;                          % 制約関数の数（スカラー）
numvio = options.numvio;                      % 制約違反の数（スカラー）
lsize = size(xlist, 1);                       % 評価する断面候補の数
if nargin < 7 || isempty(evaluation_ids)
  evaluation_ids = (1:lsize)';
end
if isfield(com, 'constant')
  use_worker_cache = isa(com.constant, 'parallel.pool.Constant');
else
  use_worker_cache = false;
end

% 出力配列を事前割当（メモリ効率化）
flist = zeros(lsize, 1);                      % 目的関数値 [lsize×1]
pflist = zeros(lsize, 1);             % ペナルティ付き [lsize×1]
clist = zeros(lsize, numc);                   % 制約関数値 [lsize×numc]
vlist = zeros(lsize, numvio);                 % 制約違反量 [lsize×numvio]
isexec = false(lsize, 1);                     % 実行フラグ [lsize×1]

% 空配列の場合は早期リターン
if lsize == 0
  return
end

%% 並列実行戦略の決定と実行
% タスク数とワーカー数に基づいて最適な戦略を自動選択
strategy = resolve_strategy(options, lsize);

% 表示モードの取得（進捗表示用）
display_mode = '';
if isfield(options, 'display')
  display_mode = char(options.display);
end

% 選択された戦略に応じて評価を実行
switch strategy
  case 'sequential'
    % 逐次実行：並列化なし、小規模タスク向け
    % fprintf('  strategy=sequential: lsize=%d\n', lsize);
    evaluate_sequential();

  case 'parfor'
    % parfor並列実行：中規模タスク向け（細粒度並列化）
    pool = gcp('nocreate');
    nworkers = 0;
    if ~isempty(pool)
      nworkers = pool.NumWorkers;
    end
    % fprintf('  parfor stat: lsize=%d workers=%d\n', lsize, nworkers);
    evaluate_parfor();

  case 'parfeval'
    % parfeval並列実行：大規模タスク向け（ブロック化による効率化）
    evaluate_parfeval();

  otherwise
    error('compute_pflist:UnknownStrategy', ...
      '不明な並列戦略: %s', strategy);
end

return

  function evaluate_sequential()
  %evaluate_sequential - 候補を逐次評価して外側の結果配列へ格納する
  %
  %   evaluate_sequential() は、
  %   候補を逐次評価して外側の結果配列へ格納する。
  %
  %   入力引数:
  %     なし（外側の lsize, xlist, sdlist, evaluation_ids, pffun, com,
  %     options, cache を参照）
  %
  %   出力引数:
  %     なし（外側の flist, clist, pflist, vlist, isexec を更新）
  %
  %   備考:
  %     単一の乱数ストリームを使用して順番に各断面を評価。
  %     タスクごとにSubstreamを設定して再現性を保証する。

  % Threefry乱数生成器を作成（高速かつ並列化に適した生成器）
  stream = RandStream('Threefry');
  prev_stream = RandStream.setGlobalStream(stream);

  % 各候補断面を順次評価
  for id = 1:lsize
    % タスクIDごとに異なる乱数系列を使用（再現性の保証）
    stream.Substream = evaluation_ids(id);

    [flist(id), clist(id, :), pflist(id), vlist(id, :), ...
      isexec(id)] = compute_individual(xlist(id, :), ...
      sdlist(:, :, id), pffun, com, options, cache);
  end

  % 元の乱数ストリームに戻す
  RandStream.setGlobalStream(prev_stream);
  return
  end

  function evaluate_parfor()
  %evaluate_parfor - 候補をparforで評価して外側の結果配列へ格納する
  %
  %   evaluate_parfor() は、
  %   候補をparforで評価して外側の結果配列へ格納する。
  %
  %   入力引数:
  %     なし（外側の lsize, xlist, sdlist, evaluation_ids, pffun, com,
  %     options, cache, use_worker_cache を参照）
  %
  %   出力引数:
  %     なし（外側の flist, clist, pflist, vlist, isexec を更新）
  %
  %   備考:
  %     各ワーカーに独立した乱数ストリームを供給し、細粒度並列化。
  %     Substreamによりタスク間の乱数系列の独立性を保証する。

  % ワーカーごとに乱数ストリームを作成（遅延評価）
  stream_constant = parallel.pool.Constant(@() RandStream('Threefry'));

  % ワーカー数の取得
  pool = gcp('nocreate');
  nworkers = 0;
  if ~isempty(pool)
    nworkers = pool.NumWorkers;
  end
  if nworkers > 0
    % fprintf('  parfor: lsize=%d workers=%d tasks/w=%.2f\n', ...
    %   lsize, nworkers, lsize / nworkers);
  else
    % fprintf('  strategy=parfor: lsize=%d workers=%d\n', lsize, nworkers);
  end

  if ~use_worker_cache
    parfor id = 1:lsize
      stream = stream_constant.Value;
      prev_stream = RandStream.setGlobalStream(stream);
      stream.Substream = evaluation_ids(id);
      [flist(id), clist(id, :), pflist(id), vlist(id, :), ...
        isexec(id)] = compute_individual(xlist(id, :), ...
        sdlist(:, :, id), pffun, com, options, cache);
      RandStream.setGlobalStream(prev_stream);
    end
  else
    worker_com_cache = com.constant;
    parfor id = 1:lsize
      stream = stream_constant.Value;
      prev_stream = RandStream.setGlobalStream(stream);
      stream.Substream = evaluation_ids(id);
      worker_com = worker_com_cache.Value; %#ok<PFBNS>
      [flist(id), clist(id, :), pflist(id), vlist(id, :), ...
        isexec(id)] = compute_individual(xlist(id, :), ...
        sdlist(:, :, id), pffun, worker_com, options, cache);
      RandStream.setGlobalStream(prev_stream);
    end
  end

  return
  end

  function evaluate_parfeval()
  %evaluate_parfeval - 候補をブロックへ分けてparfevalで評価する
  %
  %   evaluate_parfeval() は、
  %   候補をブロックへ分けてparfevalで評価する。
  %
  %   入力引数:
  %     なし（外側の lsize, xlist, sdlist, evaluation_ids, pffun,
  %     com, options, cache, use_worker_cache, display_mode を参照）
  %
  %   出力引数:
  %     なし（外側の flist, clist, pflist, vlist, isexec を更新）
  %
  %   備考:
  %     タスクをワーカー数分のブロックに分割して並列実行。
  %     通信オーバーヘッドを削減し、大規模タスクで高効率を実現。

  % 並列プールとワーカー数を取得
  pool = gcp();
  num_workers = pool.NumWorkers;

  % タスクをワーカー数分のブロックに均等分割
  blocks_all = partition_indices(lsize, num_workers);

  % 空でないブロックのみ抽出（タスク数<ワーカー数の場合）
  is_active = ~cellfun(@isempty, blocks_all);
  blocks = blocks_all(is_active);
  num_blocks = numel(blocks);

  % ブロックがない場合は早期リターン
  if num_blocks == 0
    return
  end

  % 直接呼出しでもpool生成後のworkerキャッシュを保証する
  if use_worker_cache
    worker_com_cache = com.constant;
  else
    worker_com = com;
    if isfield(worker_com, 'constant')
      worker_com = rmfield(worker_com, 'constant');
    end
    worker_com_cache = parallel.pool.Constant(worker_com);
  end
  stream_constant = parallel.pool.Constant(@() RandStream('Threefry'));

  % 並列タスク管理用の配列を準備
  futures = parallel.FevalFuture.empty(num_blocks, 0); % Future配列
  start_times = cell(num_blocks, 1);                   % 開始時刻
  durations = zeros(num_blocks, 1);                    % 実行時間
  % block_sizes = cellfun(@numel, blocks);
  % fprintf('  parfeval: lsize=%d blk=%d sz=[%d..%d] rng=%d\n', ...
  %   lsize, num_blocks, min(block_sizes), ...
  %   max(block_sizes), max(block_sizes) - min(block_sizes));

  % 各ブロックをワーカーに非同期投入
  for iw = 1:num_blocks
    start_times{iw} = tic;
    futures(iw) = parfeval(pool, @evaluate_block, 5, ...
      xlist(blocks{iw}, :), sdlist(:, :, blocks{iw}), ...
      evaluation_ids(blocks{iw}), pffun, worker_com_cache, ...
      stream_constant, options, cache);
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

  % 実行時間を表示（デバッグ用）
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
  %resolve_strategy - 候補数とワーカー数から実行方式を選ぶ
  %
  %   strategy = resolve_strategy(options_, lsize_) は、
  %   候補数とワーカー数から実行方式を選ぶ。
  %
  %   入力引数:
  %     options_ - 並列実行のオプション
  %     lsize_ - 評価する候補の数
  %
  %   出力引数:
  %     strategy - 逐次・parfor・parfevalの実行方式
  %
  %   備考:
  %     autoでは候補数とワーカー数から方式を選ぶ。
  %     parallel_block_factor以上の候補/ワーカーでparfevalとする。

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
        '不明な並列戦略: %s（auto/sequential/parfor/parfeval）', ...
        requested);
  end

  return
  end
end

%--------------------------------------------------------------------------
function [fval, cvec, pfval, vio, isexec] = compute_individual( ...
  xvar, secdim, pffun, com, options, cache)
%compute_individual - 単一の候補断面を評価
%
%   [fval, cvec, pfval, vio, isexec] = compute_individual( ...
%     xvar, secdim, pffun, com, options, cache) は、保存済みの値を
%   再利用し、未評価の候補だけを解析する。
%
%   入力引数:
%     xvar    - 設計変数ベクトル [1×nvar]
%     secdim  - xvarと対の写像済み断面寸法 [nsec×7]
%     pffun   - ペナルティ関数ハンドル
%     com     - 共通構造体
%     options - オプション構造体
%     cache   - キャッシュ構造体
%
%   出力引数:
%     fval   - 目的関数値（スカラー）
%     cvec   - 制約関数値 [1×numc]
%     pfval  - ペナルティ付き目的関数値（スカラー）
%     vio    - 制約違反量 [1×numvio]
%     isexec - 実行フラグ（true=新規計算, false=キャッシュ）

% キャッシュ検索
id = [];
isexec = false;
if options.do_cache && ~isempty(cache.xlist)
  % 最近傍点を高速検索（ユークリッド距離の2乗）
  [ddd, iddd] = pdist2(cache.xlist, xvar, ...
    'fastsquaredeuclidean', 'Smallest', 1);
  iscached = (ddd == 0);  % 完全一致の確認
  if any(iscached)
    % キャッシュヒット：保存済み結果を再利用
    id = iddd(iscached);
    id = id(1);
    fval = cache.flist(id);
    cvec = cache.clist(id, :);
  end
end

% キャッシュミスの場合は新規計算
if isempty(id)
  com = update_frame_data(secdim, com, options);
  cvec = analysis_constraint(xvar, secdim, com, options);
  fval = objective_lsr(secdim, com.secmgr, com.node, ...
    com.section, com.member, com.floor);
  isexec = true;
end

% ペナルティ関数の適用
[pfval, vio] = pffun(fval, cvec);
return
end

%--------------------------------------------------------------------------
function blocks = partition_indices(total_size, num_workers)
%partition_indices - タスクをワーカー数分のブロックに均等分割
%
%   blocks = partition_indices(total_size, num_workers) は、
%   タスクを均等に分け、余りを先頭側のワーカーへ配る。
%
%   入力引数:
%     total_size  - 総タスク数（スカラー整数）
%     num_workers - ワーカー数（スカラー整数）
%
%   出力引数:
%     blocks - ブロックのインデックス配列 {num_workers×1} cell配列

% 入力検証
validateattributes(total_size, {'numeric'}, ...
  {'scalar', 'positive', 'integer'});
validateattributes(num_workers, {'numeric'}, ...
  {'scalar', 'positive', 'integer'});

% 基本サイズと余りを計算
base_size = floor(total_size / num_workers);   % 各ワーカーの基本タスク数
remainder = mod(total_size, num_workers);      % 余りタスク数

% ブロックサイズの配列を作成（余りを前方に配分）
block_sizes = repmat(base_size, num_workers, 1);
block_sizes(1:remainder) = block_sizes(1:remainder) + 1;

% 開始・終了インデックスを計算
end_indices = cumsum(block_sizes);
start_indices = [1; end_indices(1:end - 1) + 1];

% 各ブロックのインデックス範囲を生成
blocks = cell(num_workers, 1);
for w = 1:num_workers
  blocks{w} = start_indices(w):end_indices(w);
end

return
end

%--------------------------------------------------------------------------
function [flist_block, clist_block, pflist_block, vlist_block, ...
  isexec_block] = evaluate_block(xlist, sdlist, evaluation_ids, ...
  pffun, worker_com_cache, stream_constant, options, cache)
%evaluate_block - ワーカーでブロック内タスクを連続実行
%
%   [flist_block, clist_block, pflist_block, vlist_block, ...
%     isexec_block] = evaluate_block(xlist, sdlist, evaluation_ids, ...
%     pffun, worker_com_cache, stream_constant, options, cache) は、
%   同じワーカー内で候補を順に評価する。
%
%   入力引数:
%     xlist - このブロックが処理する候補配列
%     sdlist - ブロック内候補の写像済み断面寸法
%     evaluation_ids - ブロック内候補のSubstream番号
%     pffun - ペナルティ関数ハンドル
%     worker_com_cache - worker配布用の共通構造体キャッシュ
%     stream_constant - 共有された乱数ストリーム（Constant）
%     options - オプション構造体
%     cache - キャッシュ構造体
%
%   出力引数:
%     flist_block - ブロック内の目的関数値
%     clist_block - ブロック内の制約関数値
%     pflist_block - ブロック内のペナルティ付き目的関数値
%     vlist_block - ブロック内の違反量
%     isexec_block - ブロック内の実行フラグ

% オプションから制約数を取得
numc = options.numc;      % 制約関数の数
numvio = options.numvio;  % 制約違反の数
block_size = size(xlist, 1);  % このブロックのサイズ

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
com = worker_com_cache.Value;      % 共通構造体
stream = stream_constant.Value;    % 乱数ストリーム

% 現在のグローバル乱数ストリームを保存して切り替え
prev_stream = RandStream.setGlobalStream(stream);

% ブロック内のタスクを順次処理（ワーカー内では並列化しない）
for k = 1:block_size
  % タスクごとに異なる乱数系列を使用（再現性の保証）
  % 全戦略で同じSubstreamを使用することで結果の一貫性を保つ
  stream.Substream = evaluation_ids(k);

  [flist_block(k), clist_block(k, :), ...
    pflist_block(k), vlist_block(k, :), isexec_block(k)] = ...
    compute_individual(xlist(k, :), sdlist(:, :, k), pffun, ...
    com, options, cache);
end

% 元の乱数ストリームに戻す
RandStream.setGlobalStream(prev_stream);
return
end