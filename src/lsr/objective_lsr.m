function [fval, fdetail] = objective_lsr(...
  xvar, secmgr, baseline, node, section, member, story, floor, options)

% 定数
% nstory = length(story.idz);
% nmc = size(member.column,1);

% 共通配列
stype = secmgr.idsec2stype;
% mtype = member.property.type;
idm2stype = secmgr.idme2stype;
idm2s = secmgr.idme2sec;
% idm2st = member.property.idstory;
% idm2n = [member.property.idnode1 member.property.idnode2];
idmg2m = member.girder.idme;
idmc2m = member.column.idme;
idsc2s = section.column.idsec;
idscb2s = idsc2s(section.column_base.idsecc);

cbstiff = section.column_base.property;
column_base = section.column_base;
% column_base_list = com.column_base_list;
column_base_list = secmgr.column_base_list;

% idmc2st = member.column.idstory;
% idmg2sg = member.girder.idsecg;
% idmg2st = member.girder.idstory;
% idsg2s = 1:secmgr.nsec; idsg2s = idsg2s(secmgr.idsecg>0);

% 断面積の計算
secdim = secmgr.findNearestSection(xvar, options);
sprop = calc_secprop(secdim, stype, [], secmgr);
A = sprop.A;
Am = A(idm2s);

% RC断面を除外
Am(idm2stype==PRM.RCRS) = 0;

if nargin==4
  options.do_autoupdate_floor_height = false;
  options.consider_allowable_stress_at_face = false;
end


% 基礎柱寸法
Dcb = secdim(idscb2s,1);
cbs = calc_column_base_section(...
  Dcb, cbstiff, column_base, column_base_list);

[~, ~, ~, ~, ~, lm, lf, ~] = update_geometry(...
  secdim, baseline, node, story, floor, section, member, cbs, options);

% 梁接合部長さの除外
lme = lm;
lme(idmg2m) = lme(idmg2m)-sum(lf.girder,2);

% コスト係数
ids2slist = SectionManager.getSectionListMapping(secdim);
cfm = secmgr.getMemberCostFactor(ids2slist, options);

% コスト（鋼材重量）の計算
fval = sum(cfm.*Am.*lme)*1e-3*PRM.RHOS*1e-6;

if nargout == 2
  nsublist = secmgr.getNumSectionSubList;
  fdetail.weight = sum(Am.*lme)*1e-3*PRM.RHOS*1e-6;
  fdetail.weight_girder = sum(Am(idmg2m).*lme(idmg2m))*1e-3*PRM.RHOS*1e-6;
  fdetail.weight_column = sum(Am(idmc2m).*lme(idmc2m))*1e-3*PRM.RHOS*1e-6;
  fdetail.weigth_sublist = zeros(nsublist,1);
  fdetail.cost = fval;
  fdetail.cost_girder = sum(cfm(idmg2m).*Am(idmg2m).*lme(idmg2m))*1e-3*PRM.RHOS*1e-6;
  fdetail.cost_column = sum(cfm(idmc2m).*Am(idmc2m).*lme(idmc2m))*1e-3*PRM.RHOS*1e-6;
  fdetail.cost_sublist = zeros(nsublist,1);
  % リスト別集計
  idm2sslist = secmgr.getIdMemberToSubList(ids2slist);
  fdetail.weight_sublist = zeros(secmgr.nlist,1);
  fdetail.cost_sublist = zeros(secmgr.nlist,1);
  for id=1:nsublist
    istarget = (idm2sslist==id);
    fdetail.weight_sublist(id) = ...
      sum(Am(istarget).*lme(istarget))*1e-3*PRM.RHOS*1e-6;
    fdetail.cost_sublist(id) = ...
      sum(cfm(istarget).*Am(istarget).*lme(istarget))*1e-3*PRM.RHOS*1e-6;
  end
end
return 
end
