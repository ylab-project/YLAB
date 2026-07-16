function best = select_best_lsr_history(histories, trial_ids, max_idphase)
%select_best_lsr_history - 全trial・全phaseのLSR履歴から最良解を選ぶ
%
%   best = select_best_lsr_history(histories, trial_ids, max_idphase) は、
%   各trialについて指定phaseまでの初期点と採用履歴から最良解を選び、
%   trialごとの最良解を同じ基準で比較する。
%
%   入力引数:
%     histories   - trial×phaseのLSR履歴構造体配列
%     trial_ids   - 比較対象のtrial番号
%     max_idphase - 比較対象とする最大phase番号
%
%   出力引数:
%     best - 最良解と選択元を格納した構造体

best = struct([]);
trial_ids = unique(trial_ids);
for idtrial = trial_ids(:)'
  trial_best = struct([]);
  for idphase = 1:max_idphase
    if idtrial > size(histories, 1) || idphase > size(histories, 2)
      continue
    end
    history = histories(idtrial, idphase);
    trial_best = select_history_initial(trial_best, history, ...
      idtrial, idphase);
    trial_best = select_history_iterations(trial_best, history, ...
      idtrial, idphase);
  end
  best = select_better(best, trial_best);
end
if isempty(best)
  error('select_best_lsr_history:NoResult', ...
    'No valid result exists in the specified LSR histories.');
end

return
end

function best = select_history_initial(best, history, idtrial, idphase)
%select_history_initial - phase初期点を選択候補へ加える

if ~isfield(history, 'initial') || isempty(history.initial) ...
    || ~isfield(history.initial, 'xvar')
  return
end
candidate = create_candidate(history.initial.xvar, ...
  history.initial.fval, history.initial.vio, idtrial, idphase, 0);
best = select_better(best, candidate);

return
end

function best = select_history_iterations(best, history, idtrial, idphase)
%select_history_iterations - phaseの採用履歴を選択候補へ加える

required = {'xvar', 'fval', 'vio'};
if ~all(isfield(history, required)) || isempty(history.xvar)
  return
end
candidate_count = min([size(history.xvar, 1), numel(history.fval), ...
  size(history.vio, 1)]);
for index = 1:candidate_count
  candidate = create_candidate(history.xvar(index, :), ...
    history.fval(index), history.vio(index, :), idtrial, idphase, ...
    index);
  best = select_better(best, candidate);
end

return
end

function candidate = create_candidate(xvar, fval, vio, idtrial, ...
    idphase, history_index)
%create_candidate - LSR履歴値から比較用候補を生成する

maxvio = max(vio, [], 2);
if isempty(xvar) || ~isscalar(fval) || ~isscalar(maxvio) ...
    || ~isfinite(fval) || ~isfinite(maxvio)
  candidate = struct([]);
  return
end
candidate = struct('xvar', xvar, 'fval', fval, 'maxvio', maxvio, ...
  'idtrial', idtrial, 'idphase', idphase, 'history_index', ...
  history_index);

return
end

function best = select_better(best, candidate)
%select_better - 許容性・目的関数値・違反量の順で候補を比較する

if isempty(candidate)
  return
end
if isempty(best) || is_better(candidate, best)
  best = candidate;
end

return
end

function tf = is_better(candidate, current)
%is_better - candidateがcurrentより良いかを判定する

candidate_feasible = candidate.maxvio <= PRM.TOL_MAX_VIOLATION;
current_feasible = current.maxvio <= PRM.TOL_MAX_VIOLATION;
if candidate_feasible ~= current_feasible
  tf = candidate_feasible;
  return
end
if candidate_feasible
  candidate_rank = [candidate.fval candidate.maxvio];
  current_rank = [current.fval current.maxvio];
else
  candidate_rank = [candidate.maxvio candidate.fval];
  current_rank = [current.maxvio current.fval];
end
tf = candidate_rank(1) < current_rank(1) ...
  || (candidate_rank(1) == current_rank(1) ...
  && candidate_rank(2) < current_rank(2));

return
end