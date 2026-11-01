function [x, fval, com] = call_ga(com, options)
%call_ga - 整数化した設計変数で遺伝的アルゴリズムを実行する
%
%   [x, fval, com] = call_ga(com, options) は、
%   整数化した設計変数で遺伝的アルゴリズムを実行する。
%
%   入力引数:
%     com - 架構・断面・材料を含む共通データ
%     options - 解析・探索・出力のオプション
%
%   出力引数:
%     x - 設計変数ベクトル
%     fval - 目的関数値
%     com - 架構・断面・材料を含む共通データ
%

% --- common ---
secmgr = com.secmgr;

% 初期断面での部材長を算出
secdim0 = secmgr.findNearestSection(secmgr.ub, options);
com = update_frame_data(secdim0, com, options);
lm = calc_member_length_from_node(com.node, ...
  [com.member.property.idnode1 com.member.property.idnode2]);

% 初期解
if ~isempty(options.x0)
  x0 = options.x0;
else
  x0 = secmgr.generateRandomXvar(0, com.member, lm, options);
end
x0 = x0(:)';
cvec0 = analysis_constraint_xvar(x0, com, options);

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
  x = int2x(intx);
  toc;

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
  %objfun - 整数候補を断面寸法へ写像して目的関数を評価する
  %
  %   fval = objfun(intxmat) は、
  %   整数候補を断面寸法へ写像して目的関数を評価する。
  %
  %   入力引数:
  %     intxmat - 候補番号の行列
  %     （外側の nvar, stvals, com, options を参照）
  %
  %   出力引数:
  %     fval - 目的関数値

    npop = size(intxmat,1);
    xmat = zeros(npop,nvar);
    for i=1:npop
      xmat(i,:) = int2x(intxmat(i,:));
    end
    fval = zeros(npop,1);
    parfor i=1:npop
      fval(i) = objective_lsr_xvar(xmat(i,:), com, options);
    end
    return
  end
%--------------------------------------------------------------------------
  function [c, ceq] = nonlcon(intxmat)
  %nonlcon - 整数候補を断面寸法へ写像して制約を評価する
  %
  %   [c, ceq] = nonlcon(intxmat) は、
  %   整数候補を断面寸法へ写像して制約を評価する。
  %
  %   入力引数:
  %     intxmat - 候補番号の行列
  %     （外側の nvar, nc, stvals, com, options を参照）
  %
  %   出力引数:
  %     c - 不等式制約値
  %     ceq - 等式制約値（空配列）

    npop = size(intxmat,1);
    xmat = zeros(npop,nvar);
    for i=1:npop
      xmat(i,:) = int2x(intxmat(i,:));
    end
    c = zeros(npop,nc);
    parfor i=1:npop
      c(i,:) = analysis_constraint_xvar(xmat(i,:), com, options);
    end
    % c = c*1000;
    ceq = [];
    % fprintf('%f\n',min(max(c,[],2)));
    return
  end
%--------------------------------------------------------------------------
  function intx = x2int(x)
  %x2int - 設計変数を候補リストの番号へ変換する
  %
  %   intx = x2int(x) は、
  %   設計変数を候補リストの番号へ変換する。
  %
  %   入力引数:
  %     x - 設計変数ベクトル
  %     （外側の nvar, stvals を参照）
  %
  %   出力引数:
  %     intx - 設計変数に対応する候補番号

    intx = zeros(1,nvar);
    for i=1:nvar
      [~, id] = min(abs(stvals(i,:)-x(i)));
      intx(i) = id;
    end

    return
  end
%--------------------------------------------------------------------------
  function x = int2x(intx)
  %int2x - 候補リストの番号を設計変数へ戻す
  %
  %   x = int2x(intx) は、
  %   候補リストの番号を設計変数へ戻す。
  %
  %   入力引数:
  %     intx - 設計変数に対応する候補番号
  %     （外側の nvar, stvals を参照）
  %
  %   出力引数:
  %     x - 設計変数ベクトル

    x = zeros(1,nvar);
    for i=1:nvar
      x(i) = stvals(i,intx(i));
    end

    return
  end
end
