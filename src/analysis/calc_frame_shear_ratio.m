function frame_shear_ratio = calc_frame_shear_ratio(com, rs_force, ...
  cxl, cyl, Q_nb, brace_in_story)
%calc_frame_shear_ratio - 水平力分担表相当の階別・フレーム別集計
%
%   frame_shear_ratio = calc_frame_shear_ratio(com, rs_force, cxl, ...
%   cyl, Q_nb, brace_in_story) は、各階・各フレーム・各荷重ケースの
%   柱負担水平力Qc・ブレース負担水平力Qwとそれらの比率を集計する。
%   水平力分担表出力と柱座屈長さ係数補正βが共通参照する正本となる。
%   柱水平力は解析基底の部材力を加力方向へ水平投影して集計する。
%   出力対象階(is_output_story)とその参照階(output_idstory)も返す。
%
%   入力引数:
%     com            - 共通オブジェクト
%     rs_force       - 部材応力(重ね合わせ前、解析基底) [nme×12×nlc]
%     cxl            - 部材x軸方向余弦 [nme×3]
%     cyl            - 部材y軸方向余弦 [nme×3]
%     Q_nb           - 名目ブレースごとのQ値 [nnb×nlc] (N)
%     brace_in_story - 名目ブレースの跨ぐ階 [nnb×nstory] logical
%
%   出力引数:
%     frame_shear_ratio - 階別・フレーム別集計 (struct)。
%       Qc/Qw/Qcw       : [story×frame×lc] 負担水平力 (kN, FEM符号)
%       Qc_total等       : [story×lc] 層合計負担水平力 (kN, FEM符号)
%       Qc_Qcw/Qw_Qcw   : [story×frame×lc] フレーム別負担率
%       Qc_Qcw_total等   : [story×lc] 層合計負担率
%       frame_ratio     : [story×frame×lc] フレーム別負担率(対層合計)
%       frame_name      : [frame×1] 表示用フレーム名(Y通り, X通り)
%       is_output_story : [story×1] 水平力分担表に出す階か
%       output_idstory  : [story×1] 柱座屈長さ補正が参照する出力階
%       nframe          : [lc×1] 各荷重ケースの有効フレーム数

% 定数
nstory = com.nstory;
lcdir = com.loadcase.dir;
nlc = length(lcdir);
nbly = com.nbly;
nblx = com.nblx;
nframe_report = nbly + nblx;
frame_name = [com.baseline.y.name(:); com.baseline.x.name(:)];

% 部材データ
mp = com.member.property;
mtype = mp.type;
midstory = mp.idstory;

% 断面位置補正係数
sign_cz = ones(size(cxl, 1), 1);
sign_cz(cxl(:, 3) < 0) = -1;

% 局所z軸方向余弦
czl = cross(cxl, cyl, 2);

% 柱種別による加算対象判定(標準柱・ブレース柱BODYのみ)
column = com.member.column;
col_type = zeros(size(mtype));
is_col = (mtype == PRM.COLUMN);
col_type(is_col) = column.type(mp.idmec(is_col));
is_target_col = is_col & (col_type == PRM.COLUMN_STANDARD ...
  | col_type == PRM.COLUMN_FOR_BRACE_BODY);

% 柱のフレーム通りインデックス(X加力=Y通り, Y加力=X通り)
col_idy = zeros(size(mtype));
col_idx = zeros(size(mtype));
col_idy(is_col) = column.idy(mp.idmec(is_col), 1);
col_idx(is_col) = column.idx(mp.idmec(is_col), 1);

% 名目ブレースのフレーム通りインデックス
nnb = size(Q_nb, 1);
if nnb > 0
  nb = com.nominal.brace;
  nb_idy = nb.idy(:, 1);
  nb_idx = nb.idx(:, 1);
else
  nb_idy = zeros(0, 1);
  nb_idx = zeros(0, 1);
end

% 結果配列の確保
Qc = zeros(nstory, nframe_report, nlc);
Qw = zeros(nstory, nframe_report, nlc);
Qcw = zeros(nstory, nframe_report, nlc);
Qc_total = zeros(nstory, nlc);
Qw_total = zeros(nstory, nlc);
Qcw_total = zeros(nstory, nlc);
Qc_Qcw = zeros(nstory, nframe_report, nlc);
Qw_Qcw = zeros(nstory, nframe_report, nlc);
Qc_Qcw_total = zeros(nstory, nlc);
Qw_Qcw_total = zeros(nstory, nlc);
frame_ratio = zeros(nstory, nframe_report, nlc);
nframe = zeros(nlc, 1);

% ブレースの跨ぐ階はループ不変。find は一度だけ実行し、加力方向で
% 変わる f_col のみループ内で引く。名目ブレースが1本のときは
% brace_in_story が行ベクトルとなり find が行ベクトルを返すため、
% accumarray の添字行列が崩れないよう列ベクトルに揃える。
[b_row, s_col] = find(brace_in_story);
b_row = b_row(:);
s_col = s_col(:);

