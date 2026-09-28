function [stn, stcn] = calc_nominal_stress(dfn, Mc, Asc, Aqy, Aqz, ...
  Zyij, Zzij, Zyc, mtype, idnm2m, cxl, cyl)
%calc_nominal_stress - 応力から応力度を計算する
%
%   [stn, stcn] = calc_nominal_stress(dfn, Mc, Asc, Aqy, Aqz,
%     Zyij, Zzij, Zyc, mtype, idnm2m, cxl, cyl)
%     は、名目部材応力から許容応力度検定用の応力度を計算する。
%     幅厚比の規定値を超える部分を控除済みの断面性能を受け取る。
%     せん断応力度は局所y・z方向のせん断力をそれぞれAqy・Aqzで
%     除す（計算編6.4.2・6.5.2）。梁については、設計用せん断力を
%     断面内の最鉛直方向へ射影し、支配軸の面積で除した鉛直方向
%     せん断応力度をPRM.STN_TAUV_I・PRM.STN_TAUV_J列へ保存する。
%
%   入力引数:
%     dfn    - 名目部材の設計応力 [nmn×12×nlc]
%     Mc     - 名目梁中央の曲げモーメント [nmn×nlc]
%     Asc    - 軸応力度用断面積（スカラップ考慮） [nme×1]
%     Aqy    - 局所y方向せん断力に対する断面積 [nme×1]
%     Aqz    - 局所z方向せん断力に対する断面積 [nme×1]
%     Zyij   - 材端部の局所y軸まわり断面係数 [nme×1]
%     Zzij   - 材端部の局所z軸まわり断面係数 [nme×1]
%     Zyc    - 中央部の局所y軸まわり断面係数 [nme×1]
%     mtype  - 部材種別 [nme×1]
%     idnm2m - 名目部材→実部材の対応 [nmn×ncol]
%     cxl    - 形状更新後の方向余弦（材軸） [nme×3]
%     cyl    - 形状更新後の方向余弦（局所y軸） [nme×3]
%
%   出力引数:
%     stn  - 名目部材の応力度 [nmn×PRM.STN_NCOL×nlc]
%     stcn - 名目梁中央の曲げ応力度 [nmn×nlc]

% 計算の準備
[nmn, ~, nlc] = size(dfn);

% 前処理
Zzij(mtype==PRM.BRACE) = 1.d-6;

% 名目部材端部の実部材（i端=始端セグメント、j端=終端セグメント）
idm_i = idnm2m(:,1);
idm_j = zeros(nmn,1);
for inm = 1:nmn
  idm_j(inm) = idnm2m(inm,nnz(idnm2m(inm,:)));
end

% 移し替え（Mc は既に nnm 空間。断面性能は始端セグメントで代表）
Asc = Asc(idm_i);
Aqy = Aqy(idm_i);
Aqz = Aqz(idm_i);
Zyij = Zyij(idm_i);
Zzij = Zzij(idm_i);
Zyc = Zyc(idm_i);
mtype = mtype(idm_i);

% 梁の鉛直方向せん断の射影方向と分母（1列=i端、2列=j端）
%   設計用せん断力を断面内で最も鉛直な単位方向へ射影する。単位化に
%   より、断面0度の勾配梁も勾配によらず鉛直成分|Qz|を保つ。分母は
%   支配軸（全体鉛直成分が大きい側の局所軸）のせん断力に対する面積
%   とし、局所z軸支配はAqz（スカラップ控除付きウェブ）、局所y軸
%   支配はAqy（フランジ×2/3、SS7のAwyと同一）を用いる。
% 梁がない場合も列ベクトルとし、以降の2列配列の形状を保つ
ig = reshape(find(mtype==PRM.GIRDER), [], 1);
czl = cross(cxl, cyl, 2);
cylz = [cyl(idm_i(ig),3) cyl(idm_j(ig),3)];
czlz = [czl(idm_i(ig),3) czl(idm_j(ig),3)];
is_z = abs(czlz) >= abs(cylz);
Asv = Aqy(ig).*~is_z + Aqz(ig).*is_z;
den_v = sqrt(cylz.^2 + czlz.^2).*Asv;

% 応力度の計算。材端部の曲げ応力度は梁と柱について求める
isgc = mtype==PRM.GIRDER | mtype==PRM.COLUMN;
stn = zeros(nmn,PRM.STN_NCOL,nlc);
stcn = zeros(nmn,nlc);
for ilc = 1:nlc
  stn(:,1,ilc) = dfn(:,1,ilc)./Asc;   % σc i端（スカラップ考慮）
  stn(:,2,ilc) = dfn(:,2,ilc)./Aqy;
  stn(:,3,ilc) = dfn(:,3,ilc)./Aqz;
  stn(:,6,ilc) = dfn(:,6,ilc)./Zzij;
  stn(:,7,ilc) = dfn(:,7,ilc)./Asc;   % σc j端（スカラップ考慮）
  stn(:,8,ilc) = dfn(:,8,ilc)./Aqy;
  stn(:,9,ilc) = dfn(:,9,ilc)./Aqz;
  stn(:,12,ilc) = dfn(:,12,ilc)./Zzij;
  % 梁の鉛直方向せん断応力度（射影の絶対値／支配軸の面積）
  Qv = abs(dfn(ig,[2 8],ilc).*cylz + dfn(ig,[3 9],ilc).*czlz);
  stn(ig,[PRM.STN_TAUV_I PRM.STN_TAUV_J],ilc) = Qv./den_v;
  stn(isgc,5,ilc) = dfn(isgc,5,ilc)./Zyij(isgc);
  stn(isgc,11,ilc) = dfn(isgc,11,ilc)./Zyij(isgc);
  stcn(ig,ilc) = Mc(ig,ilc)./Zyc(ig);
end

return
end
