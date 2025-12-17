function [x, fval, exitflag, com] = call_lsr(com, options)
% --- common ---
lm = com.member.property.lm;
secmgr = com.secmgr;
section = com.section;
member = com.member;
baseline = com.baseline;
node = com.node;
story = com.story;
floor = com.floor;
max_idphase = min(options.maxphase,2);

% 上下限値
lb = secmgr.lb;
ub = secmgr.ub;

% 履歴準備
trials = [];
trials_history = [];
xopt = [];

% 履歴読み込み
if ~isempty(options.matfile)
  resume = load(options.matfile, 'history');
end

% 初期ペナルティ係数
options.idphase = max_idphase;
fub = objective_lsr(ub, secmgr, baseline, node, section, member, story, floor, options);
flb = objective_lsr(lb, secmgr, baseline, node, section, member, story, floor, options);
f0 = (fub+flb)/2;
% mu = (fub+flb)/200;
% mu = (fub+flb)/2*options.mu0;
% options.mu = mu;

% 初期解
if ~isempty(options.x0)
  x0 = options.x0;
end

% --- Local Search ---
iter_set = options.iter_set;
if isfinite(options.idtrial_resume)
  iter_set = iter_set(iter_set>=options.idtrial_resume);
end
for idtrial = iter_set
  rng(idtrial);

  % 履歴ファイル読み込み
  if (options.idtrial_resume == idtrial && exist('resume','var'))
    [x0, history] = load_trial;
    start_idphase = options.idphase_resume;
  else
    % ランダム初期解生成
    if idtrial>1 || isempty(options.x0)
      x0 = secmgr.generateRandomXvar(idtrial, lm, options);
    end
    history = [];
    start_idphase = 1;
  end
  for idphase = start_idphase:max_idphase
    options.idtrial = idtrial;
    options.idphase = idphase;
    options.mu = f0*options.mu0(options.idphase);
    if (idphase~=options.idphase_resume)
      if (idphase>1)
        x0 = xopt;
      end
      history = [];
    end
    [xopt, fval, exitflag, history] = lsr(x0, com, history, options);
    save_trial
  end
end

% 最良解の選択
bestid = select_best_solution;
x = trials.xopt(:,bestid,max_idphase);
fval = trials.fval(bestid,max_idphase);
return
%--------------------------------------------------------------------------
  function save_trial
    if isempty(options.historyfile)
      return
    end
    if isempty(trials)
      trial_filename = options.historyfile;
      trials = matfile(trial_filename, 'Writable', true);
    end
    n1 = max(options.iter_set);
    n2 = max_idphase;
    nx = size(xopt,2);
    if isempty(trials_history)
      trials_history = struct(history);
      trials_history(n1,n2) = struct(history);
    end
    if isempty(who(trials))
      trials.x0 = nan(nx, n1, n2);
      trials.xopt = nan(nx, n1, n2);
      trials.fval = nan(n1, n2);
      trials.iter = nan(n1, n2);
      trials.time = nan(n1, n2);
      trials.maxvio = nan(n1, n2);
      trials.nexec = nan(n1, n2);
    end
    n_ = length(history.iter);
    if n2==1
      trials.x0(:, idtrial) = x0(:);
      trials.xopt(:, idtrial) = xopt(:);
    else
      trials.x0(:, idtrial, idphase) = x0(:);
      trials.xopt(:, idtrial, idphase) = xopt(:);
    end
    trials.fval(idtrial, idphase) = fval;
    trials.iter(idtrial, idphase) = history.iter(n_);
    trials.time(idtrial, idphase) = history.time(n_);
    trials.maxvio(idtrial, idphase) = history.maxvio;
    trials.nexec(idtrial, idphase) = history.nexec(n_);
    trials_history(idtrial, idphase) = history;
    trials.history = trials_history;
  end
%--------------------------------------------------------------------------
  function [x0, history] = load_trial
    idtrial_ = options.idtrial_resume;
    idphase_ = options.idphase_resume;
    iter_ = options.iter_resume;
    history = resume.history(idtrial_, idphase_);   
    x0 = resume.history(idtrial_, idphase_).xvar(history.iter==iter_, :);
      return
  end
%--------------------------------------------------------------------------
  function bestid = select_best_solution
    % 最良解の選択
    [fval, bestid] = min(trials.fval(:,max_idphase));

    % 最良解が許容なら選択修了
    if trials.maxvio(bestid,max_idphase)<1.e-4
      return
    end

    % 最良解が非許容解の場合
    isfeasible = trials.maxvio(:,max_idphase)<=1.e-4;
    fff = trials.fval(:,max_idphase);
    fff(~isfeasible) = inf;
    [~, bestid] = min(fff);
    if ~isempty(bestid)
      % 許容な最良解を選択
      return
    end
    
    % 許容解が存在しない場合
    [~, bestid] = min(trials.maxvio(:,max_idphase));
end
end

