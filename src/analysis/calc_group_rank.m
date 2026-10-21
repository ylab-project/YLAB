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
floor = com.floor;
idnm2m = nominal.idme;
nmtype = nominal.mtype;
idm2n = [mp.idnode1 mp.idnode2];
drank = drank0;

% 名目梁の全区間の最下位を、両端・内部の各節点へ集約する
% 接続区間が未対応でも、同じ名目梁の他区間の種別は柱へ伝える
ranknode = PRM.RANK_NONE * ones(numel(com.node.idz), 1);
for inm = find(nmtype == PRM.GIRDER)'
  idme = nonzeros(idnm2m(inm, :));
  rank = max(drank0(idme));
  drank(idme(drank0(idme) > PRM.RANK_NONE)) = rank;
  idnode = unique(idm2n(idme, :));
  ranknode(idnode) = max(ranknode(idnode), rank);
end

% 柱の全区間と接続梁の最下位を採り、未対応区間の0は維持する
% 梁から柱への補正に限り、柱の種別を他の柱・梁へ伝えない
for inm = find(nmtype == PRM.COLUMN)'
  idme = nonzeros(idnm2m(inm, :));
  idnode = unique(idm2n(idme, :));
  rank = max([drank0(idme); ranknode(idnode)]);
  drank(idme(drank0(idme) > PRM.RANK_NONE)) = rank;
end

% 階上端を横切る区間だけを採り、内部分割の二重計上を避ける
% 通し柱・多層梁は跨ぐ各階へ計上し、逆向きの負担も符号を保つ
bottom = min(com.node.idz(mp.idnode1), com.node.idz(mp.idnode2));
top = max(com.node.idz(mp.idnode1), com.node.idz(mp.idnode2));
target = ismember(mp.type, [PRM.COLUMN PRM.GIRDER]) & drank > 0;
idlc = find(ismember(com.loadcase.dir, [PRM.EXP PRM.EXN PRM.EYP PRM.EYN]));
Qrank = zeros(numel(floor.idz), size(Qm, 2), numel(PRM.MEMBER_RANK_NAME));
for ifl = find(floor.rank_group > 0)'
  idme = find(target & bottom < floor.idz(ifl) & floor.idz(ifl) <= top);
  for ilc = idlc(:)'
    Qrank(ifl, ilc, :) = accumarray(drank(idme), Qm(idme, ilc), ...
      [numel(PRM.MEMBER_RANK_NAME) 1]);
  end
end

% FD込みの水平力合計を分母とする。分母が0の割合制約だけを0とする
Q = sum(Qrank(:, idlc, :), 3);
confa = 1 - Qrank(:, idlc, PRM.MEMBER_RANK_FA) ./ Q ...
  / PRM.GROUP_RANK_A_MIN_RATIO + floor.alfa_group_fa;
limit = PRM.GROUP_RANK_A_MAX_C_RATIO * ones(numel(floor.idz), 1);
limit(floor.rank_group == PRM.GROUP_RANK_B) = PRM.GROUP_RANK_B_MAX_C_RATIO;
confc = Qrank(:, idlc, PRM.MEMBER_RANK_FC) ./ Q ./ limit ...
  - 1 + floor.alfa_group_fc;
confa(Q == 0) = 0;
confc(Q == 0) = 0;
confa = confa(floor.rank_group == PRM.GROUP_RANK_A, :);
confc = confc(ismember(floor.rank_group, ...
  [PRM.GROUP_RANK_A PRM.GROUP_RANK_B]), :);
confa = confa(:);
confc = confc(:);

return
end
