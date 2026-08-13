function [gri, grj, grc, cri, crj, gsi, gsj, csi, csj, bnij] = ...
  calc_nominal_stress_constraints(ration, nominal, girder_axial_mask)
%calc_nominal_stress_constraints - 位置・ケース別の制約値を算定する
%
%   [gri, grj, grc, cri, crj, gsi, gsj, csi, csj, bnij] =
%     calc_nominal_stress_constraints(ration, nominal,
%     girder_axial_mask) は、成分別の応力度比から部材種別・位置別
%     の制約値（検定比から1を引いた値）を算定する。梁は水平面内
%     （弱軸）成分を算入せず、曲げは強軸、せん断は鉛直方向の
%     射影値を用いる（計算編6.4）。許容応力度検定の対象外部材には
%     -1.0を与える。
%
%   入力引数:
%     ration            - 位置・成分別の応力度比
%                         [nnm×PRM.RATION_NCOL×nlc]
%     nominal           - 名目部材データ構造体
%     girder_axial_mask - S梁の軸力考慮マスク (struct)
%
%   出力引数:
%     gri, grj, grc - 梁の曲げ制約値（i端・j端・中央） [nng×nlc]
%     gsi, gsj      - 梁のせん断制約値（i端・j端） [nng×nlc]
%     cri, crj      - 柱の曲げ制約値（i端・j端） [nnc×nlc]
%     csi, csj      - 柱のせん断制約値（i端・j端） [nnc×nlc]
%     bnij          - ブレースの軸力制約値 [nb×nlc]

% 共通定数
nnm = size(nominal.property.ntype,1);
nng = size(nominal.girder.idmeg,1);
nnc = size(nominal.column.idmec,1);
nmb = nnz(nominal.property.mtype==PRM.BRACE);
if nmb > 0
  idmeb = nominal.brace.idmeb;
  nb = max(idmeb(:));
else
  idmeb = zeros(0, 2);
  nb = 0;
end
nlc = size(ration,3);

% 計算の準備
nmtype = nominal.property.mtype;
gri = zeros(nng,nlc); grj = zeros(nng,nlc);
grc = zeros(nng,nlc);
cri = zeros(nnc,nlc); crj = zeros(nnc,nlc);
gsi = zeros(nng,nlc); gsj = zeros(nng,nlc);
csi = zeros(nnc,nlc); csj = zeros(nnc,nlc);
bnij = zeros(nb,nlc);

% 以降は絶対値で比較するため、ここで一括して符号を落とす
ration = abs(ration);
innn = 1:nnm;
iggg = innn(nmtype==PRM.GIRDER);
iccc = innn(nmtype==PRM.COLUMN);
ibbb = innn(nmtype==PRM.BRACE);

for ilc = 1:nlc
  for ing = 1:nng
    % --- 梁 ---
    inm = iggg(ing);

    % 軸応力度の検定
    if girder_axial_mask.i(inm, ilc)
      gci = ration(inm,1,ilc);
    else
      gci = 0;
    end
    if girder_axial_mask.j(inm, ilc)
      gcj = ration(inm,7,ilc);
    else
      gcj = 0;
    end

    % i端曲げ応力度の検定（強軸）
    gri(ing,ilc) = gci+ration(inm,5,ilc)-1;

    % j端曲げ応力度の検定（強軸）
    grj(ing,ilc) = gcj+ration(inm,11,ilc)-1;

    % 中央曲げ応力度の検定（N/fc + M/fb）
    if girder_axial_mask.c(inm, ilc)
      gcc = ration(inm,14,ilc);
    else
      gcc = 0;
    end
    grc(ing,ilc) = gcc + ration(inm,13,ilc) - 1;

    % i端・j端せん断応力度の検定（鉛直方向の射影値）
    gsi(ing,ilc) = ration(inm,PRM.RATION_TAUV_I,ilc)-1;
    gsj(ing,ilc) = ration(inm,PRM.RATION_TAUV_J,ilc)-1;
  end

  % --- 柱 ---
  for inc = 1:nnc
    inm = iccc(inc);

    % 軸応力度の検定
    cc = ration(inm,1,ilc);

    % i端曲げ応力度の検定
    cbi1 = ration(inm,5,ilc);
    cbi2 = ration(inm,6,ilc);
    cri(inc,ilc) = cc+cbi1+cbi2-1;

    % j端曲げ応力度の検定
    cbj1 = ration(inm,11,ilc);
    cbj2 = ration(inm,12,ilc);
    crj(inc,ilc) = cc+cbj1+cbj2-1;

    % i端せん断応力度の検定
    csi1 = ration(inm,2,ilc);
    csi2 = ration(inm,3,ilc);
    csi(inc,ilc) = max([csi1, csi2])-1;

    % j端せん断応力度の検定
    csj1 = ration(inm,8,ilc);
    csj2 = ration(inm,9,ilc);
    csj(inc,ilc) = max([csj1, csj2])-1;
  end

  % --- ブレース ---
  for imb = 1:nmb
    inm = ibbb(imb);
    idme_ = idmeb(imb, :);
    nz_ = find(idme_ > 0);
    if isscalar(nz_)
      bnij(idme_(nz_),ilc) = max(ration(inm,[1 7],ilc))-1;
    else
      bnij(idme_(1),ilc) = ration(inm,1,ilc)-1;
      bnij(idme_(2),ilc) = ration(inm,7,ilc)-1;
    end
  end

end

if isempty(gri)
  gri = -1.0; grj = -1.0; grc = -1.0;
  gsi = -1.0; gsj = -1.0;
else
  is_target = nominal.girder.is_allowable_stress;
  gri(~is_target,:) = -1.0;
  grj(~is_target,:) = -1.0;
  grc(~is_target,:) = -1.0;
  gsi(~is_target,:) = -1.0;
  gsj(~is_target,:) = -1.0;
end
if isempty(cri)
  cri = -1.0; crj = -1.0;
  csi = -1.0; csj = -1.0;
else
  % 柱の除外処理を追加（梁と同様）
  is_target = nominal.column.is_allowable_stress;
  cri(~is_target,:) = -1.0;
  crj(~is_target,:) = -1.0;
  csi(~is_target,:) = -1.0;
  csj(~is_target,:) = -1.0;
end
if isempty(bnij)
  bnij = -1.0;
end

return
end
