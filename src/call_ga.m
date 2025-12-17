function [x, fval, com] = call_ga(com, options)
% --- common ---
lm = com.member.property.lm;
secmgr = com.secmgr;
member = com.member;
node = com.node;
story = com.story;
floor = com.floor;

% 初期解
if ~isempty(options.x0)
  x0 = options.x0;
else
  x0 = secmgr.generateRandomXvar(0, lm, options);
end
x0 = x0(:)';
cvec0 = analysis_constraint(x0, com, options);

% サイズ
nvar = com.nvar;
nc = length(cvec0);

% 断面寸法規格値
stvals = secmgr.getStandardValues();

% 上下限値
lb = secmgr.lb;
ub = secmgr.ub;

% 整数変換
intlb = x2int(lb);
intub = x2int(ub);
intx0 = x2int(x0);

% 画面出力
switch options.display
  case 'Iter'
    display_mode = 'iter';
  case 'None'
    display_mode = 'off';
  otherwise
    display_mode = 'final';
end
    
% GA計算条件
gaoptions = optimoptions('ga');
gaoptions = optimoptions(gaoptions, 'InitialPopulationMatrix', intx0);
gaoptions = optimoptions(gaoptions, 'UseVectorized', true);
gaoptions = optimoptions(gaoptions, 'Display', display_mode);
% gaoptions = optimoptions(gaoptions, 'PopulationSize', 200);
% gaoptions = optimoptions(gaoptions, 'MaxGenerations', 500);
% gaoptions = optimoptions(gaoptions, 'InitialPenalty', 1e8);
% gaoptions = optimoptions(gaoptions, 'PlotFcn', @gaplotbestf);

% 問題作成
prob.solver = 'ga';
prob.fitnessfcn = @objfun;
prob.nvars = nvar;
prob.Aineq = [];	
prob.Bineq	= [];
prob.Aeq	= [];
prob.Beq	= [];
prob.lb	= intlb;
prob.ub	= intub;
prob.nonlcon =@nonlcon;
prob.intcon = 1:nvar;
% prob.rngstate	= [];
prob.options = gaoptions;

% GA
fbest = inf;
for iter = options.iter_set
  tic;
  rng(iter);
  [intx, fval] = ga(prob);
  x = int2x(intx)
  time = toc

  % 結果の更新
  if fval<fbest
    fbest = fval;
    xbest = x;
  end
end

% 結果の保存
x = xbest;
fval = fbest;
return
%--------------------------------------------------------------------------
  function fval = objfun(intxmat)
    npop = size(intxmat,1);
    xmat = zeros(npop,nvar);
    for i=1:npop
      xmat(i,:) = int2x(intxmat(i,:));
    end
    fval = zeros(npop,1);
    parfor i=1:npop
      fval(i) = objective_lsr(xmat(i,:), ...
        lm, secmgr, node, member, story, floor, options);
    end
    return
  end
%--------------------------------------------------------------------------
  function [c, ceq] = nonlcon(intxmat)
    npop = size(intxmat,1);
    xmat = zeros(npop,nvar);
    for i=1:npop
      xmat(i,:) = int2x(intxmat(i,:));
    end
    c = zeros(npop,nc);
    parfor i=1:npop
      c(i,:) = analysis_constraint(xmat(i,:), com, options);
    end
    % c = c*1000;
    ceq = [];
    % fprintf('%f\n',min(max(c,[],2)));
    return
  end
%--------------------------------------------------------------------------
  function intx = x2int(x)
    intx = zeros(1,nvar);
    for i=1:nvar
      [~, id] = min(abs(stvals(i,:)-x(i)));
      intx(i) = id;
    end
  end
%--------------------------------------------------------------------------
  function x = int2x(intx)
    x = zeros(1,nvar);
    for i=1:nvar
      x(i) = stvals(i,intx(i));
    end
  end
end
