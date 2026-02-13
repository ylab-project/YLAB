function beta = calc_brace_force_share_ratio(com, result)
%calc_brace_force_share_ratio - ブレース水平力分担率βを算出

% 定数
nstory = com.nstory;
lcdir = com.loadcase.dir;
nlc = length(lcdir);

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
% i端が下端(cz>0)なら+1、上端(cz<0)なら-1
cz = cxl(:, 3);
sign_cz = ones(size(cz));
sign_cz(cz < 0) = -1;

% 部材応力（重ね合わせ前）
rs0 = result.rs0;

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
is_target_col = is_col ...
  & (col_type == PRM.COLUMN_STANDARD ...
    | col_type == PRM.COLUMN_FOR_BRACE_BODY);

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

  % i端の部材応力
  N = rs0(:, 1, ilc);   % 軸力
  Qy = rs0(:, 2, ilc);  % せん断力（強軸）
  Qz = rs0(:, 3, ilc);  % せん断力（弱軸）

  % 部材の水平力成分（加力方向）
  % 局所座標→全体座標変換 × 断面位置補正
  Fh = (N .* cxl(:, idir_eq) ...
    + Qy .* cyl(:, idir_eq) ...
    + Qz .* czl(:, idir_eq)) .* sign_cz;

  % ブレースのフィルタ条件
  is_brace = (mtype == PRM.BRACE);
  if idir_eq == 1
    is_target_brace = is_brace ...
      & (midir == PRM.X | midir == PRM.XY);
  else
    is_target_brace = is_brace ...
      & (midir == PRM.Y | midir == PRM.XY);
  end

  % 層ごとに集計
  for ist = 1:nstory
    % 柱の水平力（標準柱・ブレース柱BODYのみ）
    idx_col = is_target_col ...
      & (midstory == ist);
    Qc = sum(Fh(idx_col));

    % ブレースの水平力
    idx_br = is_target_brace ...
      & (midstory == ist);
    Qb = sum(Fh(idx_br));

    % 層せん断力
    Qi = Qc + Qb;

    % β = ブレース負担率
    if abs(Qi) > 0
      beta(ist, ilc) = Qb / Qi;
    end
  end
end

return
end
