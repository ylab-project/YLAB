function [cands, xrows, wrows, rrows] = create_wtratio_candidates( ...
  xvar, secdim, idsec, com, options, Fs, isSNsec, grank, crank, is_wtcon)
%create_wtratio_candidates - 幅厚比候補を写像前の寸法で評価する
%
%   [cands, xrows, wrows, rrows] = create_wtratio_candidates( ...
%     xvar, secdim, idsec, com, options, Fs, isSNsec,
%     grank, crank, is_wtcon) は、現在値と上下近傍から、
%   各代表断面内の有限な組合せを作る。固定変数は基点値だけを候補とし、
%   表作成中に写像しない。
%
%   入力引数:
%     xvar   - 復元元の設計変数 [1×nx]
%     secdim - 復元元の写像済み断面 [nsec×7] (mm)
%     idsec  - 変更対象の代表断面番号
%     com    - 断面・材料・設計変数の情報
%     options - 共通オプション
%     Fs, isSNsec - 復元元の材料F値とSN材判定 [nsec×1]
%     grank, crank, is_wtcon - 実効要求種別と対象 [nsec×1]
%
%   出力引数:
%     cands - 全設計変数の候補値 {nx×1}
%     xrows - 代表断面内の変数候補 {nsrep×1}（変数番号の昇順）
%     wrows - 候補行の実効幅厚比制約 {nsrep×1}
%     rrows - 候補行の補正前種別 {nsrep×1}

secmgr = com.secmgr;
isvar = com.design.variable.isvar(:)';
idsec2var = secmgr.idsec2var;
idvar = unique(nonzeros(idsec2var(idsec, :)));
% 板厚対の近傍から寸法ごとの値を集め、後段で直積を作る。
% 元の対は保持せず、共有変数の値を断面間で一致させる。
% 候補値の追加は可変変数だけに限り、固定変数には基点値を保つ。
cands = num2cell(xvar(:));
for iv = idvar(:)'
  if ~isvar(iv)
    continue
  end
  xlist = secmgr.neighborSearcher.enumerateNeighbor( ...
    xvar, iv, secmgr.idvar2vtype(iv), options);
  for jv = find(any(xlist ~= xvar, 1) & isvar)
    cands{jv} = unique([cands{jv}; xlist(:, jv)]);
  end
end
for iv = idvar(:)'
  vals = cands{iv};
  vals = vals(vals >= secmgr.lb(iv) & vals <= secmgr.ub(iv));
  cands{iv} = unique([xvar(iv); vals]);
end

% 復元元の材料を使い、候補行の寸法だけを変更する。
idsrep2s = com.section.representative.idsec;
stype = com.section.representative.section_type;
nsrep = numel(idsrep2s);
xrows = cell(nsrep, 1);
wrows = cell(nsrep, 1);
rrows = cell(nsrep, 1);
for is = 1:nsrep
  ids = idsrep2s(is);
  if ~ismember(stype(is), [PRM.WFS PRM.HSS PRM.CWFS PRM.CWFSI])
    xrows{is} = zeros(1, 0);
    wrows{is} = 0;
    rrows{is} = PRM.RANK_NONE;
    continue
  end
  idv = unique(nonzeros(secmgr.idsrep2var(is, :)));
  % 同一変数を複数寸法に使う場合も、列挙は一つの選択にまとめる。
  nvals = cellfun(@numel, cands(idv));
  nrow = prod(nvals);
  xrows{is} = zeros(nrow, numel(idv));
  for iv = 1:numel(idv)
    irow = mod(floor((0:nrow-1)' / prod(nvals(1:iv-1))), nvals(iv));
    xrows{is}(:, iv) = cands{idv(iv)}(irow + 1);
  end
  sd = repmat(secdim(ids, :), nrow, 1);
  for idim = find(idsec2var(ids, :) > 0)
    [~, iv] = ismember(idsec2var(ids, idim), idv);
    sd(:, idim) = xrows{is}(:, iv);
  end
  % 既存の幅厚比関数を一括で呼び、種別と制約値の式を共用する。
  F = repmat(Fs(ids), nrow, 1);
  sn = repmat(isSNsec(ids), nrow, 1);
  [wt, rank] = calc_wtratio(sd, F, (1:nrow)', repmat( ...
    stype(is), nrow, 1), repmat(grank(ids), nrow, 1), ...
    repmat(crank(ids), nrow, 1), sn, options);
  wrows{is} = wt + options.coptions.alfa_section_wt_ratio;
  if ~is_wtcon(ids)
    wrows{is}(:) = 0;
  end
  rrows{is} = rank;
end

return
end
