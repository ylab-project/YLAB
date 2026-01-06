function [concgsr, cgsr] = calc_cgstrength_ratio(Zpy, vix, viy, ...
  idnode_cgsr, idm2n, idmc2m, medir, mtype, Fm, cxl)
%calc_cgstrength_ratio - 柱梁耐力比を計算
%
%   [concgsr, cgsr] = calc_cgstrength_ratio(Zpy, vix, viy, ...
%     idnode_cgsr, idm2n, idmc2m, medir, mtype, Fm, cxl) は、
%   各接合部における柱梁耐力比を計算する。
%
%   斜め梁の場合、梁の全塑性モーメントに cosθ 補正を適用する。
%   SS7仕様: M'pbi = Mpbi × cosθ
%
%   入力引数:
%     Zpy        - 塑性断面係数 [nmember×1]
%     vix, viy   - 柱の方向成分 [nmec×2]
%     idnode_cgsr- 柱梁耐力比算定対象節点 [ncgsr×1]
%     idm2n      - 部材の節点番号 [nmember×2]
%     idmc2m     - 柱部材インデックス [nmec×1]
%     medir      - 部材方向 [nmember×1]
%     mtype      - 部材種別 [nmember×1]
%     Fm         - 材料のF値 [nmember×1]
%     cxl        - 部材の方向余弦（X軸方向）[nmember×3]（オプション）
%
%   出力引数:
%     concgsr - 柱梁耐力比制約値 [ncgsr×4]
%     cgsr    - 柱梁耐力比詳細構造体

% 計算の準備
ncgsr = length(idnode_cgsr);
cgsr.ratio = zeros(ncgsr,4);
cgsr.sgx = zeros(ncgsr,2);
cgsr.sgy = zeros(ncgsr,2);
cgsr.scx = zeros(ncgsr,4);
cgsr.scy = zeros(ncgsr,4);

% cosθ補正係数の計算
nmember = size(idm2n,1);
if nargin >= 10 && ~isempty(cxl)
  % 水平面内の方向余弦からcosθを計算
  cx = cxl(:,1);
  cy = cxl(:,2);
  cxy = sqrt(cx.^2 + cy.^2);
  % X方向成分、Y方向成分
  cos_x = abs(cx) ./ cxy;  % X方向への投影係数
  cos_y = abs(cy) ./ cxy;  % Y方向への投影係数
  % NaN対策（鉛直梁の場合）
  cos_x(isnan(cos_x)) = 1;
  cos_y(isnan(cos_y)) = 1;
else
  % cxlが指定されていない場合は補正なし
  cos_x = ones(nmember,1);
  cos_y = ones(nmember,1);
end

% 耐力比の計算
for icg = 1:ncgsr
  in = idnode_cgsr(icg);
  isconnected1 = (idm2n(:,1)==in);
  isconnected2 = (idm2n(:,2)==in);

  % 左右の梁（cosθ補正適用）
  % 45度梁（PRM.XY）は両方向に含める
  isgx1 = isconnected2&mtype==PRM.GIRDER&(medir==PRM.X|medir==PRM.XY);
  isgy1 = isconnected2&mtype==PRM.GIRDER&(medir==PRM.Y|medir==PRM.XY);
  isgx2 = isconnected1&mtype==PRM.GIRDER&(medir==PRM.X|medir==PRM.XY);
  isgy2 = isconnected1&mtype==PRM.GIRDER&(medir==PRM.Y|medir==PRM.XY);
  sgxl = sum(Zpy(isgx1).*Fm(isgx1).*cos_x(isgx1)*1.1);
  sgxr = sum(Zpy(isgx2).*Fm(isgx2).*cos_x(isgx2)*1.1);
  sgyl = sum(Zpy(isgy1).*Fm(isgy1).*cos_y(isgy1)*1.1);
  sgyr = sum(Zpy(isgy2).*Fm(isgy2).*cos_y(isgy2)*1.1);

  % 上下の柱
  % TODO 柱の耐力の方向成分を考える必要があるが保留
  isc1  = isconnected2&mtype==PRM.COLUMN;
  isc2  = isconnected1&mtype==PRM.COLUMN;
  scx1p = sum(vix(isc1(idmc2m),1).*Zpy(isc1).*Fm(isc1)*1.1);
  scx1n = sum(vix(isc1(idmc2m),2).*Zpy(isc1).*Fm(isc1)*1.1);
  scx2p = sum(vix(isc2(idmc2m),1).*Zpy(isc2).*Fm(isc2)*1.1);
  scx2n = sum(vix(isc2(idmc2m),2).*Zpy(isc2).*Fm(isc2)*1.1);
  scy1p = sum(viy(isc1(idmc2m),1).*Zpy(isc1).*Fm(isc1)*1.1);
  scy1n = sum(viy(isc1(idmc2m),2).*Zpy(isc1).*Fm(isc1)*1.1);
  scy2p = sum(viy(isc2(idmc2m),1).*Zpy(isc2).*Fm(isc2)*1.1);
  scy2n = sum(viy(isc2(idmc2m),2).*Zpy(isc2).*Fm(isc2)*1.1);

  % 梁の合算
  sgx = sgxl+sgxr;
  sgy = sgyl+sgyr;

  %柱の合算
  scxp = scx1p+scx2p;
  scxn = scx1n+scx2n;
  scyp = scy1p+scy2p;
  scyn = scy1n+scy2n;

  % 結果の保存
  cgsr.ratio(icg,:) = [scxp/sgx scxn/sgx scyp/sgy scyn/sgy];
  cgsr.sgx(icg,:) = [sgxl sgxr];
  cgsr.sgy(icg,:) = [sgyl sgyr];
  cgsr.scx(icg,:) = [scx1p scx2p scx1n scx2n];
  cgsr.scy(icg,:) = [scy1p scy2p scy1n scy2n];
end
concgsr = 1.5./cgsr.ratio-1;
concgsr = reshape(concgsr,[],1);

return
end
