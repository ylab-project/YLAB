function [btf, dtw, conwt, drank] = wtratioH(H, B, tw, tf, F, rank, isSNH)
  %wtratioH - H形鋼の幅厚比制約と判定ランクを計算

  if nargin <= 5
    rank = PRM.GIRDER_RANK_FA;
  end

  if nargin <= 6
    isSNH = false;
  end

  % 列ベクトルに整形
  H = H(:);
  B = B(:);
  tw = tw(:);
  tf = tf(:);
  F = F(:);

  % 計算の準備
  n = length(H);
  if isscalar(rank)
    rank = rank*ones(n,1);
  end
  if isscalar(F)
    F = F*ones(n,1);
  end
  sqF = sqrt(235./F);

  % 炭素鋼の幅厚比制限値（表12.3）
  % rf_tab(irank): フランジ係数、rw_tab(irank): ウェブ係数
  rf_tab = [9 11 15.5 100];
  rw_tab = [60 65 71 100];
  rf = zeros(n,1);
  rw = zeros(n,1);
  for irank = 1:4
    target = rank == irank;
    rf(target) = rf_tab(irank) * sqF(target);
    rw(target) = rw_tab(irank) * sqF(target);
  end

  % 幅厚比
  btf = B/2./tf;
  dtw = (H-2*tf)./tw;
  conwt = [btf./rf-1 dtw./rw-1];
  conwt = max(conwt,[],2);

  % 判定ランク（炭素鋼梁、表12.3）
  drank = PRM.GIRDER_RANK_FD * ones(n, 1);
  for irank = [PRM.GIRDER_RANK_FC PRM.GIRDER_RANK_FB ...
      PRM.GIRDER_RANK_FA]
    ok = btf <= rf_tab(irank)*sqF & dtw <= rw_tab(irank)*sqF;
    drank(ok) = irank;
  end

  if all(~isSNH)
    return
  end

  % SN鋼材の相関判定定数（表12.4）
  % get_sn_girder_constants で一括取得し、制約・判定で共用
  kf = zeros(n,1); kw = zeros(n,1); kc = zeros(n,1);
  for irank = 1:3
    [kf_, kw_, kc_] = get_sn_girder_constants(irank, F, n);
    target = rank == irank;
    kf(target) = kf_(target);
    kw(target) = kw_(target);
    kc(target) = kc_(target);
  end

  % 相関関係を考慮した幅厚比制限値（制約用）
  sqF98 = sqrt(F/98);
  conwt2 = [btf.^2./kf.^2.*(F/98) ...
    + dtw.^2./kw.^2.*(F/98) - 1 ...
    dtw - kc./sqF98];
  conwt2 = max(conwt2,[],2);
  conwt(isSNH) = conwt2(isSNH);

  % SN材の判定ランク（表12.4、式12.10）
  drank_sn = PRM.GIRDER_RANK_FD * ones(n, 1);
  for irank = [PRM.GIRDER_RANK_FC PRM.GIRDER_RANK_FB ...
      PRM.GIRDER_RANK_FA]
    [kf_, kw_, kc_] = get_sn_girder_constants(irank, F, n);
    corr = btf.^2./kf_.^2.*(F/98) + dtw.^2./kw_.^2.*(F/98);
    ok = corr <= 1 & dtw <= kc_./sqF98;
    drank_sn(ok) = irank;
  end
  drank(isSNH) = drank_sn(isSNH);

  return
end

function [kf, kw, kc] = get_sn_girder_constants(irank, F, n)
%get_sn_girder_constants - SN鋼材H形梁の相関判定定数
  kf = zeros(n,1); kw = zeros(n,1); kc = zeros(n,1);
  switch irank
    case PRM.GIRDER_RANK_FA
      kf(F==235) = 22; kw(F==235) = 144; kc(F==235) = 100;
      kf(F==325) = 26; kw(F==325) = 118; kc(F==325) = 100;
    case PRM.GIRDER_RANK_FB
      kf(F==235) = 27; kw(F==235) = 175; kc(F==235) = 100;
      kf(F==325) = 33; kw(F==325) = 147; kc(F==325) = 100;
    case PRM.GIRDER_RANK_FC
      kf(F==235) = 32; kw(F==235) = 209; kc(F==235) = 110;
      kf(F==325) = 40; kw(F==325) = 180; kc(F==325) = 110;
  end

  return
end
