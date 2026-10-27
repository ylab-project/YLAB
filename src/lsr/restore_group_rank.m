function [xlist, sdlist] = restore_group_rank(xvar0, secdim0, ...
  Qm, com, options, conwt, drank, Fs, isSNsec, grank, crank, is_wtcon)
%restore_group_rank - 群種別を改善する組合せ候補を整数計画で作る
%
%   [xlist, sdlist] = restore_group_rank( ...
%     xvar0, secdim0, Qm, com, options, conwt, drank, Fs, isSNsec,
%     grank, crank, is_wtcon) は、
%   復元元の水平力と材料を固定して幅厚比と群割合を改善し、
%   固定変数を維持した候補を求解後に一度だけ写像する。
%
%   入力引数:
%     xvar0, secdim0 - 復元元の設計変数と写像済み断面の組
%     Qm            - 復元元の部材水平力 [nme×nlc] (N)
%     com           - 部材・断面・階・設計変数の情報
%     options       - 共通オプション
%     conwt, drank  - 復元元の幅厚比制約と種別 [nsrep×1]
%     Fs, isSNsec   - 復元元の材料F値とSN材判定 [nsec×1]
%     grank, crank, is_wtcon - 実効要求種別と対象 [nsec×1]
%
%   出力引数:
%     xlist  - 整数計画で選んだ設計変数 [nlist×nx]
%     sdlist - xlistと対の断面寸法 [nsec×7×nlist]

xlist = zeros(0, numel(xvar0));
sdlist = secdim0(:, :, []);
if ~options.coptions.consider_group_rank
  return
end
mp = com.member.property;
idfl = find(ismember(com.floor.rank_group, ...
  [PRM.GROUP_RANK_A PRM.GROUP_RANK_B]));
idme = find(any(ismember(mp.idfloor, idfl), 2) & ...
  ismember(mp.section_type, [PRM.WFS PRM.HSS PRM.CWFS PRM.CWFSI]));
idme = get_group_rank_members(com, idme);
if isempty(idme)
  return
end
ids = unique(com.section.property.idsrep(mp.idsec(idme)));
idsrep2s = com.section.representative.idsec;
idm2srep = com.section.property.idsrep(mp.idsec);
[confa, confc, rankmember0] = calc_group_rank(com, drank(idm2srep), Qm);
if all([confa; confc; conwt(ids)] <= options.tau)
  return
end

[cands, xrows, wrows, rrows] = create_wtratio_candidates( ...
  xvar0, secdim0, idsrep2s(ids), com, options, Fs, isSNsec, ...
  grank, crank, is_wtcon);
xvar = solve_candidates(xvar0, cands, xrows, wrows, rrows, ...
  Qm, com, options);
if isempty(xvar) || isequal(xvar, xvar0)
  return
end
initial_guess = struct('x', xvar0, 'secdim', secdim0);
xlist = xvar;
sdlist = com.secmgr.findNearestSectionList(xlist, options, ...
  initial_guess, com);

% 写像後は候補の材料で再判定し、新たなFDへの悪化を除く。
[candidate_Fs, candidate_isSNsec] = ...
  get_section_material_properties(sdlist(:, :, 1), com);
[~, candidate_drank] = eval_section_wtratio(sdlist(:, :, 1), com, ...
  options, candidate_Fs, candidate_isSNsec, grank, crank, is_wtcon);
[~, ~, rankmember] = calc_group_rank(com, candidate_drank(idm2srep), Qm);
if any(rankmember0 > PRM.RANK_NONE & ...
    rankmember0 <= PRM.MEMBER_RANK_FC & ...
    rankmember == PRM.MEMBER_RANK_FD)
  xlist = zeros(0, numel(xvar0));
  sdlist = secdim0(:, :, []);
end

return
end

function xvar = solve_candidates(xvar0, cands, xrows, wrows, rrows, ...
  Qm, com, options)
%solve_candidates - 候補選択と種別補正を二段階の整数計画で解く
%
%   xvar = solve_candidates(xvar0, cands, xrows, wrows, rrows,
%     Qm, com, options) は、超過量を先に減らし、その到達値を
%   上限として相対寸法変更量を最小化する。
%
%   入力引数:
%     xvar0         - 復元元の設計変数 [1×nx]
%     cands, xrows  - 変数候補値と代表断面ごとの候補行
%     wrows, rrows  - 候補行の幅厚比制約と補正前種別
%     Qm            - 復元元の部材水平力 (N)
%     com, options  - 共通データとオプション
%
%   出力引数:
%     xvar - 選択した設計変数（候補なしは0行）

xvar = zeros(0, numel(xvar0));
idsrep2s = com.section.representative.idsec;
idm2s = com.section.property.idsrep(com.member.property.idsec);
nrows = cellfun(@numel, rrows);
iz = cumsum([0; nrows]);
nvals = cellfun(@numel, cands);
iy = iz(end) + cumsum([0; nvals]);
[Dmat, idm2rank] = rank_dependencies(com, rrows);
nrank = size(Dmat, 1);
nq = 3 * nrank;
iq = reshape(iy(end) + (1:nq), nrank, 3);
ni = iy(end) + nq;
[Gmat, g0] = group_coefficients(Dmat, idm2rank, idm2s, rrows, Qm, com);
ng = numel(g0);
N = ni + ng;
f = zeros(N, 1);
delta = zeros(N, 1);
y0 = zeros(N, 1);
rank0 = zeros(numel(idsrep2s), 1);

