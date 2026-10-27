function xlist = restore_column_diameter_gap(xlist0, Dgap, ...
  secmgr, isvar, options)
%restore_column_diameter_gap - 柱外径差違反の復元候補を生成する
%
%   xlist = restore_column_diameter_gap(xlist0, Dgap, secmgr,
%     isvar, options) は、角形鋼管の外径とH形鋼柱の公称せいを近傍の
%   候補から選ぶ。独立した変数の組ごとに最大違反量、寸法変更量の
%   順で最小化し、固定変数を維持した候補を後段の評価へ渡す。
%
%   入力引数:
%     xlist0  - 変数値の候補リスト [nlist×nx]
%     Dgap    - 柱外径差ペアデータ（idvar, idxy）
%     secmgr  - SectionManagerインスタンス
%     isvar   - 設計変数フラグ [nx×1]（偽=固定）
%     options - 共通オプション
%
%   出力引数:
%     xlist - 現在値と復元候補 [nlist×nx]（対象なしは0行）

xlist = zeros(0,size(xlist0,2));
if ~options.coptions.consider_column_diameter_gap ...
    || isempty(Dgap.idvar) || isempty(xlist0)
  return
end

% 同じ通りでも、変更可能な変数を共有しない組は独立に最小化する。
% 組の対応は候補によらないため、候補ループの前に一度だけ求める。
idDgap2var = Dgap.idvar;
[~, ~, idxy] = unique(Dgap.idxy,'rows');
idg2group = zeros(size(idDgap2var,1),1);
for id=1:max(idxy)
  istarget = idxy == id;
  idg2v = idDgap2var(istarget,:);
  % ペアと変更可能な変数を結び、固定柱を挟むペアは独立に扱う。
  ngap = size(idg2v,1);
  [ig, ~] = find(reshape(isvar(idg2v),size(idg2v)));
  [~, ~, idg2x] = unique(idg2v(isvar(idg2v) > 0));
  idg2x = idg2x(:);
  idgroup = conncomp(graph(ig,ngap+idg2x,[],ngap+max([0; idg2x])));
  idg2group(istarget) = max(idg2group) + idgroup(1:ngap);
end

% 従来の3秒を各求解に適用し、目的関数のギャップによる早期終了を
% 無効にする。時間切れの整数解は最適性を保証せず候補として返す。
lpopt = optimoptions('intlinprog','Display','off','MaxTime',3, ...
  'AbsoluteGapTolerance',0,'RelativeGapTolerance',0);
nlist0 = size(xlist0,1);
xcell = cell(nlist0,1);
if nlist0 > 1 && options.do_parallel
  parfor i=1:nlist0
    xcell{i} = restore_individual(xlist0(i,:), idDgap2var, ...
      idg2group, secmgr, isvar, options, lpopt);
  end
else
  for i=1:nlist0
    xcell{i} = restore_individual(xlist0(i,:), idDgap2var, ...
      idg2group, secmgr, isvar, options, lpopt);
  end
end
xlist = unique(vertcat(xcell{:}),'rows','stable');

return
end

%--------------------------------------------------------------------------
function xlist = restore_individual(xvar, idDgap2var, idg2group, ...
  secmgr, isvar, options, lpopt)
%restore_individual - 1候補の柱外径差を独立した組ごとに復元する
%
%   xlist = restore_individual(xvar, idDgap2var, idg2group,
%     secmgr, isvar, options, lpopt) は、現在値と独立した組ごとの
%   復元候補を返す。全てのペアが許容値以内なら候補を追加しない。
%
%   入力引数:
%     xvar       - 現在の変数値 [1×nx]
%     idDgap2var - 上下柱の変数番号 [ngap×2]（上階、下階）
%     idg2group  - ペアが属する独立した組の番号 [ngap×1]
%     secmgr     - SectionManagerインスタンス
%     isvar      - 設計変数フラグ [nx×1]
%     options    - 共通オプション
%     lpopt      - 整数計画のオプション
%
%   出力引数:
%     xlist - 現在値と復元候補 [nlist×nx]（対象なしは0行）

xlist = zeros(0,size(xvar,2));
condgap = calc_column_diameter_gap_var(xvar, idDgap2var, options);
if all(condgap<=options.tau)
  return
end
xcell = cell(max(idg2group)+1,1);
xcell{1} = xvar;
for id=1:max(idg2group)
  idg2v = idDgap2var(idg2group==id,:);
  xcell{id+1} = restore_pairs(xvar, idg2v, secmgr, isvar, options, lpopt);
