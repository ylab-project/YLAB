function section_property = calc_secprop(secdim, stype, scallop, secmgr)
%CALC_SECPROP この関数の概要をここに記述
%   詳細説明をここに記述

if nargin<3 || isempty(scallop)
  scallop = 0;
end

% 計算の準備
n = size(secdim,1);
section_property = zeros(n,17);
if isscalar(stype)
  stype = stype*ones(1,n);
end

% H形鋼（梁柱 WFS + ブレース BWFS）
iw = stype==PRM.WFS | stype==PRM.BWFS;
props_wfs = calc_prop_wfs(secdim(iw,:), scallop);
section_property(iw,1:14) = props_wfs(:,1:14);
section_property(iw,16) = props_wfs(:,15);  % Iyr
section_property(iw,17) = props_wfs(:,16);  % Asc

% 角形鋼管（梁柱 HSS + ブレース BHSS）
ih = stype==PRM.HSS | stype==PRM.BHSS;
section_property(ih,1:12) = ...
  calc_prop_hss(secdim(ih,:));

% RC矩形断面
section_property(stype==PRM.RCRS,1:12) = ...
  calc_prop_rcrs(secdim(stype==PRM.RCRS,:));

% 座屈拘束ブレース
if any(stype==PRM.BRB)
  table = secmgr.getListRecord(secdim(stype==PRM.BRB,:));
  section_property(stype==PRM.BRB,1) = table.A*100;
  section_property(stype==PRM.BRB,12) = table.A*100;
  section_property(stype==PRM.BRB,15) = table.Lkmax;
end

% 円形鋼管（梁柱 HSR + ブレース BHSR）
ir = stype==PRM.HSR | stype==PRM.BHSR;
if any(ir)
  section_property(ir,1:12) = ...
    calc_prop_hsr(secdim(ir,:));
end

% 水平ブレース
if any(stype==PRM.HBR)
  sdim = secdim(stype==PRM.HBR,1:3);
  section_property(stype==PRM.HBR,1) = sdim(:,1); % A
  section_property(stype==PRM.HBR,12) = sdim(:,1); % A;
end

% 引張ブレース
% dimension: [shape_code, A(mm2), Ae(mm2), Ta(kN)]
if any(stype==PRM.TB)
  sdim = secdim(stype==PRM.TB,:);
  section_property(stype==PRM.TB,1) = sdim(:,2);  % A
  section_property(stype==PRM.TB,12) = sdim(:,3); % Ae
end

% 非WFS断面のAsはAと同値（スカラップなし）
noAs = section_property(:,17)==0 & section_property(:,1)>0;
section_property(noAs,17) = section_property(noAs,1);

section_property = array2table(section_property, ...
  'VariableNames', {...
  'A', 'Asy', 'Asz', 'Iy', 'Iz', ...
  'Zy', 'Zz', 'Zyf', 'Zpy', 'Zpz', ...
  'JJ', 'Aw', 'Af', 'Zysc', 'Lkmax', ...
  'Iyr', 'Asc'});
end

