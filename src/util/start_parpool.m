function pool = start_parpool(num_workers_spec, maxRetries)
%start_parpool - リトライ付きで並列プールを起動
%
%   pool = start_parpool(num_workers_spec, maxRetries) は、
%   並列プール（parpool）の起動を試行し、失敗時は
%   残存プールを削除して再試行する。
%
%   入力引数:
%     num_workers_spec - ワーカー数の指定（整数または 'N%'）。空なら
%                        MATLAB既定のワーカー数で起動する
%     maxRetries       - 最大リトライ回数 (既定値: 3)
%
%   出力引数:
%     pool - 起動した並列プールオブジェクト
%
%   備考:
%     - 既存プールは、ワーカー数の指定がないか指定と一致すれば
%       そのまま返し、異なれば削除して作り直す
%     - 指定ワーカー数が並列プロファイルの上限（既定は高性能コア数）
%       を超える場合は、上限を指定数まで引き上げて起動する
%     - 全リトライ失敗時は throw_err で
%       YLAB:Parallel:ParpoolFailed エラーを発行

  if nargin < 2
    maxRetries = 3;
  end

  pool = gcp('nocreate');
  if isempty(num_workers_spec)
    if ~isempty(pool)
      return;
    end
    parpool_args = {};
  else
    local_cluster = parcluster(PRM.PARALLEL_PROFILE);
    num_workers = resolve_num_workers(num_workers_spec, ...
      local_cluster.NumWorkers);
    if ~isempty(pool) && pool.NumWorkers == num_workers
      return;
    end
    fprintf('Parallel pool: numworkers=%s -> %d workers (limit %d)\n', ...
      string(num_workers_spec), num_workers, local_cluster.NumWorkers);
    % 上限を超える指定も通すため、プロファイル上限を指定数まで引き上げる
    local_cluster.NumWorkers = max(local_cluster.NumWorkers, num_workers);
    parpool_args = {local_cluster, num_workers};
  end
  delete(pool);

  for attempt = 1:maxRetries
    try
      pool = parpool(parpool_args{:});
      return;
    catch ME
      if attempt < maxRetries
        delete(gcp('nocreate'));
        pause(2);
        fprintf('Parpool failed. Retrying (%d/%d)\n', attempt, maxRetries);
      else
        throw_err('Env', 'ParpoolFailed', ME.message);
      end
    end
  end

  return;
end
