function beta = calc_brace_force_share_ratio(com, rs0, cxl, cyl, Q_nb)
%calc_brace_force_share_ratio - ブレース水平力分担率βを算出
%
%   beta = calc_brace_force_share_ratio(com, rs0, cxl, cyl, Q_nb)
%   は、各層・各荷重ケースについてブレース水平力分担率βを算出する。
%   ブレース負担せん断力Qbは名目ブレースごとのQ値（Q_nb）を層ごとに
%   集計して求める。
%
%   入力引数:
%     com  - 共通オブジェクト
%     rs0  - 部材応力（重ね合わせ前）[nme×13×nlc]
%     cxl  - 部材x軸方向余弦 [nme×3]
%     cyl  - 部材y軸方向余弦 [nme×3]
%     Q_nb - 名目ブレースごとのQ値 [nnb×nlc] (N)
%
%   出力引数:
%     beta - ブレース水平力分担率 [nstory×nlc]

% 定数
nstory = com.nstory;
lcdir = com.loadcase.dir;
nlc = length(lcdir);

% 部材データ
mp = com.member.property;
mtype = mp.type;
midstory = mp.idstory;

% z軸方向余弦
czl = cross(cxl, cyl, 2);

% 断面位置補正係数
sign_cz = ones(size(cxl, 1), 1);
sign_cz(cxl(:, 3) < 0) = -1;

% 結果配列
beta = zeros(nstory, nlc);

% ブレースがない場合は終了
if com.nmeb == 0
  return
end

% 柱種別による層せん断力の加算対象判定
% 標準柱とブレース柱BODY（上側分割柱）のみ加算
% ブレース柱FOUNDATION（下側分割柱）はブレース反力の
% 中継要素のため除外
column = com.member.column;
col_type = zeros(size(mtype));
is_col = (mtype == PRM.COLUMN);
col_type(is_col) = column.type(mp.idmec(is_col));
is_target_col = is_col & (col_type == PRM.COLUMN_STANDARD ...
  | col_type == PRM.COLUMN_FOR_BRACE_BODY);

% 名目ブレースの階インデックス
nb_idstory = com.nominal.brace.idstory;

% ダミー層→従属層のマップ
isdummy = com.story.isdummy;
id_dep = com.story.id_dependent_story;

% 地震荷重ケースごとに計算
for ilc = 1:nlc
  % 加力方向の判定
  switch lcdir(ilc)
    case {PRM.EXP, PRM.EXN}
      idir_eq = 1;  % X方向
    case {PRM.EYP, PRM.EYN}
      idir_eq = 2;  % Y方向
    otherwise
      continue  % 長期は対象外
  end

  % 柱の水平力成分（加力方向）
  N = rs0(:, 1, ilc);
  Qy = rs0(:, 2, ilc);
  Qz = rs0(:, 3, ilc);
  Fh_col = (N .* cxl(:, idir_eq) ...
    + Qy .* cyl(:, idir_eq) ...
    + Qz .* czl(:, idir_eq)) .* sign_cz;

  % 層ごとに集計
  for ist = 1:nstory
    % 柱の水平力（標準柱・ブレース柱BODYのみ）
    idx_col = is_target_col & (midstory == ist);
    Qc = sum(Fh_col(idx_col));

    % ブレースの水平力（Q_nbを層集計）
    Qb = sum(Q_nb(nb_idstory == ist, ilc));

    % 層せん断力
    Qi = Qc + Qb;

    % β = ブレース負担率
    if abs(Qi) > 0
      beta(ist, ilc) = Qb / Qi;
    end
  end

  % ダミー層のβを従属層に伝搬（柱座屈長さ補正がダミー境界で
  % ブレース寄与を拾えるようにする）。abs大を残すことで、ブレース
  % ありの層の値が優先される。
  for ist_dum = 1:nstory
    if ~isdummy(ist_dum), continue; end
    ist_dep = id_dep(ist_dum);
    if ist_dep <= 0 || ist_dep > nstory, continue; end
    if abs(beta(ist_dum, ilc)) > abs(beta(ist_dep, ilc))
      beta(ist_dep, ilc) = beta(ist_dum, ilc);
    end
  end
end

return
end
