function [concgsr, cgsr] = calc_cgstrength_ratio(Zpy, vix, viy, ...
  idnode_cgsr, idm2n, idmc2m, mtype, Fm, cxl, isxdir_member, ...
  isydir_member)
%calc_cgstrength_ratio - 柱梁耐力比を計算
%
%   [concgsr, cgsr] = calc_cgstrength_ratio(Zpy, vix, viy, ...
%     idnode_cgsr, idm2n, idmc2m, mtype, Fm, cxl, isxdir_member,
%     isydir_member) は、各接合部における柱梁耐力比を計算する。
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
%     mtype      - 部材種別 [nmember×1]
%     Fm         - 材料のF値 [nmember×1]
%     cxl        - 部材の方向余弦（X軸方向）[nmember×3]
%     isxdir_member - X方向計算に寄与する部材 [nmember×1]
%     isydir_member - Y方向計算に寄与する部材 [nmember×1]
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
cgsr.idmc_upper = zeros(ncgsr,1);  % 上柱の部材番号（帳票の種別表示用）
cgsr.idmc_lower = zeros(ncgsr,1);  % 下柱の部材番号（帳票の種別表示用）

% cosθ補正係数の計算
cx = cxl(:,1);
cy = cxl(:,2);
cxy = sqrt(cx.^2 + cy.^2);
cos_x = abs(cx) ./ cxy;  % X方向への投影係数
cos_y = abs(cy) ./ cxy;  % Y方向への投影係数
cos_x(isnan(cos_x)) = 1;
cos_y(isnan(cos_y)) = 1;

isgirx = mtype==PRM.GIRDER & isxdir_member;
isgiry = mtype==PRM.GIRDER & isydir_member;

% 耐力比の計算
for icg = 1:ncgsr
  in = idnode_cgsr(icg);
  isconnected1 = (idm2n(:,1)==in);
  isconnected2 = (idm2n(:,2)==in);

  % 左右の梁（cosθ補正適用）
  % 左右判定は相手端の座標で行う（SS7互換）。方向余弦の符号により
  % 節点順が検討方向と逆向きの斜め梁でも左右を正しく振り分ける
  isxdir1 = isgirx&((isconnected2&cx>=0)|(isconnected1&cx<0));
  isxdir2 = isgirx&((isconnected1&cx>=0)|(isconnected2&cx<0));
  isydir1 = isgiry&((isconnected2&cy>=0)|(isconnected1&cy<0));
  isydir2 = isgiry&((isconnected1&cy>=0)|(isconnected2&cy<0));
  sgxl = sum(Zpy(isxdir1).*Fm(isxdir1).*cos_x(isxdir1)*1.1);
  sgxr = sum(Zpy(isxdir2).*Fm(isxdir2).*cos_x(isxdir2)*1.1);
  sgyl = sum(Zpy(isydir1).*Fm(isydir1).*cos_y(isydir1)*1.1);
  sgyr = sum(Zpy(isydir2).*Fm(isydir2).*cos_y(isydir2)*1.1);

  % 上下の柱
  % TODO 柱の耐力の方向成分を考える必要があるが保留
  isc1  = isconnected2&mtype==PRM.COLUMN;
  isc2  = isconnected1&mtype==PRM.COLUMN;
  imc_upper = find(isc2, 1);
  imc_lower = find(isc1, 1);
  if ~isempty(imc_upper)
    cgsr.idmc_upper(icg) = imc_upper;
  end
  if ~isempty(imc_lower)
    cgsr.idmc_lower(icg) = imc_lower;
  end
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
