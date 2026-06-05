function [head, body] = write_cell_force_share_ratio(com, result, ilc)
%write_cell_force_share_ratio - 水平力分担表の出力
%
%   [head, body] = write_cell_force_share_ratio(com, result, ilc)
%   は、指定荷重ケースの水平力分担表を生成する。Qw（ブレース負担）は
%   result.Q_nbをフレーム・層ごとに集計して算出する。
%
%   入力引数:
%     com    - 共通オブジェクト
%     result - 解析結果（rs0, Q_nb, cxl, cylを含む）
%     ilc    - 荷重ケース番号
%
%   出力引数:
%     head - ヘッダセル配列 [3×18]
%     body - データセル配列 [nrow×19]（最終列は CONT_MARKER）

nstory = com.nstory;
lcdir = com.loadcase.dir;

% 加力方向の判定
switch lcdir(ilc)
  case PRM.EXP
    idir_eq = 1; sign_dir = -1;
    nframe = com.nbly;
    frame_names = com.baseline.y.name;
  case PRM.EXN
    idir_eq = 1; sign_dir = 1;
    nframe = com.nbly;
    frame_names = com.baseline.y.name;
  case PRM.EYP
    idir_eq = 2; sign_dir = -1;
    nframe = com.nblx;
    frame_names = com.baseline.x.name;
  case PRM.EYN
    idir_eq = 2; sign_dir = 1;
    nframe = com.nblx;
    frame_names = com.baseline.x.name;
  otherwise
    head = {};
    body = {};
    return
end

% --- 柱の水平力成分 ---
mp = com.member.property;
cxl = result.cxl;
cyl = result.cyl;
mtype = mp.type;
midstory = mp.idstory;

czl = cross(cxl, cyl, 2);
cz = cxl(:, 3);
sign_cz = ones(size(cz));
sign_cz(cz < 0) = -1;

rs0 = result.rs0;
N = rs0(:, 1, ilc);
Qy = rs0(:, 2, ilc);
Qz = rs0(:, 3, ilc);

Fh_col = (N .* cxl(:, idir_eq) + Qy .* cyl(:, idir_eq) ...
  + Qz .* czl(:, idir_eq)) .* sign_cz / 1000;

% 柱種別フィルタ
column = com.member.column;
col_type = zeros(size(mtype));
is_col = (mtype == PRM.COLUMN);
col_type(is_col) = column.type(mp.idmec(is_col));
is_target_col = is_col & (col_type == PRM.COLUMN_STANDARD ...
  | col_type == PRM.COLUMN_FOR_BRACE_BODY);

% 柱のフレーム通りインデックス
col_idframe = zeros(size(mtype));
if idir_eq == 1
  col_idframe(is_col) = column.idy(mp.idmec(is_col), 1);
else
  col_idframe(is_col) = column.idx(mp.idmec(is_col), 1);
end

% --- ブレースの水平力（Q_nbから集計）---
Q_nb = result.Q_nb(:, ilc) / 1000;  % N→kN
nb = com.nominal.brace;
% 跨ぐ階 membership は分析層で算出済み（result）。多層ブレースの水平力
% を跨ぐ各階に計上するため、配置階単一値ではなくこれを参照する。
brace_in_story = result.brace_in_story;

% 名目ブレースのフレーム通りインデックス
if idir_eq == 1
  nb_idframe = nb.idy(:, 1);
else
  nb_idframe = nb.idx(:, 1);
end

% ヘッダ（3行: 列名、副見出し、単位）
ncol = 18;
head = cell(3, ncol);
head(1, :) = {'階', 'ﾌﾚｰﾑ', 'Qc', 'Qw', 'Qcw', 'QR', 'QG', 'QS', ...
  'Qc/Qcw', 'Qw/Qcw', 'QR/ΣQ', 'QG/ΣQ', 'QS/ΣQ', '負担率', ...
  'δ', 'δ/h', 'ΣQ/δ', ''};
head(2, :) = {'', '', '', '', '', '', '', '', '', '', '', '', '', ...
  '', '', '', '水平ﾊﾞﾈ考慮', '水平ﾊﾞﾈなし'};
head(3, :) = {'', '', 'kN', 'kN', 'kN', 'kN', 'kN', 'kN', ...
  '%', '%', '%', '%', '%', '%', 'mm', '', 'kN/mm', 'kN/mm'};

maxrows = nstory * (nframe + 1);
body = cell(maxrows, ncol + 1);
irow = 0;

