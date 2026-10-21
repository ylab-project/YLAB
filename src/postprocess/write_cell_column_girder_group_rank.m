function [head, body] = write_cell_column_girder_group_rank( ...
  com, result, ilc)
%write_cell_column_girder_group_rank - 柱・梁群の種別の推定帳票を作る
%
%   [head, body] = write_cell_column_girder_group_rank(com, result,
%   ilc) は、一次解析の水平力と幅厚比による部材種別から、
%   一般階の柱・梁群の種別を推定する。柱と接続梁の全方向の最下位を
%   採用し、FD部材を考慮する。接合部・横補剛・柱脚は評価しない。
%
%   入力引数:
%     com     - 階、部材、名目部材の対応
%     result  - 解析結果（Qrank [N]、rank.section・memberを使用）
%     ilc     - 地震荷重ケース番号
%
%   出力引数:
%     head - 見出し [3×13] cell
%     body - 一般階ごとの表示行 [ngroup×13] cell

% 加力方向に沿う負担を正で表示する。逆向きの負担も符号を保つ
switch com.loadcase.dir(ilc)
  case {PRM.EXP, PRM.EYP}
    sign_dir = -1;
  case {PRM.EXN, PRM.EYN}
    sign_dir = 1;
  otherwise
    head = {};
    body = {};
    return
end

mp = com.member.property;
floor = com.floor;
% 一般階には読込時に要求種別が無条件に入るので、対象階はそれで決まる
idfloor = flip(find(floor.rank_group > 0));
ngroup = numel(idfloor);

% 種別と水平力は calc_group_rank が補正・集計した値を読む。未対応の
% 接続梁を含む群を未判定にするため、補正前の種別も断面番号で参照する
drank0 = result.rank.section(mp.idsec);
drank = result.rank.member;

% 階上端の直下を横切る部材を採る。内部分割の隣接要素を重複せず、
% 通し柱と多層にわたる梁は、それぞれが跨ぐ階へ計上する
idz1 = com.node.idz(mp.idnode1);
idz2 = com.node.idz(mp.idnode2);
bottom = min(idz1, idz2);
top = max(idz1, idz2);
target = mp.type == PRM.COLUMN | mp.type == PRM.GIRDER;

head = cell(3, 13);
head(1, :) = {'階', '主体構造', 'FA', '', 'FB', '', 'FC', '', ...
  'FA+FB+FC', 'FD', 'Q(合計)', '種別', '備考'};
head(2, 3:8) = {'Q', '割合', 'Q', '割合', 'Q', '割合'};
head(3, [3 5 7 9 10 11]) = repmat({'kN'}, 1, 6);
body = cell(ngroup, 13);
note = ['一次解析による推定（全方向の柱・接続梁で最下位、FD考慮。' ...
  '接合部・横補剛・柱脚は未評価）'];

for igroup = 1:ngroup
  ifl = idfloor(igroup);
  idme = find(target & bottom < floor.idz(ifl) & floor.idz(ifl) <= top);
  idme_rank = get_group_rank_members(com, idme);
  rank = PRM.RANK_NONE;
  reason = '';
  if isempty(idme)
    reason = '／対象部材なし';
  elseif any(drank0(idme_rank) == PRM.RANK_NONE)
    reason = '／種別未評価の部材あり';
  else
    % 数値集計と判定はN・丸め前の値で行う。割合の分母はFA～FCの
    % 合計Q（SS7計算編12.3.7）とし、FDを含むQ_totalはQ(合計)欄に使う
    Qrank = reshape(result.Qrank(ifl, ilc, :), 1, []);
    Q = sum(Qrank(PRM.MEMBER_RANK_FA:PRM.MEMBER_RANK_FC));
    Q_total = sum(Qrank);
    is_fd = drank(idme) == PRM.MEMBER_RANK_FD;
    if all(is_fd)
      % FA～FCの部材がなく分母に対象がない。SS7と同じ0表示にする
      body(igroup, [4 6 8]) = repmat({'0.000'}, 1, 3);
    elseif Q ~= 0
      ratio = Qrank(PRM.MEMBER_RANK_FA:PRM.MEMBER_RANK_FC) / Q;
      body(igroup, [4 6 8]) = arrayfun(@(r) sprintf('%.3f', r + 0), ...
        ratio, 'UniformOutput', false);
      if ratio(PRM.MEMBER_RANK_FA) >= PRM.GROUP_RANK_A_MIN_RATIO ...
          && ratio(PRM.MEMBER_RANK_FC) <= PRM.GROUP_RANK_A_MAX_C_RATIO
        rank = PRM.GROUP_RANK_A;
      elseif ratio(PRM.MEMBER_RANK_FC) < PRM.GROUP_RANK_C_MIN_RATIO
        rank = PRM.GROUP_RANK_B;
      else
        rank = PRM.GROUP_RANK_C;
      end
    else
      reason = '／FA+FB+FCが0（割合未判定）';
    end
    % FDがあるときは割合や水平力の合計によらずD
    if any(is_fd)
      rank = PRM.GROUP_RANK_D;
    end

    % 表示はkN小数1桁、割合は小数3桁。+0は-0.0の表示を避ける
    body(igroup, [3 5 7 9 10 11]) = arrayfun(@(q) sprintf('%.1f', q), ...
      sign_dir * [Qrank(PRM.MEMBER_RANK_FA:PRM.MEMBER_RANK_FC), ...
      Q, Qrank(PRM.MEMBER_RANK_FD), Q_total] / 1000 + 0, ...
      'UniformOutput', false);
  end

  body{igroup, 1} = floor.name{ifl};
  if ~isempty(idme) && all(drank0(idme) > PRM.RANK_NONE)
    body{igroup, 2} = 'S';
  end
  if rank == PRM.RANK_NONE
    body{igroup, 12} = '未判定';
  else
    body{igroup, 12} = PRM.GROUP_RANK_NAME{rank};
  end
  body{igroup, 13} = [note reason];
end

return
end
