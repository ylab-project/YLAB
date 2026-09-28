function [btf, dtw, conwt, drank] = wtratioH(H, B, tw, tf, F, rank, ...
  isSNH, mtype)
%wtratioH - H形鋼の幅厚比制約と判定ランクを計算
%
%   [btf, dtw, conwt, drank] = wtratioH(H, B, tw, tf, F, rank, isSNH,
%   mtype) は、H形鋼のフランジ幅厚比 b/tf（b＝B/2）とウェブ幅厚比
%   d/tw（d＝H−2tf）から、指定した部材種別 rank に対する制約値と、
%   満たす最も厳しい部材種別（判定ランク FA～FD）を計算する。
%   制限値は梁がSS7計算編 表12.3、柱が表12.1で、SN材のH形鋼（isSNH）
%   は相関判定（梁は式12.10・表12.4、柱は式12.9・表12.2）を用いる。
%
%   入力引数:
%     H, B, tw, tf - 断面寸法 [n×1] mm
%     F     - 基準強度 [n×1] またはスカラー N/mm2
%     rank  - 制約に用いる部材種別（FA=1～FD=4）[n×1] またはスカラー
%     isSNH - SN材の相関判定を用いるか [n×1] logical またはスカラー
%     mtype - 部材の区分（PRM.GIRDER または PRM.COLUMN）
%
%   出力引数:
%     btf   - フランジ幅厚比 b/tf [n×1]
%     dtw   - ウェブ幅厚比 d/tw [n×1]
%     conwt - 幅厚比制約値（0以下で満足）[n×1]。FDは制約なし（-1）
%     drank - 判定ランク（FA=1～FD=4）[n×1]

  % 列ベクトルに整形
  H = H(:);
  B = B(:);
  tw = tw(:);
  tf = tf(:);
  F = F(:);

  % 計算の準備
  n = length(H);
  if isscalar(rank)
    rank = repmat(rank, n, 1);
  end
  if isscalar(F)
    F = repmat(F, n, 1);
  end
  if isscalar(isSNH)
    isSNH = repmat(isSNH, n, 1);
  end
  sqF = sqrt(235./F);
  sqF98 = sqrt(F/98);

  % 幅厚比の制限値（炭素鋼、列はFA・FB・FCの順。FDは制約なし）と
  % SN材の相関判定定数。表は梁と柱で異なる
  [rf_tab, rw_tab, kf_tab, kw_tab, kc_tab, rank_fd] = ...
    wtratio_h_limits(mtype);

  % 幅厚比
  btf = B/2./tf;
  dtw = (H-2*tf)./tw;

  % 部材種別ごとの制約値（0以下で満足）。炭素鋼は制限値との比、SN材は
  % 相関判定（式12.9・12.10）。FCからFAへ順に評価し、指定した部材種別
  % の値を制約に、満たす最も厳しい部材種別を判定ランクに残す
  conwt = -ones(n, 1);
  drank = rank_fd * ones(n, 1);
  for irank = 3:-1:1
    con = max(btf./(rf_tab(irank)*sqF) - 1, dtw./(rw_tab(irank)*sqF) - 1);
    if any(isSNH)
      kf = sn_constant(kf_tab, irank, F);
      kw = sn_constant(kw_tab, irank, F);
      kc = sn_constant(kc_tab, irank, F);
      con_sn = max(btf.^2./kf.^2.*(F/98) + dtw.^2./kw.^2.*(F/98) - 1, ...
        dtw - kc./sqF98);
      con(isSNH) = con_sn(isSNH);
    end
    target = rank == irank;
    conwt(target) = con(target);
    drank(con <= 0) = irank;
  end

  return
end

function [rf_tab, rw_tab, kf_tab, kw_tab, kc_tab, rank_fd] = ...
  wtratio_h_limits(mtype)
%wtratio_h_limits - H形鋼の幅厚比制限値とSN材の相関判定定数の表を返す
%
%   列はFA・FB・FCの順。rf_tab・rw_tab はフランジ・ウェブの制限値の
%   √(235/F)に対する係数、kf_tab・kw_tab・kc_tab はSN400（1行目）と
%   SN490（2行目）の定数で、kf_tab は梁と柱で同じ。柱はSS7計算編
%   表12.1・12.2、梁は表12.3・12.4
  kf_tab = [22 27 32; 26 33 40];
  if mtype == PRM.COLUMN
    rf_tab = [9.5 12 15.5];
    rw_tab = [43 45 48];
    kw_tab = [71 87 104; 63 77 94];
    kc_tab = [71 71 74; 71 71 74];
    rank_fd = PRM.COLUMN_RANK_FD;
  else
    rf_tab = [9 11 15.5];
    rw_tab = [60 65 71];
    kw_tab = [144 175 209; 118 147 180];
    kc_tab = [100 100 110; 100 100 110];
    rank_fd = PRM.GIRDER_RANK_FD;
  end

  return
end

function v = sn_constant(tab, irank, F)
%sn_constant - SN材の定数を基準強度の行（235は1行目、325は2行目）から取る
  v = zeros(size(F));
  v(F == 235) = tab(1, irank);
  v(F == 325) = tab(2, irank);

  return
end
