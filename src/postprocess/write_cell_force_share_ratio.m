function [head, body] = write_cell_force_share_ratio(com, result, ilc)
%write_cell_force_share_ratio - 水平力分担表の出力
%
%   [head, body] = write_cell_force_share_ratio(com, result, ilc)
%   は、指定荷重ケースの水平力分担表を生成する。Qc/Qw/Qcw 等の数値は
%   result.frame_shear_ratio から読み取り、本関数は表示符号の付与と
%   書式整形のみを行う(計算は分析層 calc_frame_shear_ratio が担う)。
%
%   入力引数:
%     com    - 共通オブジェクト
%     result - 解析結果(frame_shear_ratio を含む)
%     ilc    - 荷重ケース番号
%
%   出力引数:
%     head - ヘッダセル配列 [3×18]
%     body - データセル配列 [nrow×19]（最終列は CONT_MARKER）

nstory = com.nstory;
lcdir = com.loadcase.dir;

% 加力方向に応じた表示符号とフレーム名(表示用の参照のみ)
switch lcdir(ilc)
  case PRM.EXP
    sign_dir = -1;
    frame_names = com.baseline.y.name;
  case PRM.EXN
    sign_dir = 1;
    frame_names = com.baseline.y.name;
  case PRM.EYP
    sign_dir = -1;
    frame_names = com.baseline.x.name;
  case PRM.EYN
    sign_dir = 1;
    frame_names = com.baseline.x.name;
  otherwise
    head = {};
    body = {};
    return
end

% 分析層の正本(各階・フレーム・荷重ケースの集計値)
fsr = result.frame_shear_ratio;
nframe = fsr.nframe(ilc);

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

  % 出力対象階以外（ダミー階直上）はスキップ
  if ~fsr.is_output_story(ist)
    continue
  end

  % 基礎レベル（層せん断力ゼロ）はスキップ
  if fsr.Qcw_total(ist, ilc) == 0
    continue
  end

  story_name = com.story.floor_name{ist};

  % フレーム行
  for ifr = 1:nframe
    irow = irow + 1;

    % 階名は最初のフレームのみ
    if ifr == 1
      body{irow, 1} = story_name;
    else
      body{irow, 1} = '';
    end
    body{irow, 2} = frame_names{ifr};
    % 加力方向に応じた符号変換（+0で-0除去）
    body{irow, 3} = sprintf('%.1f', sign_dir * fsr.Qc(ist, ifr, ilc) + 0);
    body{irow, 4} = sprintf('%.1f', sign_dir * fsr.Qw(ist, ifr, ilc) + 0);
    body{irow, 5} = sprintf('%.1f', sign_dir * fsr.Qcw(ist, ifr, ilc) + 0);
    body{irow, 6} = '0.0';   % QR
    body{irow, 7} = '0.0';   % QG
    body{irow, 8} = '0.0';   % QS
    % 比率は符号不変（+0で-0除去）
    body{irow, 9} = sprintf('%.1f', fsr.Qc_Qcw(ist, ifr, ilc) * 100 + 0);
    body{irow, 10} = sprintf('%.1f', fsr.Qw_Qcw(ist, ifr, ilc) * 100 + 0);
    body{irow, 11} = '0.0';  % QR/ΣQ
    body{irow, 12} = '0.0';  % QG/ΣQ
    body{irow, 13} = '0.0';  % QS/ΣQ
    body{irow, 14} = sprintf('%.1f', fsr.frame_ratio(ist, ifr, ilc) * 100);
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
  body{irow, 3} = sprintf('%.1f', sign_dir * fsr.Qc_total(ist, ilc) + 0);
  body{irow, 4} = sprintf('%.1f', sign_dir * fsr.Qw_total(ist, ilc) + 0);
  body{irow, 5} = sprintf('%.1f', sign_dir * fsr.Qcw_total(ist, ilc) + 0);
  body{irow, 6} = '0.0';
  body{irow, 7} = '0.0';
  body{irow, 8} = '0.0';
  body{irow, 9} = sprintf('%.1f', fsr.Qc_Qcw_total(ist, ilc) * 100 + 0);
  body{irow, 10} = sprintf('%.1f', fsr.Qw_Qcw_total(ist, ilc) * 100 + 0);
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
