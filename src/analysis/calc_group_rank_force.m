function [confa, confc, Qrank] = calc_group_rank_force(com, drank, Qm)
%calc_group_rank_force - 補正済み種別で水平力と群割合を集計する
%
%   [confa, confc, Qrank] = calc_group_rank_force(com, drank, Qm) は、
%   柱と階をまたぐ梁の水平力を集計する。種別の補正は呼出し元で行う。
%
%   入力引数:
%     com   - 部材・階・ケースと群種別の要求
%     drank - 補正後の部材種別 [nme×1]（未対応は0）
%     Qm    - 符号付き部材水平力 [nme×nlc] (N)
%
%   出力引数:
%     confa, confc - FA・FC割合の制約 [nconfa×1], [nconfc×1]
%     Qrank        - 種別別水平力 [nfl×nlc×nrank] (N)

mp = com.member.property;
floor = com.floor;

% 階上端を横切る区間だけを採り、内部分割の二重計上を避ける
% 通し柱・多層梁は跨ぐ各階へ計上し、逆向きの負担も符号を保つ
% 部材と対象階の組は加力ケースによらないので、読込時に数えた跨ぐ階から
% 一度だけ作る
target = ismember(mp.type, [PRM.COLUMN PRM.GIRDER]) & drank > 0;
idfloor = mp.idfloor;
idfloor(~target, :) = 0;
[ime, ~, ifl] = find(idfloor);
ime = ime(:);
ifl = ifl(:);
is_group_floor = floor.rank_group(ifl) > 0;
ime = ime(is_group_floor);
ifl = ifl(is_group_floor);
idlc = find(ismember(com.loadcase.dir, [PRM.EXP PRM.EXN PRM.EYP PRM.EYN]));
nfl = numel(floor.idz);
nrank = numel(PRM.MEMBER_RANK_NAME);
Qrank = zeros(nfl, size(Qm, 2), nrank);
for ilc = idlc(:)'
  Qrank(:, ilc, :) = reshape(accumarray([ifl drank(ime)], Qm(ime, ilc), ...
    [nfl nrank]), nfl, 1, nrank);
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
