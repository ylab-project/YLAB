function pool = start_parpool(num_workers_spec, maxRetries)
%start_parpool - リトライ付きで並列プールを起動する
%
%   pool = start_parpool(num_workers_spec, maxRetries) は、指定した
%   ワーカー数で並列プールを起動する。失敗時は残存プールを削除し、
%   再試行する。
%
%   入力引数:
%     num_workers_spec - ワーカー数の指定（整数または 'N%'）
%                        空は '100%' と同じ。割合の分母はPコアと
%                        Eコアを含む有効物理コア数
%     maxRetries       - 最大リトライ回数 (既定値: 3)
%
%   出力引数:
%     pool - 起動した並列プールオブジェクト
%
%   備考:
%     - 既存プールのワーカー数が指定と一致すればそのまま返し、
%       異なれば削除して作り直す
%     - クラスタの上限を指定数まで引き上げるが、保存はしない
%     - 全リトライ失敗時は YLAB:Env:ParpoolFailed で停止する

if nargin < 2
  maxRetries = 3;
end
if isempty(num_workers_spec)
  num_workers_spec = '100%';
end
[num_workers, num_cores] = resolve_num_workers(num_workers_spec);
pool = gcp('nocreate');
if ~isempty(pool) && pool.NumWorkers == num_workers
  return
end
local_cluster = parcluster(PRM.PARALLEL_PROFILE);
fprintf(['並列プール: numworkers=%s → %dワーカー' ...
  '（有効物理コア数%d）\n'], string(num_workers_spec), ...
  num_workers, num_cores);
% 上限を超える指定も通すため、クラスタの上限を指定数まで引き上げる
local_cluster.NumWorkers = max(local_cluster.NumWorkers, num_workers);
delete(pool);

for attempt = 1:maxRetries
  try
    pool = parpool(local_cluster, num_workers);
    return
  catch ME
    if attempt < maxRetries
      delete(gcp('nocreate'));
      pause(2);
      fprintf('並列プールの起動失敗。再試行 (%d/%d)\n', ...
        attempt, maxRetries);
    else
      throw_err('Env', 'ParpoolFailed', ME.message);
    end
  end
end

return
end