end
xlist = vertcat(xcell{:});

return
end

%--------------------------------------------------------------------------
function xsol = restore_pairs(xvar, idg2v, secmgr, isvar, options, lpopt)
%restore_pairs - 候補選択の整数計画で柱外径差を復元する
%
%   xsol = restore_pairs(xvar, idg2v, secmgr, isvar, options, lpopt)
%   は、共有変数でつながる上下柱のペアについて、変数ごとに近傍の
%   寸法を1つ選ぶ。違反量の最小間隔が1 mm以上という前提で、
%   最大違反量、現在値からの変更量の順に1回の求解で最小化する。
%
%   入力引数:
%     xvar    - 現在の変数値 [1×nx]
%     idg2v   - 上下柱の変数番号 [ngap×2]（上階、下階）
%     secmgr  - SectionManagerインスタンス
%     isvar   - 設計変数フラグ [nx×1]
%     options - 共通オプション
%     lpopt   - 整数計画のオプション
%
%   出力引数:
%     xsol - 復元候補 [1×nx]（追加候補なしは0行）

xsol = zeros(0,size(xvar,2));
condgap = calc_column_diameter_gap_var(xvar, idg2v, options);
if all(condgap<=options.tau)
  return
end

% 固定変数は現在値のみ。角形鋼管は上下1サイズ、H形鋼柱は既存の
% 公称せいの近傍を使い、候補間を補間した寸法は生成しない。
idx2v = unique(idg2v);
nv = length(idx2v);
cands = cell(nv,1);
for iv=1:nv
  iv2v = idx2v(iv);
  cands{iv} = xvar(iv2v);
  if ~isvar(iv2v)
    continue
  end
  if secmgr.idvar2vtype(iv2v) == PRM.WFS_H
    [vup, vdw] = secmgr.neighborSearcher.getNeighborH(xvar(iv2v),iv2v);
  else
    [vup, vdw] = secmgr.neighborSearcher.getNeighborD(xvar(iv2v),iv2v);
  end
  cands{iv} = unique([xvar(iv2v); vup; vdw]);
end

% 候補の選択変数と、選んだ寸法への写像を疎行列で構成する。
% 同じ設計変数に対する選択は、全ての接続ペアで共有する。
nvals = cellfun(@numel,cands);
idstart = cumsum([0; nvals]);
nz = idstart(end);
f = zeros(nz+1,1);
y0 = zeros(nz+1,1);
dmax = 0;
for iv=1:nv
  ids = idstart(iv)+(1:nvals(iv));
  f(ids) = abs(cands{iv}-xvar(idx2v(iv)));
  dmax = dmax + max(f(ids));
  y0(ids) = cands{iv} == xvar(idx2v(iv));
end
if dmax == 0
  return
end

idvar = repelem((1:nv)',nvals);
Hmat = sparse(idvar,(1:nz)',vertcat(cands{:}),nv,nz);
Aeq = sparse(idvar,(1:nz)',1,nv,nz+1);

% 変更量の寄与を0.5以下にし、違反量1 mmの改善を必ず優先する。
% 最後の連続変数は全ペアに共通する最大違反量 [mm]。
f(1:nz) = f(1:nz)*(0.5/dmax);
f(end) = 1;
[~, idg2x] = ismember(idg2v,idx2v);
Dmat = Hmat(idg2x(:,1),:) - Hmat(idg2x(:,2),:);
ngap = size(idg2v,1);
A = [Dmat -ones(ngap,1); -Dmat -ones(ngap,1)];
b = [zeros(ngap,1); options.tolMaxDgap*ones(ngap,1)];
beq = ones(nv,1);
y0(end) = max([0; A(:,1:nz)*y0(1:nz)-b]);
lb = zeros(nz+1,1);
ub = [ones(nz,1); y0(end)];
[ysol, ~, exitflag] = intlinprog(f,1:nz,A,b,Aeq,beq,lb,ub,y0,lpopt);

% 最適解または時間切れ等の整数実行可能解だけを候補へ戻す。
% 選択値の数値誤差は整数許容差内で丸め、物理寸法は候補から採る。
if isempty(ysol) || ~ismember(exitflag,[1 2])
  return
end
z = round(ysol(1:nz));
if any(abs(ysol(1:nz)-z)>lpopt.ConstraintTolerance) ...
    || any(z<0 | z>1) || any(Aeq(:,1:nz)*z~=beq)
  return
end
xsol = xvar;
xsol(idx2v) = Hmat*z;

return
end
