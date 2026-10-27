function [xlist, sdlist, conwt, drank] = restore_section_wtratio( ...
  xvar0, secdim0, com, options, Fs, isSNsec, grank, crank, is_wtcon)
%restore_section_wtratio - 幅厚比を満たす断面別の復元候補を作る
%
%   [xlist, sdlist, conwt, drank] = restore_section_wtratio( ...
%     xvar0, secdim0, com, options, Fs, isSNsec, grank, crank, ...
%     is_wtcon) は、違反断面ごとに実効要求を満たす最小変更候補を選び、
%   固定変数を維持し、写像後にも条件を確認する。
%
%   入力引数:
%     xvar0, secdim0 - 復元元の設計変数と写像済み断面の組
%     com           - 断面・材料・設計変数の情報
%     options       - 共通オプション
%     Fs, isSNsec   - 復元元の材料F値とSN材判定 [nsec×1]
%     grank, crank, is_wtcon - 実効要求種別と対象 [nsec×1]
%
%   出力引数:
%     xlist  - 復元操作で選んだ設計変数 [nlist×nx]
%     sdlist - xlistと対の断面寸法 [nsec×7×nlist]
%     conwt, drank - 復元元の幅厚比制約と種別 [nsrep×1]

xlist = zeros(0, numel(xvar0));
sdlist = secdim0(:, :, []);
[conwt, drank] = eval_section_wtratio(secdim0, com, options, ...
  Fs, isSNsec, grank, crank, is_wtcon);
ids = find(conwt > options.tau);
if isempty(ids)
  return
end
idsrep2s = com.section.representative.idsec;
[~, xrows, wrows] = create_wtratio_candidates(xvar0, secdim0, ...
  idsrep2s(ids), com, options, Fs, isSNsec, grank, crank, is_wtcon);
xcell = cell(numel(ids), 1);
idsec = zeros(numel(ids), 1);
for i = 1:numel(ids)
  is = ids(i);
  idv = unique(nonzeros(com.secmgr.idsrep2var(is, :)));
  rows = find(wrows{is} <= options.tau);
  if isempty(rows)
    xcell{i} = zeros(0, numel(xvar0));
    continue
  end
  delta = sum(abs(xrows{is}(rows, :) - xvar0(idv)) ./ xvar0(idv), 2);
  [~, idx] = min(delta);
  xvar = xvar0;
  xvar(idv) = xrows{is}(rows(idx), :);
  xcell{i} = xvar;
  idsec(i) = is;
end
xlist = vertcat(xcell{:});
idsec = nonzeros(idsec);
if isempty(xlist)
  return
end
initial_guess = struct('x', xvar0, 'secdim', secdim0);
sdlist = com.secmgr.findNearestSectionList(xlist, options, ...
  initial_guess, com);
keep = false(size(xlist, 1), 1);
for i = 1:size(xlist, 1)
  [candidate_Fs, candidate_isSNsec] = ...
    get_section_material_properties(sdlist(:, :, i), com);
  candidate_conwt = eval_section_wtratio(sdlist(:, :, i), com, ...
    options, candidate_Fs, candidate_isSNsec, grank, crank, is_wtcon);
  keep(i) = candidate_conwt(idsec(i)) <= options.tau;
end
xlist = xlist(keep, :);
sdlist = sdlist(:, :, keep);

return
end