for i = 1:nstory
  ist = nstory - i + 1;

  % ダミー階はスキップ（SS7マニュアル 5.7: ダミー階は集計しない）
  % 階の下端がダミー層の場合、この階はダミー階扱い
  if ist > 1 && com.story.isdummy(ist-1)
    continue
  end

  story_name = com.story.floor_name{ist};

  % フレームごとのQc, Qw
  Qc_frame = zeros(nframe, 1);
  Qw_frame = zeros(nframe, 1);

  for ifr = 1:nframe
    % 柱の水平力
    idx_c = is_target_col & (midstory == ist) & (col_idframe == ifr);
    Qc_frame(ifr) = sum(Fh_col(idx_c));

    % ブレースの水平力（跨ぐ階に計上した Q_nb を集計）
    idx_nb = brace_in_story(:, ist) & (nb_idframe == ifr);
    Qw_frame(ifr) = sum(Q_nb(idx_nb));
  end

  % 層合計（FEM符号のまま）
  Qc_total = sum(Qc_frame);
  Qw_total = sum(Qw_frame);
  Qcw_total = Qc_total + Qw_total;

  % 基礎レベル（層せん断力ゼロ）はスキップ
  if Qcw_total == 0
    continue
  end

  % フレーム行
  for ifr = 1:nframe
    Qcw_fr = Qc_frame(ifr) + Qw_frame(ifr);
    irow = irow + 1;

    % 階名は最初のフレームのみ
    if ifr == 1
      body{irow, 1} = story_name;
    else
      body{irow, 1} = '';
    end
    body{irow, 2} = frame_names{ifr};
    % 加力方向に応じた符号変換（+0で-0除去）
    body{irow, 3} = sprintf('%.1f', sign_dir * Qc_frame(ifr) + 0);
    body{irow, 4} = sprintf('%.1f', sign_dir * Qw_frame(ifr) + 0);
    body{irow, 5} = sprintf('%.1f', sign_dir * Qcw_fr + 0);
    body{irow, 6} = '0.0';   % QR
    body{irow, 7} = '0.0';   % QG
    body{irow, 8} = '0.0';   % QS
    % 比率は符号不変（+0で-0除去）
    if abs(Qcw_fr) > 0
      body{irow, 9} = sprintf('%.1f', Qc_frame(ifr)/Qcw_fr*100 + 0);
      body{irow, 10} = sprintf('%.1f', Qw_frame(ifr)/Qcw_fr*100 + 0);
    else
      body{irow, 9} = '0.0';
      body{irow, 10} = '0.0';
    end
    body{irow, 11} = '0.0';  % QR/ΣQ
    body{irow, 12} = '0.0';  % QG/ΣQ
    body{irow, 13} = '0.0';  % QS/ΣQ
    if abs(Qcw_total) > 0
      body{irow, 14} = sprintf('%.1f', Qcw_fr / Qcw_total * 100);
    else
      body{irow, 14} = '0.0';
    end
    % δ, δ/h, ΣQ/δ は後続フェーズで実装
    body{irow, 15} = '';
    body{irow, 16} = '';
    body{irow, 17} = '';
    body{irow, 18} = '';
    body{irow, ncol + 1} = PRM.CONT_MARKER;
  end

  % 合計行
  irow = irow + 1;
  body{irow, 1} = '';
  body{irow, 2} = '合計';
  body{irow, 3} = sprintf('%.1f', sign_dir * Qc_total + 0);
  body{irow, 4} = sprintf('%.1f', sign_dir * Qw_total + 0);
  body{irow, 5} = sprintf('%.1f', sign_dir * Qcw_total + 0);
  body{irow, 6} = '0.0';
  body{irow, 7} = '0.0';
  body{irow, 8} = '0.0';
  if abs(Qcw_total) > 0
    body{irow, 9} = sprintf('%.1f', Qc_total / Qcw_total * 100 + 0);
    body{irow, 10} = sprintf('%.1f', Qw_total / Qcw_total * 100 + 0);
  else
    body{irow, 9} = '0.0';
    body{irow, 10} = '0.0';
  end
  body{irow, 11} = '0.0';
  body{irow, 12} = '0.0';
  body{irow, 13} = '0.0';
  body{irow, 14} = '100.0';
  body{irow, 15} = '';
  body{irow, 16} = '';
  body{irow, 17} = '';
  body{irow, 18} = '';
end

% 空行を削除
body = body(1:irow, :);

return
end
