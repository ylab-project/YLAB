function [confa, confc, drank, Qrank] = calc_group_rank(com, drank0, Qm)
%calc_group_rank - 部材種別を補正し群種別の割合制約を評価する
%
%   [confa, confc, drank, Qrank] = calc_group_rank(com, drank0, Qm) は、
%   名目部材と接続梁の最下位種別を採り、階上端直下の水平力を種別別に
%   集計する。対応部材を補正・集計し、FDも集計に含める。
%
%   入力引数:
%     com    - 部材対応と階別の要求種別・余裕率
%     drank0 - 補正前の部材種別 [nme×1]（0=未対応、FA～FD=1～4）
%     Qm     - 部材の符号付き水平力 [nme×nlc] (N)
%
%   出力引数:
%     confa - 要求AのFA割合制約 [nconfa×1]
%     confc - 要求A・BのFC割合制約 [nconfc×1]
%     drank - 補正後の部材種別 [nme×1]（未対応部材は0のまま）
%     Qrank - 種別別水平力 [nfl×nlc×nrank] (N)
%
%   備考:
%     - 割合制約は地震荷重ケースごとに対象階の順に並べる
%     - Qrankの対象外階・ケースは0、nrankはFA～FDの種別数

mp = com.member.property;
nominal = com.nominal.property;
idnm2m = nominal.idme;
nmtype = nominal.mtype;
idm2n = [mp.idnode1 mp.idnode2];
drank = drank0;

% 0埋めされた既存の区間対応から、名目部材の最下位を一括集約する。
rank = [PRM.RANK_NONE; drank0];
ranknominal = max(reshape(rank(idnm2m + 1), size(idnm2m)), [], 2);
[inm, j] = find(idnm2m > 0);
idme = idnm2m(sub2ind(size(idnm2m), inm, j));

% 名目梁の全区間を両端節点へ渡す。重複節点も同じ最大値となる。
ids = nmtype(inm) == PRM.GIRDER;
idnode = idm2n(idme(ids), :);
rank = repmat(ranknominal(inm(ids)), 1, 2);
ranknode = accumarray(idnode(:), rank(:), [numel(com.node.idz), 1], ...
  @max, PRM.RANK_NONE);

% 梁から柱への補正だけを行い、未対応区間の種別0を保つ。
rank = [PRM.RANK_NONE; max(reshape(ranknode(idm2n), size(idm2n)), [], 2)];
ids = nmtype == PRM.COLUMN;
ranknominal(ids) = max(ranknominal(ids), max(reshape( ...
  rank(idnm2m(ids, :) + 1), nnz(ids), size(idnm2m, 2)), [], 2));
ids = ismember(nmtype(inm), [PRM.GIRDER PRM.COLUMN]) & ...
  drank0(idme) > PRM.RANK_NONE;
drank(idme(ids)) = ranknominal(inm(ids));
[confa, confc, Qrank] = calc_group_rank_force(com, drank, Qm);

return
end
