function [Igm, gphiI] = calc_composite_girder_Iy(...
  member_girder, msdim, msprop, idmg2m, options)
% 床による合成効果を考慮した梁の断面二次モーメント計算

% 計算の準備
nmeg = length(idmg2m);
gphiI = ones(nmeg,1);
mgsdim = msdim(idmg2m,1:4);
mgstype = member_girder.section_type;

% スラブ協力幅から計算
% Agm = msprop.A(mtype==PRM.GIRDER);
% Igm = msprop.Iy(mtype==PRM.GIRDER);
Agm = msprop.A(idmg2m);
Igm = msprop.Iy(idmg2m);
phiI1 = calc_composite_slab(member_girder, mgsdim, Agm, Igm);

% 場合分け
for ims=1:2
  switch ims
    case 1
      % S梁
      composite_slab_effect = options.consider_composite_slab_effect_s;
      composite_slab_coefficient = options.composite_slab_coefficient_s;
      isgtarget = (mgstype==PRM.WFS);
      % ismtarget = (mstype==PRM.WFS);
    case 2
      % RC梁
      composite_slab_effect = options.consider_composite_slab_effect_rc;
      composite_slab_coefficient = options.composite_slab_coefficient_rc;
      isgtarget = (mgstype==PRM.RCRS);
      % ismtarget = (mstype==PRM.RCRS);
  end
  switch composite_slab_effect
    case PRM.COMPOSITE_SLAB_WIDTH
      gphiI(isgtarget) = phiI1(isgtarget);
    case PRM.COMPOSITE_SLAB_DIRECT
      comp_effect = member_girder.comp_effect;
      phiI1(isgtarget&comp_effect==0) = 1;
      phiI1(isgtarget&comp_effect==1) = composite_slab_coefficient(1);
      phiI1(isgtarget&comp_effect==2) = composite_slab_coefficient(2);
      gphiI(isgtarget) = phiI1(isgtarget);
  end
end

% 指定値の上書き
phiI_ = member_girder.phiI;
% gphiI(~isnan(phiI_)) = gphiI(~isnan(phiI_)).*phiI_(~isnan(phiI_));
gphiI(~isnan(phiI_)) = phiI_(~isnan(phiI_));

% 断面にモーメントの計算
Igm = Igm.*gphiI;
end