% 断面の行と共有変数の値をそれぞれ一つ選び、両者を一致させる。
neq = numel(rrows) + numel(cands);
for is = 1:numel(rrows)
  if rrows{is}(1) == PRM.RANK_NONE
    continue
  end
  idv = unique(nonzeros(com.secmgr.idsrep2var(is, :)));
  neq = neq + sum(nvals(idv));
end
eqcell = cell(neq, 1);
beq = zeros(neq, 1);
ieq = 0;
for iv = 1:numel(cands)
  ids = iy(iv) + (1:nvals(iv));
  ieq = ieq + 1;
  eqcell{ieq} = sparse(ones(size(ids)), ids, 1, 1, N);
  beq(ieq) = 1;
  y0(ids) = cands{iv} == xvar0(iv);
  if nvals(iv) > 1
    delta(ids) = abs(cands{iv} - xvar0(iv)) / xvar0(iv);
  end
end
for is = 1:numel(rrows)
  ids = iz(is) + (1:nrows(is));
  ieq = ieq + 1;
  eqcell{ieq} = sparse(ones(size(ids)), ids, 1, 1, N);
  beq(ieq) = 1;
  f(ids) = max(wrows{is} - options.tau, 0);
  if rrows{is}(1) == PRM.RANK_NONE
    y0(ids) = 1;
    continue
  end
  idv = unique(nonzeros(com.secmgr.idsrep2var(is, :)));
  current = all(xrows{is} == xvar0(idv), 2);
  y0(ids) = current;
  rank0(is) = rrows{is}(current);
  for iv = 1:numel(idv)
    for k = 1:nvals(idv(iv))
      ieq = ieq + 1;
      cols = [ids(xrows{is}(:, iv) == cands{idv(iv)}(k)) iy(idv(iv)) + k];
      vals = [ones(1, numel(cols)-1) -1];
      eqcell{ieq} = sparse(ones(size(cols)), cols, vals, 1, N);
    end
  end
end

Aeq = vertcat(eqcell{:});

% 補正後種別が各境界を超える条件を、関係断面の論理和で表す。
% 下限と上限の両方を課し、都合のよい種別を任意に選ばせない。
Acell = cell(nq + 1, 1);
ub = [ones(ni, 1); inf(ng, 1)];
for ir = 1:nrank
  idsrep = find(Dmat(ir, :));
  for k = 1:3
    rows = cell(numel(idsrep) + 1, 1);
    badcols = cell(numel(idsrep), 1);
    for j = 1:numel(idsrep)
      is = idsrep(j);
      ids = iz(is) + find(rrows{is} > k);
      badcols{j} = ids;
      cols = [ids; iq(ir, k)];
      vals = [ones(size(ids)); -1];
      rows{j} = sparse(ones(size(cols)), cols, vals, 1, N);
    end
    cols = [vertcat(badcols{:}); iq(ir, k)];
    vals = [-ones(numel(cols)-1, 1); 1];
    rows{end} = sparse(ones(size(cols)), cols, vals, 1, N);
    Acell{(k-1)*nrank + ir} = vertcat(rows{:});
    y0(iq(ir, k)) = any(rank0(idsrep) > k);
  end
  % 復元元と候補をともに写像前の種別で比較する。
  ub(iq(ir, 3)) = y0(iq(ir, 3));
end
Acell{end} = [sparse(ng, iy(end)) Gmat -speye(ng)];
A = vertcat(Acell{:});
b = [zeros(size(A, 1) - ng, 1); options.tau - g0];
f(ni+1:end) = 1;
y0(ni+1:end) = max(g0 + Gmat*y0(iq(:)) - options.tau, 0);
lb = zeros(N, 1);

% 二段階で時間を共有する。上限の追加緩和は0とし、丸め後に再検査。
lpopt = optimoptions('intlinprog', 'Display', 'off', ...
  'AbsoluteGapTolerance', 0, 'RelativeGapTolerance', 0, ...
  'MaxTime', PRM.GROUP_RANK_RESTORE_MAX_TIME);
timer = tic;
[ysol, ~, exitflag] = intlinprog(f, 1:ni, A, b, Aeq, beq, ...
  lb, ub, y0, lpopt);
ysol = check_solution(ysol, exitflag, ni, A, b, Aeq, beq, ...
  ub, g0, Gmat, iq, options.tau, lpopt.ConstraintTolerance);
if isempty(ysol)
  return
