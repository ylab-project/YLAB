function x = generateRandomXvar(secmgr, seed, lm, options)
% 初期解のランダム生成
if nargin==1
  rng('shuffle');
else
  rng(seed);
end

% 計算の準備
x = zeros(1,secmgr.nxvar);
ivvv = 1:secmgr.nxvar;
vtypeset = [PRM.WFS_H PRM.WFS_B PRM.WFS_TW PRM.WFS_TF ...
  PRM.HSS_D PRM.HSS_T];
idm2v = secmgr.idme2var(:,1);

for idlist = 1:secmgr.nlist
  % 計算の準備
  Hnominal = secmgr.getHnominal(idlist);
  idH2v = ivvv(secmgr.isVarofSlist(:,idlist)&...
    secmgr.idvar2vtype==PRM.WFS_H);
  nHv = length(idH2v);

  % 梁せい上下限値の設定
  Hnomset = cell(nHv,1);
  if options.do_limit_initial_girder_height
    % スパン1/20～1/10の範囲に制限
    for iHv=1:nHv
      idv = idH2v(iHv);
      lmg = lm(idm2v==idv);
      Hub = max(lmg/10);
      Hlb = max(lmg/20);
      Hnomset{iHv} = Hnominal(Hnominal>=Hlb&Hnominal<=Hub);
    end
  else
    % 制限なし
    for iHv=1:nHv
      Hnomset{iHv} = Hnominal;
    end
  end

  % ランダム値のセット
  for vtype = vtypeset
    idtarget = ivvv(secmgr.isVarofSlist(:,idlist)&...
      secmgr.idvar2vtype==vtype);
    if isempty(idtarget)
      % 対象外のスキップ
      continue
    end
    switch vtype
      case PRM.WFS_H
        val = zeros(1,nHv);
        for iv=1:nHv
          Hnom_ = Hnomset{iv};
          val(iv) = Hnom_(randi(length(Hnom_)));
        end
      case PRM.WFS_B
        Bnominal = secmgr.getBnominal(idlist);
        val = Bnominal(randi(length(Bnominal),1,length(idtarget)));
      case PRM.WFS_TW
        twst = secmgr.getTwst(idlist);
        val = twst(randi(length(twst),1,length(idtarget)));
      case PRM.WFS_TF
        tfst = secmgr.getTfst(idlist);
        val = tfst(randi(length(tfst),1,length(idtarget)));
      case PRM.HSS_D
        Dst = secmgr.getDst(idlist);
        val = Dst(randi(length(Dst),1,length(idtarget)));
      case PRM.HSS_T
        tst = secmgr.getTst(idlist);
        val = tst(randi(length(tst),1,length(idtarget)));
    end
    x(idtarget) = val;
  end
end
end
