function [head, body] = ...
  write_cell_force_share_ratio(com, result, ilc)
%write_cell_force_share_ratio - 水平力分担表の出力

% 定数
nstory = com.nstory;
lcdir = com.loadcase.dir;

% 加力方向の判定
switch lcdir(ilc)
  case {PRM.EXP, PRM.EXN}
    idir_eq = 1;  % X方向 → Y通りで集計
    nframe = com.nbly;
    frame_names = com.baseline.y.name;
  case {PRM.EYP, PRM.EYN}
    idir_eq = 2;  % Y方向 → X通りで集計
    nframe = com.nblx;
    frame_names = com.baseline.x.name;
  otherwise
    head = {};
    body = {};
    return
end

% 部材データ
mp = com.member.property;
cxl = mp.cxl;
cyl = mp.cyl;
mtype = mp.type;
midstory = mp.idstory;
midir = mp.idir;

% z軸方向余弦
czl = cross(cxl, cyl, 2);

% 断面位置補正係数
cz = cxl(:, 3);
sign_cz = ones(size(cz));
sign_cz(cz < 0) = -1;

% 部材応力（重ね合わせ前）
rs0 = result.rs0;
N = rs0(:, 1, ilc);
Qy = rs0(:, 2, ilc);
Qz = rs0(:, 3, ilc);

% 部材の水平力成分（加力方向）[N→kN]
Fh = (N .* cxl(:, idir_eq) ...
  + Qy .* cyl(:, idir_eq) ...
  + Qz .* czl(:, idir_eq)) .* sign_cz / 1000;

% 柱種別による層せん断力の加算対象判定
column = com.member.column;
col_type = zeros(size(mtype));
is_col = (mtype == PRM.COLUMN);
col_type(is_col) = ...
  column.type(mp.idmec(is_col));
is_target_col = is_col ...
  & (col_type == PRM.COLUMN_STANDARD ...
    | col_type == PRM.COLUMN_FOR_BRACE_BODY);

% ブレースのフィルタ条件
is_brace = (mtype == PRM.BRACE);
if idir_eq == 1
  is_target_brace = is_brace ...
    & (midir == PRM.X | midir == PRM.XY);
else
  is_target_brace = is_brace ...
    & (midir == PRM.Y | midir == PRM.XY);
end

% 柱のフレーム通りインデックス
col_idframe = zeros(size(mtype));
if idir_eq == 1
  col_idframe(is_col) = ...
    column.idy(mp.idmec(is_col), 1);
else
  col_idframe(is_col) = ...
    column.idx(mp.idmec(is_col), 1);
end

% ブレースのフレーム通りインデックス
brace = com.member.brace;
br_idframe = zeros(size(mtype));
if idir_eq == 1
  br_idframe(is_brace) = ...
    brace.idy(mp.idmeb(is_brace), 1);
else
  br_idframe(is_brace) = ...
    brace.idx(mp.idmeb(is_brace), 1);
end

% ヘッダ
head = { ...
  '階', 'ﾌﾚｰﾑ', 'Qc', 'Qw', 'Qcw', ...
  'Qc/Qcw', 'Qw/Qcw', '負担率'; ...
  '', '', 'kN', 'kN', 'kN', ...
  '', '', ''};

% データ行
ncol = 8;
maxrows = nstory * (nframe + 1);
body = cell(maxrows, ncol);
irow = 0;

for i = 1:nstory
  ist = nstory - i + 1;
  story_name = com.story.name{ist};

  % フレームごとのQc, Qw
  Qc_frame = zeros(nframe, 1);
  Qw_frame = zeros(nframe, 1);

  for ifr = 1:nframe
    % 柱の水平力
    idx_c = is_target_col ...
      & (midstory == ist) ...
      & (col_idframe == ifr);
    Qc_frame(ifr) = sum(Fh(idx_c));

    % ブレースの水平力
    idx_b = is_target_brace ...
      & (midstory == ist) ...
      & (br_idframe == ifr);
    Qw_frame(ifr) = sum(Fh(idx_b));
  end

  % 絶対値（抵抗力を正値で表示）
  Qc_frame = abs(Qc_frame);
  Qw_frame = abs(Qw_frame);

  % 層合計
  Qc_total = sum(Qc_frame);
  Qw_total = sum(Qw_frame);
  Qcw_total = Qc_total + Qw_total;

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
    body{irow, 3} = sprintf('%.1f', ...
      Qc_frame(ifr));
    body{irow, 4} = sprintf('%.1f', ...
      Qw_frame(ifr));
    body{irow, 5} = sprintf('%.1f', Qcw_fr);
    if Qcw_fr > 0
      body{irow, 6} = sprintf('%.1f%%', ...
        Qc_frame(ifr) / Qcw_fr * 100);
      body{irow, 7} = sprintf('%.1f%%', ...
        Qw_frame(ifr) / Qcw_fr * 100);
    else
      body{irow, 6} = '-';
      body{irow, 7} = '-';
    end
    if Qcw_total > 0
      body{irow, 8} = sprintf('%.1f%%', ...
        Qcw_fr / Qcw_total * 100);
    else
      body{irow, 8} = '-';
    end
  end

  % 合計行
  irow = irow + 1;
  body{irow, 1} = '';
  body{irow, 2} = '合計';
  body{irow, 3} = sprintf('%.1f', Qc_total);
  body{irow, 4} = sprintf('%.1f', Qw_total);
  body{irow, 5} = sprintf('%.1f', Qcw_total);
  if Qcw_total > 0
    body{irow, 6} = sprintf('%.1f%%', ...
      Qc_total / Qcw_total * 100);
    body{irow, 7} = sprintf('%.1f%%', ...
      Qw_total / Qcw_total * 100);
  else
    body{irow, 6} = '-';
    body{irow, 7} = '-';
  end
  body{irow, 8} = '100.0%';
end

% 空行を削除
body = body(1:irow, :);

return
end
