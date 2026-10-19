function [head, body] = write_cell_column_girder_group_rank( ...
  com, result, options, ilc)
%write_cell_column_girder_group_rank - 柱・梁群の種別の推定帳票を作る
%
%   [head, body] = write_cell_column_girder_group_rank(com, result,
%   options, ilc) は、一次解析の水平力と幅厚比による部材種別から、
%   一般階の柱・梁群の種別を推定する。柱と接続梁の全方向の最下位を
%   採用し、FD部材を考慮する。接合部・横補剛・柱脚は評価しない。
%
%   入力引数:
%     com     - 階、部材、名目部材の対応
%     result  - 解析結果（Qm [N]、rank.sectionを使用）
%     options - 地下階数とPH階数を含む計算条件
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
nominal = com.nominal.property;
floor = com.floor;
idfloor = find(~floor.isdummy);
idfloor = idfloor(1+options.num_basement_floor: ...
  end-options.num_penthouse_floor);
idfloor = flip(idfloor);
ngroup = numel(idfloor);

% 断面の幅厚比による部材種別。drank0は補正前で主体構造欄の判定に
% 使う。drankは一本部材と接続梁による修正後で群種別の集計に使う
drank0 = result.rank.section(mp.idsec);
drank = drank0;

% 梁は一本部材を構成する区間の最下位にまとめる。柱は接続梁と
% 合わせて次のループでまとめる
for inm = find(nominal.mtype == PRM.GIRDER)'
  idme = nonzeros(nominal.idme(inm, :));
  drank(idme) = pick_lowest_rank(drank(idme));
end

% 柱の両端と内部節点に接続する梁を含めて種別を修正する。
% 屋根面・基礎梁も対象とし、幅厚比で評価できない部材は未判定とする
for inm = find(nominal.mtype == PRM.COLUMN)'
  idme = nonzeros(nominal.idme(inm, :));
  idnode = [mp.idnode1(idme); mp.idnode2(idme)];
  idmeg = find(mp.type == PRM.GIRDER & (ismember(mp.idnode1, idnode) ...
    | ismember(mp.idnode2, idnode)));
  drank(idme) = pick_lowest_rank(drank([idme; idmeg]));
end

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
  rank = PRM.RANK_NONE;
  reason = '';
  if isempty(idme)
    reason = '／対象部材なし';
  elseif any(drank(idme) == PRM.RANK_NONE)
    reason = '／種別未評価の部材あり';
  else
    % 数値集計と判定はN・丸め前の値で行う。割合の分母はFA～FCの
    % 合計Q（SS7計算編12.3.7）とし、FDを含むQ_totalはQ(合計)欄に使う
    Qrank = accumarray(drank(idme), result.Qm(idme, ilc), ...
      [numel(PRM.MEMBER_RANK_NAME) 1])';
    Q = sum(Qrank(1:3));
    Q_total = sum(Qrank);
    is_fd = drank(idme) == PRM.MEMBER_RANK_FD;
    if all(is_fd)
      % FA～FCの部材がなく分母に対象がない。SS7と同じ0表示にする
      body(igroup, [4 6 8]) = repmat({'0.000'}, 1, 3);
    elseif Q ~= 0
      ratio = Qrank(1:3) / Q;
      body(igroup, [4 6 8]) = arrayfun(@(r) sprintf('%.3f', r + 0), ...
        ratio, 'UniformOutput', false);
      if ratio(1) >= PRM.GROUP_RANK_A_MIN_RATIO ...
          && ratio(3) <= PRM.GROUP_RANK_A_MAX_C_RATIO
        rank = PRM.GROUP_RANK_A;
      elseif ratio(3) < PRM.GROUP_RANK_C_MIN_RATIO
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
      sign_dir * [Qrank(1:3), Q, Qrank(4), Q_total] / 1000 + 0, ...
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

function rank = pick_lowest_rank(ranks)
%pick_lowest_rank - 種別の組から最下位の種別を選ぶ
%
%   rank = pick_lowest_rank(ranks) は、FA～FDの種別の組から最下位を
%   返す。未評価（RANK_NONE）を含む場合は未評価を返し、RC梁などが
%   接続する柱をFA等へ仮定しない。
%
%   入力引数:
%     ranks - 部材種別 [n×1]（0=未評価、FA=1～FD=4）
%
%   出力引数:
%     rank - 最下位の種別、または未評価

if any(ranks == PRM.RANK_NONE)
  rank = PRM.RANK_NONE;
else
  rank = max(ranks);
end

return
end
