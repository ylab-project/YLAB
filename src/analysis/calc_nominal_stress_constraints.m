function [gri, grj, grc, cri, crj, gsi, gsj, csi, csj, bnij] = ...
  calc_nominal_stress_constraints(ration, nominal)

% 共通定数
% nme = length(mtype);
% nmc = nnz(mtype==PRM.COLUMN);
% nmg = nnz(mtype==PRM.GIRDER);
% nmb = nnz(mtype==PRM.BRACE);
nnm = size(nominal.property.ntype,1);
nng = size(nominal.girder.idmeg,1);
nnc = size(nominal.column.idmec,1);
nmb = nnz(nominal.property.mtype==PRM.BRACE);
nlc = size(ration,3);

% 計算の準備
nmtype = nominal.property.mtype;
gri = zeros(nng,nlc); grj = zeros(nng,nlc);
grc = zeros(nng,nlc);
cri = zeros(nnc,nlc); crj = zeros(nnc,nlc);
gsi = zeros(nng,nlc); gsj = zeros(nng,nlc);
csi = zeros(nnc,nlc); csj = zeros(nnc,nlc);
bnij = zeros(nmb,nlc);

ration = abs(ration);
innn = 1:nnm;
iggg = innn(nmtype==PRM.GIRDER);
iccc = innn(nmtype==PRM.COLUMN);
ibbb = innn(nmtype==PRM.BRACE);
% idglc = 1:nng*nlc; idglc = reshape(idglc,nng,[]);
% idclc = 1:nnc*nlc; idclc = reshape(idclc,nnc,[]);
% idblc = 1:nmb*nlc; idclb = reshape(idblc,nmb,[]);

for ilc = 1:nlc
  for ing = 1:nng
    % --- 梁 ---
    inm = iggg(ing);

    % 軸応力度の検定
    gci = abs(ration(inm,1,ilc));
    gcj = abs(ration(inm,7,ilc));

    % i端曲げ応力度の検定
    gi1 = ration(inm,5,ilc);
    % gi2 = ration(inm,6,ilc);
    % gri(ing,ilc) = max([gci+gi1, gci+gi2])-1;
    % 弱軸曲げは見ない？
    gri(ing,ilc) = gci+gi1-1;

    % j端曲げ応力度の検定
    gj1 = ration(inm,11,ilc);
    % gj2 = ration(inm,12,ilc);
    % grj(ing,ilc) = max([gcj+gj1, gcj+gj2])-1;
    % 弱軸曲げは見ない？
    grj(ing,ilc) = gcj+gj1-1;

    % 中央曲げ応力度の検定
    grc(ing,ilc) = ration(inm,13,ilc)-1;

    % i端せん断応力度の検定
    gsi1 = ration(inm,2,ilc);
    gsi2 = ration(inm,3,ilc);
    gsi(ing,ilc) = max([gsi1, gsi2])-1;

    % j端せん断応力度の検定
    gsj1 = ration(inm,8,ilc);
    gsj2 = ration(inm,9,ilc);
    gsj(ing,ilc) = max([gsj1, gsj2])-1;
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

    % 軸応力度の検定
    nnn = abs(ration(inm,[1 7],ilc));
    bnij(imb,ilc) = max(nnn)-1;
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

end
