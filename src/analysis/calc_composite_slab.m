function phiI = calc_composite_slab(member_girder, sdim, A0, I0)
%CALC_COMPOSITE_SLAB この関数の概要をここに記述
%   詳細説明をここに記述

% 定数
nmg = size(sdim,1);
Es = 205000;

% 計算の準備
phiI = ones(nmg,1);
ba0 = member_girder.slab_width;
Hc0 = member_girder.slab_thickness;
Ec0 = member_girder.slab_E;
Hd0 = member_girder.deck_height;
stype = member_girder.section_type;
ispin = all(member_girder.joint==PRM.PIN,2);
ispin = ispin(stype==PRM.WFS);

% 鉄骨梁：増大率の計算
Hs = sdim(stype==PRM.WFS,1);
Bs = sdim(stype==PRM.WFS,2);
As = A0(stype==PRM.WFS);
Is = I0(stype==PRM.WFS);
Hc = Hc0(stype==PRM.WFS,:);
Ec = Ec0(stype==PRM.WFS);
Hd = Hd0(stype==PRM.WFS,:);
ba = ba0(stype==PRM.WFS,:);
issymmetric = (Hc(:,1)==Hc(:,2)&Hd(:,1)==Hd(:,2));
% issymmetric = true;
if issymmetric
  % 対称な場合
  ba = sum(ba,2);
  Ba = Bs+ba;
  Hc = Hc(:,1);
  Hd = Hd(:,1);
  g = (Ec.*Ba.*Hc.*(Hc/2)+Es.*As.*(Hc+Hd+Hs/2))./(Ec.*Ba.*Hc+Es.*As);
  Icom = (Ec/Es).*Ba.*(Hc.^3/12+Hc.*(g-Hc/2).^2)+Is+As.*(g-Hc-Hd-Hs/2).^2;
else
  % 非対称な場合
  nwfs = sum(stype==PRM.WFS);
  i1 = zeros(nwfs,1);
  i2 = zeros(nwfs,1);
  for i=1:nwfs
    if Hc(i,1)<Hc(i,2) || ba(i,1)==0
      i1(i) = 2;
      i2(i) = 1;
    else
      i1(i) = 1;
      i2(i) = 2;
    end
  end
  ba1 = zeros(nwfs,1);
  ba2 = zeros(nwfs,1);
  Hc1 = zeros(nwfs,1);
  Hc2 = zeros(nwfs,1);
  Hd1 = zeros(nwfs,1);
  Hd2 = zeros(nwfs,1);
  for i=1:nwfs
    ba1(i) = ba(i,i1(i));
    ba2(i) = ba(i,i2(i));
    Hc1(i) = Hc(i,i1(i));
    Hc2(i) = Hc(i,i2(i));
    Hd1(i) = Hd(i,i1(i));
    Hd2(i) = Hd(i,i2(i));
  end
  Ba = Bs+ba1;
  % g = (Ec.*Ba.*Hc1.*(Hc1/2) ...
  %   +Ec.*ba2.*Hc2.*(Hc1-Hc2/2) ...
  %   +Es.*As.*(Hc1+Hd1+Hs/2)) ...
  %   ./(Ec.*Ba.*Hc1+Ec.*ba2.*Hc2+Es.*As);
  g = (Ec.*Ba.*Hc1.*(Hc1/2) ...
    +Ec.*ba2.*Hc2.*(Hc2/2) ...
    +Es.*As.*(Hc1+Hd1+Hs/2)) ...
    ./(Ec.*Ba.*Hc1+Ec.*ba2.*Hc2+Es.*As);
  Icom = (Ec/Es).*(Ba.*Hc1.^3/12 ...
    +Ba.*Hc1.*(g-Hc1/2).^2 ...
    +ba2.*Hc2.^3/12 ...
    +ba2.*Hc2.*(g-Hc2/2).^2) ...
    +Is+As.*(g-Hc1-Hd1-Hs/2).^2;
end

% 接合条件の場合分け
I = (Icom+Is)/2;
I(ispin) = Icom(ispin);
I0_ = I0(stype==PRM.WFS);
I(all(ba==0,2)) = I0_(all(ba==0,2));
phiI(stype==PRM.WFS) = I./I0_;

% RC梁：増大率の計算
% ba = sum(ba0(stype==PRM.RCRS,:),2);
% B = b+ba;
Hc = Hc0(stype==PRM.RCRS,:);
Hd = Hd0(stype==PRM.RCRS,:);
ba = ba0(stype==PRM.RCRS,:);

% 非対称の判定
nrcrs = sum(stype==PRM.RCRS);
i1 = zeros(nrcrs,1);
i2 = zeros(nrcrs,1);
for i=1:nrcrs
  if Hc(i,1)<Hc(i,2) || ba(i,1)==0
    i1(i) = 2;
    i2(i) = 1;
  else
    i1(i) = 1;
    i2(i) = 2;
  end
end
ba1 = zeros(nrcrs,1);
ba2 = zeros(nrcrs,1);
Hc1 = zeros(nrcrs,1);
Hc2 = zeros(nrcrs,1);
Hd1 = zeros(nrcrs,1);
Hd2 = zeros(nrcrs,1);
for i=1:nrcrs
  ba1(i) = ba(i,i1(i));
  ba2(i) = ba(i,i2(i));
  Hc1(i) = Hc(i,i1(i));
  Hc2(i) = Hc(i,i2(i));
  Hd1(i) = Hd(i,i1(i));
  Hd2(i) = Hd(i,i2(i));
end

% 寸法設定
b = sdim(stype==PRM.RCRS,3);
D = sdim(stype==PRM.RCRS,4);
Dn = sdim(stype==PRM.RCRS,2);
t1 = Hc1;
t2 = Hc2;

% 面積
A0 = b.*D;
A1 = ba1.*t1;
A2 = ba2.*t2;

% 重心
g = (A0.*Dn/2+A1.*t1/2+A2.*t2/2)./(A0+A1+A2);

% 断面二次モーメント
I = b.*D.^3/12+A0.*(g-Dn/2).^2 ...
  +ba1.*t1.^3/12+A1.*(g-t1/2).^2 ...
  +ba2.*t2.^3/12+A2.*(g-t2/2).^2;

I0_ = I0(stype==PRM.RCRS);
phiI(stype==PRM.RCRS) = I./I0_;
end