end
J = f'*ysol;
remaining = PRM.GROUP_RANK_RESTORE_MAX_TIME - toc(timer);
if remaining > 0
  lpopt.MaxTime = remaining;
  [ysol2, ~, exitflag] = intlinprog(delta, 1:ni, [A; f'], ...
    [b; J], Aeq, beq, lb, ub, ysol, lpopt);
  ysol2 = check_solution(ysol2, exitflag, ni, A, b, Aeq, beq, ...
    ub, g0, Gmat, iq, options.tau, lpopt.ConstraintTolerance);
  if ~isempty(ysol2) && f'*ysol2 <= J
    ysol = ysol2;
  end
end
if f'*ysol >= f'*y0
  return
end
xvar = xvar0;
for iv = 1:numel(cands)
  ids = iy(iv) + (1:nvals(iv));
  xvar(iv) = cands{iv}' * ysol(ids);
end

return
end

function [Dmat, idm2rank] = rank_dependencies(com, rrows)
%rank_dependencies - 補正後種別に関わる代表断面の組をまとめる
%
%   [Dmat, idm2rank] = rank_dependencies(com, rrows) は、
%   同じ名目部材・接続梁に支配される部材を一つの判定にまとめる。
%
%   入力引数:
%     com   - 名目部材と断面の対応
%     rrows - 代表断面ごとの補正前種別候補
%
%   出力引数:
%     Dmat     - 判定する組と代表断面の対応 [nrank×nsrep]
%     idm2rank - 部材から判定する組への番号（未対応は0）

mp = com.member.property;
idm2s = com.section.property.idsrep(mp.idsec);
supported = cellfun(@(r) r(1) > PRM.RANK_NONE, rrows);
Dmat = false(numel(mp.idsec), numel(rrows));
for im = find(supported(idm2s))'
  idme = get_group_rank_members(com, im);
  if isempty(idme)
    idme = im;
  end
  ids = unique(idm2s(idme));
  Dmat(im, ids(supported(ids))) = true;
end
idme = find(any(Dmat, 2));
[Dmat, ~, ids] = unique(Dmat(idme, :), 'rows');
idm2rank = zeros(numel(mp.idsec), 1);
idm2rank(idme) = ids;

return
end

function [Gmat, g0] = group_coefficients(Dmat, idm2rank, idm2s, ...
  rrows, Qm, com)
%group_coefficients - 水平力を固定した群割合の線形係数を得る
%
%   [Gmat, g0] = group_coefficients(Dmat, idm2rank, idm2s,
%     rrows, Qm, com) は、通常評価の集計関数を用いて種別境界ごとの
%   割合制約の差分を作る。FD込みの分母は種別移動で変わらない。
%
%   入力引数:
%     Dmat, idm2rank - 種別補正の組と部材の対応
%     idm2s, rrows   - 部材の代表断面と種別候補
%     Qm, com        - 復元元水平力と階・ケースの集計条件
%
%   出力引数:
%     Gmat - 種別境界変数の線形係数
%     g0   - 対応部材をすべてFAとした群割合制約

supported = cellfun(@(r) r(1) > PRM.RANK_NONE, rrows);
drank = double(supported(idm2s));
[fa, fc] = calc_group_rank_force(com, drank, Qm);
g0 = [fa; fc];
nrank = size(Dmat, 1);
gcell = cell(3*nrank, 1);
for ir = 1:nrank
  previous = g0;
  for k = 1:3
    rank = drank;
    rank(idm2rank == ir) = k + 1;
    [fa, fc] = calc_group_rank_force(com, rank, Qm);
    gcell{(k-1)*nrank + ir} = [fa; fc] - previous;
    previous = [fa; fc];
  end
end
Gmat = sparse(horzcat(gcell{:}));

return
end

function ysol = check_solution(ysol, exitflag, ni, A, b, ...
  Aeq, beq, ub, g0, Gmat, iq, tau, tol)
%check_solution - 整数選択を丸めて実行可能性を再検査する
%
%   ysol = check_solution(ysol, exitflag, ni, A, b,
%     Aeq, beq, ub, g0, Gmat, iq, tau, tol) は、選択から超過量を
%   再計算し、制約を満たす整数実行可能解だけを返す。
%
%   入力引数:
%     ysol, exitflag - 求解結果と終了状態
%     ni             - 整数変数の数
%     A, b, Aeq, beq - 不等式・等式制約
%     ub             - 上限値（下限は0）
%     g0, Gmat, iq   - 群割合の定数・係数・変数位置
%     tau            - 通常制約の許容差
%     tol            - 求解器の制約許容差
%
%   出力引数:
%     ysol - 検査後の解（不適合は空配列）

if isempty(ysol) || ~ismember(exitflag, [1 2])
  ysol = [];
  return
end
z = round(ysol(1:ni));
if any(abs(ysol(1:ni) - z) > tol)
  ysol = [];
  return
end
ysol(1:ni) = z;
ysol(ni+1:end) = max(g0 + Gmat*ysol(iq(:)) - tau, 0);
if any(ysol < 0 | ysol > ub) || any(abs(Aeq*ysol - beq) > tol) ...
    || any(A*ysol - b > tol)
  ysol = [];
end

return
end
