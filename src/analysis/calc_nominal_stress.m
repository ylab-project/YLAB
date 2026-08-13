function [stn, stcn] = calc_nominal_stress(dfn, Mc, A, Asc, ...
  Asy, Asz, Aw, Zy, Zz, Zyij, Zyc, secdim, stype, F, ...
  mtype, idnm2m, cxl, cyl)
%calc_nominal_stress - 応力から応力度を計算する
%
%   [stn, stcn] = calc_nominal_stress(dfn, Mc, A, Asc, Asy, Asz,
%     Aw, Zy, Zz, Zyij, Zyc, secdim, stype, F, mtype, idnm2m,
%     cxl, cyl) は、名目部材応力から許容応力度検定用の応力度を
%     計算する。幅厚比制限超過時の有効断面性能は内部で作成する。
%     梁については、設計用せん断力を断面内の最鉛直方向へ射影し、
%     支配軸の有効せん断面積で除した鉛直方向せん断応力度を
%     PRM.STN_TAUV_I・PRM.STN_TAUV_J列へ保存する（計算編6.4.2）。
%
%   入力引数:
%     dfn    - 名目部材の設計応力 [nmn×12×nlc]
%     Mc     - 名目梁中央の曲げモーメント [nmn×nlc]
%     A      - 断面積 [nme×1]
%     Asc    - 軸応力度用断面積（スカラップ考慮） [nme×1]
%     Asy    - 強軸曲げのせん断有効断面積（ウェブ） [nme×1]
%     Asz    - 弱軸曲げのせん断有効断面積（フランジ） [nme×1]
%     Aw     - スカラップ控除付きウェブ断面積 [nme×1]
%     Zy     - 強軸断面係数 [nme×1]
%     Zz     - 弱軸断面係数 [nme×1]
%     Zyij   - 材端部の強軸断面係数 [nme×1]
%     Zyc    - 中央部の強軸断面係数 [nme×1]
%     secdim - 断面寸法 [nme×ndim]
%     stype  - 断面種別 [nme×1]
%     F      - 基準強度 [nme×1]
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

% 応力度計算用の有効断面性能
[~, Asc, Asy, Asz, Aw, Zy, Zz] = calc_effective_stress_secprop(...
  A, Asc, Asy, Asz, Aw, Zy, Zz, secdim, stype, F);

% 前処理（Asfはフランジのせん断有効断面積。Aw差し替え前に確保）
Asf = Asz;
Asz(mtype==PRM.GIRDER) = Aw(mtype==PRM.GIRDER);
Zz(mtype==PRM.BRACE) = 1.d-6;

% 名目部材端部の実部材（i端=始端セグメント、j端=終端セグメント）
idm_i = idnm2m(:,1);
idm_j = zeros(nmn,1);
for inm = 1:nmn
  idm_j(inm) = idnm2m(inm,nnz(idnm2m(inm,:)));
end

% 移し替え（Mc は既に nnm 空間。断面性能は始端セグメントで代表）
Asc = Asc(idm_i);
Asy = Asy(idm_i);
Asz = Asz(idm_i);
Asf = Asf(idm_i);
Zy = Zy(idm_i);
Zz = Zz(idm_i);
Zyij = Zyij(idm_i);
Zyc = Zyc(idm_i);
mtype = mtype(idm_i);

% 梁の鉛直方向せん断の射影方向と分母（1列=i端、2列=j端）
%   設計用せん断力を断面内で最も鉛直な単位方向へ射影する。単位化に
%   より、断面0度の勾配梁も勾配によらず鉛直成分|Qz|を保つ。分母は
%   支配軸（全体鉛直成分が大きい側の局所軸）の有効せん断面積とし、
%   局所z軸支配はAw（スカラップ控除付きウェブ）、局所y軸支配は
%   フランジ×2/3（SS7のAwyと同一）を用いる。
% 梁がない場合も列ベクトルとし、以降の2列配列の形状を保つ
ig = reshape(find(mtype==PRM.GIRDER), [], 1);
czl = cross(cxl, cyl, 2);
cylz = [cyl(idm_i(ig),3) cyl(idm_j(ig),3)];
czlz = [czl(idm_i(ig),3) czl(idm_j(ig),3)];
is_z = abs(czlz) >= abs(cylz);
Asv = repmat(Asf(ig)*2/3, 1, 2);
Asz_g = repmat(Asz(ig), 1, 2);   % 梁のAszはAw差し替え済み
Asv(is_z) = Asz_g(is_z);
den_v = sqrt(cylz.^2 + czlz.^2).*Asv;

% 応力度の計算
stn = zeros(nmn,PRM.STN_NCOL,nlc);
stcn = zeros(nmn,nlc);
for ilc = 1:nlc
  stn(:,1,ilc) = dfn(:,1,ilc)./Asc;   % σc i端（スカラップ考慮）
  stn(:,2,ilc) = dfn(:,2,ilc)./Asy;
  stn(:,3,ilc) = dfn(:,3,ilc)./Asz;
  stn(:,6,ilc) = dfn(:,6,ilc)./Zz;
  stn(:,7,ilc) = dfn(:,7,ilc)./Asc;   % σc j端（スカラップ考慮）
  stn(:,8,ilc) = dfn(:,8,ilc)./Asy;
  stn(:,9,ilc) = dfn(:,9,ilc)./Asz;
  stn(:,12,ilc) = dfn(:,12,ilc)./Zz;
  % 梁の鉛直方向せん断応力度（射影の絶対値／支配軸の有効面積）
  Qv = abs(dfn(ig,[2 8],ilc).*cylz + dfn(ig,[3 9],ilc).*czlz);
  stn(ig,[PRM.STN_TAUV_I PRM.STN_TAUV_J],ilc) = Qv./den_v;
  for inm = 1:nmn
    switch mtype(inm)
      case PRM.GIRDER
        stn(inm,5,ilc) = dfn(inm,5,ilc)/Zyij(inm);
        stn(inm,11,ilc) = dfn(inm,11,ilc)/Zyij(inm);
        stcn(inm,ilc) = Mc(inm,ilc)/Zyc(inm);
      case PRM.COLUMN
        stn(inm,5,ilc) = dfn(inm,5,ilc)/Zy(inm);
        stn(inm,11,ilc) = dfn(inm,11,ilc)/Zy(inm);
    end
  end
end

return
end
