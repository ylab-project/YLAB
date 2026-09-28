function [Dup, Ddw] = getNeighborD(obj, Dcur, idvar)
%getNeighborD - 外径Dの近傍候補を寸法だけで取得する
%
%   [Dup, Ddw] = getNeighborD(obj, Dcur, idvar) は、対象変数の
%   断面リストに含まれる外径から上下1サイズの候補を返す。
%
%   入力引数:
%     obj   - SectionNeighborSearcherインスタンス
%     Dcur  - 現在の外径 [mm]
%     idvar - 対象変数ID（空なら候補なし）
%
%   出力引数:
%     Dup - 上側の候補寸法 [nup×1]（0または1行）
%     Ddw - 下側の候補寸法 [ndw×1]（0または1行）

Dup = zeros(0,1);
Ddw = zeros(0,1);
if isempty(idvar)
  return
end

% 対象変数を使う鋼管断面の外径をリストから集める。
idsec2var = obj.idMapper_.idsec2var;
idsec2shape = obj.idMapper_.idsec2shape;
idhss2x = idsec2var(idsec2shape==PRM.HSS,1:2);
if all(idhss2x(:,PRM.SECDIM_HSS_D)~=idvar)
  return
end
idslist = obj.idMapper_.getIdSlistofVar(idvar);
if isempty(idslist)
  return
end
values = cell(numel(idslist),1);
for i=1:numel(idslist)
  values{i} = obj.standardAccessor_.getStandardD(idslist(i));
  values{i} = values{i}(:);
end
Dst = unique(vertcat(values{:}));

% 現在の外径に隣接する上下1サイズを選ぶ。
idst_cur = find(Dst==Dcur);
idst_up = idst_cur+1;
idst_dw = idst_cur-1;
Dup = Dst(idst_up(idst_up<=numel(Dst)));
Ddw = Dst(idst_dw(idst_dw>=1));

Dup = Dup(:);
Ddw = Ddw(:);

return
end