function [bt, conwt, drank] = wtratioBox(D, t, F, rank)
  %wtratioBox - 角形鋼管の幅厚比制約と判定ランクを計算

  if nargin == 3
    rank = 2;
  end

  % 列ベクトルに整形
  D = D(:);
  t = t(:);
  F = F(:);
  n = length(D);
  sqF = sqrt(235./F);

  % ベクトルrank対応
  if isscalar(rank)
    rank = rank * ones(n, 1);
  end

  % 制約用幅厚比制限値（表12.1/12.3 角形鋼管、FA/FB/FCのみ。FDは制約なし）
  r_tab = [33 37 48];
  r = zeros(n, 1);
  for irank = 1:3
    target = rank == irank;
    r(target) = r_tab(irank) * sqF(target);
  end

  % 幅厚比
  bt = D./t;
  conwt = bt./r - 1;
  conwt(rank == PRM.COLUMN_RANK_FD) = -1;  % FDは制約なし

  % 判定ランク（表12.1 角形鋼管柱）
  drank = PRM.COLUMN_RANK_FD * ones(n, 1);
  drank(bt <= r_tab(3)*sqF) = PRM.COLUMN_RANK_FC;
  drank(bt <= r_tab(2)*sqF) = PRM.COLUMN_RANK_FB;
  drank(bt <= r_tab(1)*sqF) = PRM.COLUMN_RANK_FA;

  return
end
