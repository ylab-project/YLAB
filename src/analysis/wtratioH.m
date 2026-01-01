function [btf, dtw, conwt] = wtratioH(H, B, tw, tf, F, rank, isSNH)
  %WTRATIOH ...
  %   ...
  
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
  rf = zeros(n,1);
  rw = zeros(n,1);
  
  % 制限値の計算
  for irank=1:4
    switch irank
      case PRM.GIRDER_RANK_FA
        % FA材
        rf_ = 9*sqrt(235./F);
        rw_ = 60*sqrt(235./F);
      case PRM.GIRDER_RANK_FB
        % FB材
        rf_ = 11*sqrt(235./F);
        rw_ = 65*sqrt(235./F);
      case PRM.GIRDER_RANK_FC
        % FC材
        rf_ = 15.5*sqrt(235./F);
        rw_ = 71*sqrt(235./F);
      case PRM.GIRDER_RANK_FD
        rf_ = 100*ones(n,1);
        rw_ = 100*ones(n,1);
    end
    target = rank==irank;
    rf(target) = rf_(target);
    rw(target) = rw_(target);
  end

  % 幅厚比
  btf = B/2./tf;
  dtw = (H-2*tf)./tw;
  conwt = [btf./rf-1 dtw./rw-1];
  conwt = max(conwt,[],2);

  if all(~isSNH)
    return
  end

  % 相関関係を考慮した幅厚比制限値（告示1791号・1792号規定）
  % TODO: H形梁のみ対応
  kf = zeros(n,1); kw = zeros(n,1); kc = zeros(n,1);
  for irank=1:2
    kf_ = zeros(n,1); kw_ = zeros(n,1); kc_ = zeros(n,1);
    switch irank
      case PRM.GIRDER_RANK_FA
        % FA材
        kf_(F==235) = 22; kw_(F==235) = 144; kc_(F==235) = 100;
        kf_(F==325) = 26; kw_(F==325) = 118; kc_(F==325) = 100;
      case PRM.GIRDER_RANK_FB
        % FB材
        kf_(F==235) = 27; kw_(F==235) = 175; kc_(F==235) = 100;
        kf_(F==325) = 33; kw_(F==325) = 147; kc_(F==325) = 100;
    end
    target = rank==irank;
    kf(target) = kf_(target);
    kw(target) = kw_(target);
    kc(target) = kc_(target);
  end
  conwt2 = [btf.^2./kf.^2.*(F/98)+dtw.^2./kw.^2.*(F/98)-1 ...
    dtw-kc./sqrt(F/98)];
  conwt2 = max(conwt2,[],2);

  % SN材は常に相関関係を考慮した幅厚比制限値を採用
  % conwt2(~isSNH) = conwt(~isSNH);
  % conwt = min([conwt conwt2],[],2);
  conwt(isSNH) = conwt2(isSNH);
end
