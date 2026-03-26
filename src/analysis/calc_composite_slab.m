function phiI = calc_composite_slab(member_girder, sdim, A0, I0)
%calc_composite_slab - 合成スラブによる断面二次モーメント増大率を計算

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
  g = (Ec.*Ba.*Hc1.*(Hc1/2)+Ec.*ba2.*Hc2.*(Hc2/2) ...
    +Es.*As.*(Hc1+Hd1+Hs/2))./(Ec.*Ba.*Hc1+Ec.*ba2.*Hc2+Es.*As);
  Icom = (Ec/Es).*(Ba.*Hc1.^3/12+Ba.*Hc1.*(g-Hc1/2).^2 ...
    +ba2.*Hc2.^3/12+ba2.*Hc2.*(g-Hc2/2).^2) ...
    +Is+As.*(g-Hc1-Hd1-Hs/2).^2;
end

% 接合条件の場合分け
I = (Icom+Is)/2;
I(ispin) = Icom(ispin);
I0_ = I0(stype==PRM.WFS);
I(all(ba==0,2)) = I0_(all(ba==0,2));
phiI(stype==PRM.WFS) = I./I0_;

% RC梁：増大率の計算
isrc = (stype==PRM.RCRS);

% 上面スラブ（左右）
ba_u = ba0(isrc,:);
t_u = Hc0(isrc,:);

% 下面スラブ（二重スラブ）
ba_l = member_girder.slab_width_lower(isrc,:);
t_l = member_girder.slab_thickness_lower(isrc,:);

% 寸法設定
b = sdim(isrc,3);   % b'（荷重剛性用）
D = sdim(isrc,4);   % D'（荷重剛性用）
Dn = sdim(isrc,2);  % D（原断面せい）

% 面積（原断面=打増し後の断面、図心はDn/2）
Ab = b.*D;
A_u1 = ba_u(:,1).*t_u(:,1);
A_u2 = ba_u(:,2).*t_u(:,2);
A_l1 = ba_l(:,1).*t_l(:,1);
A_l2 = ba_l(:,2).*t_l(:,2);

% 重心位置（梁底基準、スラブはDn基準で配置）
% 上面: Dn天端に密着 → 重心 = Dn - t/2
% 下面: 梁底に密着   → 重心 = t/2
d_u1 = Dn - t_u(:,1)/2;
d_u2 = Dn - t_u(:,2)/2;
d_l1 = t_l(:,1)/2;
d_l2 = t_l(:,2)/2;

% 合成断面の重心
A_total = Ab+A_u1+A_u2+A_l1+A_l2;
g = (Ab.*Dn/2+A_u1.*d_u1+A_u2.*d_u2+A_l1.*d_l1+A_l2.*d_l2) ./ A_total;

% 断面二次モーメント（I形断面）
I = b.*D.^3/12+Ab.*(g-Dn/2).^2+ba_u(:,1).*t_u(:,1).^3/12 ...
  +A_u1.*(g-d_u1).^2+ba_u(:,2).*t_u(:,2).^3/12 ...
  +A_u2.*(g-d_u2).^2+ba_l(:,1).*t_l(:,1).^3/12+A_l1.*(g-d_l1).^2 ...
  +ba_l(:,2).*t_l(:,2).^3/12+A_l2.*(g-d_l2).^2;

I0_ = I0(isrc);
phiI(isrc) = I./I0_;

return
end

