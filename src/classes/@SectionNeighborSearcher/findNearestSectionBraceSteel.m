function [secbrace, id] = findNearestSectionBraceSteel( ...
  obj, xvar, idslist, is_target)
%findNearestSectionBraceSteel - ブレース鋼材の最近傍断面を選択する
%
%   [secbrace, id] = findNearestSectionBraceSteel(obj, xvar,
%   idslist, is_target) は、ブレース鋼材断面（BWFS/BHSS/BHSR）の
%   最近傍断面を断面リストから選択する。
%
%   入力引数:
%     obj       - SectionNeighborSearcherインスタンス
%     xvar      - 設計変数ベクトル [nxvar×1]
%     idslist   - 断面リストID
%     is_target - 対象断面の論理配列 [nsec×1]
%
%   出力引数:
%     secbrace - 選択した断面寸法 [ntarget×5]
%     id       - ID構造体（.slist、.section）

secdimlist = obj.standardAccessor_.getSectionDimension(idslist);
nsecdim = size(secdimlist, 2);
idsec_list = find(is_target);
ntarget = length(idsec_list);
secbrace = zeros(ntarget, 5);
id.slist = zeros(ntarget, 1);
id.section = zeros(ntarget, 1);
idsec2var = obj.idMapper_.idsec2var;

for itarget = 1:ntarget
  isec = idsec_list(itarget);
  varids = idsec2var(isec, :);
  varids = varids(varids > 0);
  ncol = min(length(varids), nsecdim);
  if ncol == 0
    continue
  end
  target = reshape(xvar(varids(1:ncol)), 1, []);
  distance = sum((secdimlist(:, 1:ncol) - target).^2, 2);
  [~, index] = min(distance);
  ndim = min(nsecdim, 5);
  secbrace(itarget, 1:ndim) = secdimlist(index, 1:ndim);
  id.slist(itarget) = idslist;
  id.section(itarget) = index;
end

return
end