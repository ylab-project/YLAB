function [bt, conwt, drank] = wtratioBox(D, t, F, rank)
%wtratioBox - 角形鋼管の幅厚比制約と判定ランクを計算
%
%   [bt, conwt, drank] = wtratioBox(D, t, F, rank) は、角形鋼管柱の
%   幅厚比D/tから指定種別の制約値と満たす最上位種別を返す。
%   制限値にはSS7計算編 表12.1を用いる。
%
%   入力引数:
%     D, t - 断面の幅・板厚 [n×1] mm
%     F    - 基準強度 [n×1] N/mm2
%     rank - 制約に用いる部材種別 [n×1] またはスカラー。省略時はFB
%
%   出力引数:
%     bt    - 幅厚比D/t [n×1]
%     conwt - 制限値との比-1 [n×1]。FDは制約なし（-1）
%     drank - 判定ランク（FA=1～FD=4）[n×1]

  if nargin == 3
    rank = PRM.MEMBER_RANK_FB;
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

  % 制約用幅厚比制限値（表12.1、FA・FB・FCの順。FDは制約なし）
  r_tab = [33 37 48];
  r = zeros(n, 1);
  for irank = 1:3
    target = rank == irank;
    r(target) = r_tab(irank) * sqF(target);
  end

  % 幅厚比
  bt = D./t;
  conwt = bt./r - 1;
  conwt(rank == PRM.MEMBER_RANK_FD) = -1;  % FDは制約なし

  % 判定ランク（表12.1 角形鋼管柱）
  drank = PRM.MEMBER_RANK_FD * ones(n, 1);
  drank(bt <= r_tab(3)*sqF) = PRM.MEMBER_RANK_FC;
  drank(bt <= r_tab(2)*sqF) = PRM.MEMBER_RANK_FB;
  drank(bt <= r_tab(1)*sqF) = PRM.MEMBER_RANK_FA;

  return
end
