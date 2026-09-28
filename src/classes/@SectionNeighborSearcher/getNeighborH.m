function [Hup, Hdw] = getNeighborH(obj, Hcur, idvar, delta)
%getNeighborH - 公称せいHの近傍候補を寸法だけで取得する
%
%   [Hup, Hdw] = getNeighborH(obj, Hcur, idvar, delta) は、対象変数の
%   断面リストから近傍の公称せいを選ぶ。上側は昇順、下側は降順で、
%   探索範囲の端を超える最初の候補まで含める。
%
%   入力引数:
%     obj   - SectionNeighborSearcherインスタンス
%     Hcur  - 現在の公称せい [mm]
%     idvar - 対象変数ID（空なら候補なし）
%     delta - 探索範囲 [mm]（省略時150）
%
%   出力引数:
%     Hup - 上側の候補寸法 [nup×1]
%     Hdw - 下側の候補寸法 [ndw×1]

if nargin == 3
  delta = 150;
end
Hup = zeros(0,1);
Hdw = zeros(0,1);
if isempty(idvar)
  return
end

% 対象変数を使うH形鋼断面の公称せいをリストから集める。
idsec2var = obj.idMapper_.idsec2var;
idsec2shape = obj.idMapper_.idsec2shape;
idwfs2x = idsec2var(idsec2shape==PRM.WFS,1:4);
if all(idwfs2x(:,PRM.SECDIM_WFS_H)~=idvar)
  return
end
idslist = obj.idMapper_.getIdSlistofVar(idvar);
if isempty(idslist)
  return
end
values = cell(numel(idslist),1);
for i=1:numel(idslist)
  values{i} = obj.standardAccessor_.getNominalH(idslist(i));
  values{i} = values{i}(:);
end
Hnset = unique(vertcat(values{:}));

% 既存の探索範囲の端を含む候補まで選び、現在値を除く。
idx_current = find(Hnset==Hcur);
H_upper_limit = min(Hcur+delta,max(Hnset));
idx_candidates = find(Hnset>=H_upper_limit);
if ~isempty(idx_candidates)
  idx_upper = idx_candidates(1);
else
  idx_upper = length(Hnset);
end
idx_up_range = setdiff(idx_current:idx_upper,idx_current);
H_lower_limit = max(Hcur-delta,min(Hnset));
idx_candidates = find(Hnset<=H_lower_limit);
if ~isempty(idx_candidates)
  idx_lower = idx_candidates(end);
else
  idx_lower = 1;
end
idx_down_range = fliplr(setdiff(idx_lower:idx_current,idx_current));
Hup = Hnset(idx_up_range);
Hdw = Hnset(idx_down_range);

Hup = Hup(:);
Hdw = Hdw(:);

return
end