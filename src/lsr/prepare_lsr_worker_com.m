function com = prepare_lsr_worker_com(com, do_parallel)
%prepare_lsr_worker_com - phase確定後のworker配布値を準備する
%
%   com = prepare_lsr_worker_com(com, do_parallel) は、以前のworker
%   キャッシュを除去し、並列実行時は現在phaseのcomを各workerへ
%   一度だけ配布するConstantを生成する。
%
%   入力引数:
%     com - phase確定後の共通構造体
%     do_parallel - 並列実行フラグ
%
%   出力引数:
%     com - worker配布用constantを付加した共通構造体

if isfield(com, 'constant')
  com = rmfield(com, 'constant');
end

if ~do_parallel
  com.constant = [];
  return
end

% parforによる遅延pool生成より先にworker配布値を確定する
gcp();
com.constant = parallel.pool.Constant(com);

return
end