% 荷重ケースごとに集計(地震ケースのみ。長期は0のまま)
for ilc = 1:nlc
  switch lcdir(ilc)
    case {PRM.EXP, PRM.EXN}
      idir_eq = 1;
      nfr_main = nbly;
      main_offset = 0;
      col_idmain = col_idy;
      nb_idframe = nb_idy;
    case {PRM.EYP, PRM.EYN}
      idir_eq = 2;
      nfr_main = nblx;
      main_offset = nbly;
      col_idmain = col_idx;
      nb_idframe = nb_idx;
    otherwise
      continue
  end
  nframe(ilc) = nframe_report;

  % 柱の水平力成分(kN, FEM符号)
  % 解析基底の軸力・局所せん断を加力方向へ水平投影する。
  N = rs_force(:, 1, ilc);
  Qy = rs_force(:, 2, ilc);
  Qz = rs_force(:, 3, ilc);
  Fh_col = (N .* cxl(:, idir_eq) ...
    + Qy .* cyl(:, idir_eq) ...
    + Qz .* czl(:, idir_eq)) .* sign_cz / 1000;

  % フレーム別の柱負担水平力を集計
  sel_c = is_target_col & midstory >= 1 & midstory <= nstory ...
    & col_idmain >= 1 & col_idmain <= nfr_main;
  if any(sel_c)
    Qc(:, :, ilc) = Qc(:, :, ilc) ...
      + accumarray([midstory(sel_c), main_offset + col_idmain(sel_c)], ...
      Fh_col(sel_c), [nstory, nframe_report]);
  end
  % ブレースの水平力(跨ぐ階に計上, kN)
  Qb_nb = Q_nb(:, ilc) / 1000;
  f_col = main_offset + nb_idframe(b_row);
  sel_b = f_col >= 1 & f_col <= nframe_report ...
    & s_col >= 1 & s_col <= nstory;
  if any(sel_b)
    Qw(:, :, ilc) = accumarray([s_col(sel_b), f_col(sel_b)], ...
      Qb_nb(b_row(sel_b)), [nstory, nframe_report]);
  end

  Qcw(:, :, ilc) = Qc(:, :, ilc) + Qw(:, :, ilc);
  Qc_total(:, ilc) = sum(Qc(:, :, ilc), 2);
  Qw_total(:, ilc) = sum(Qw(:, :, ilc), 2);
  Qcw_total(:, ilc) = Qc_total(:, ilc) + Qw_total(:, ilc);

  % 負担率の算定(分母0は0のまま)
  qcw = Qcw(:, :, ilc);
  qc = Qc(:, :, ilc);
  qw = Qw(:, :, ilc);
  mask = qcw ~= 0;
  qc_qcw = zeros(nstory, nframe_report);
  qw_qcw = zeros(nstory, nframe_report);
  qc_qcw(mask) = qc(mask) ./ qcw(mask);
  qw_qcw(mask) = qw(mask) ./ qcw(mask);
  Qc_Qcw(:, :, ilc) = qc_qcw;
  Qw_Qcw(:, :, ilc) = qw_qcw;

  tot = Qcw_total(:, ilc);
  mt = tot ~= 0;
  frame_ratio(mt, :, ilc) = qcw(mt, :) ./ tot(mt);
  Qc_Qcw_total(mt, ilc) = Qc_total(mt, ilc) ./ tot(mt);
  Qw_Qcw_total(mt, ilc) = Qw_total(mt, ilc) ./ tot(mt);
end

% 出力対象階と参照階の判定
% 出力対象階: 直下の階がダミーでない階(水平力分担表に出す階)
% 参照階: 各内部storyが柱座屈長さ補正で参照する出力階(自身以下で
% 最も上の出力対象階)
isdummy = com.story.isdummy;
is_output_story = true(nstory, 1);
for ist = 2:nstory
  if isdummy(ist - 1)
    is_output_story(ist) = false;
  end
end
output_idstory = zeros(nstory, 1);
last_out = 1;
for ist = 1:nstory
  if is_output_story(ist)
    last_out = ist;
  end
  output_idstory(ist) = last_out;
end

% 構造体へ格納
frame_shear_ratio.Qc = Qc;
frame_shear_ratio.Qw = Qw;
frame_shear_ratio.Qcw = Qcw;
frame_shear_ratio.Qc_total = Qc_total;
frame_shear_ratio.Qw_total = Qw_total;
frame_shear_ratio.Qcw_total = Qcw_total;
frame_shear_ratio.Qc_Qcw = Qc_Qcw;
frame_shear_ratio.Qw_Qcw = Qw_Qcw;
frame_shear_ratio.Qc_Qcw_total = Qc_Qcw_total;
frame_shear_ratio.Qw_Qcw_total = Qw_Qcw_total;
frame_shear_ratio.frame_ratio = frame_ratio;
frame_shear_ratio.frame_name = frame_name;
frame_shear_ratio.is_output_story = is_output_story;
frame_shear_ratio.output_idstory = output_idstory;
frame_shear_ratio.nframe = nframe;

return
end
