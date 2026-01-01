function section_property = calc_secprop(secdim, stype, scallop, secmgr)
%CALC_SECPROP この関数の概要をここに記述
%   詳細説明をここに記述

if nargin<3 || isempty(scallop)
  scallop = 0;
end

% 計算の準備
n = size(secdim,1);
section_property = zeros(n,15);
if isscalar(stype)
  stype = stype*ones(1,n);
end

% H形鋼
section_property(stype==PRM.WFS,1:14) = ...
  calc_prop_wfs(secdim(stype==PRM.WFS,:), scallop);

% 角形鋼管
section_property(stype==PRM.HSS,1:12) = ...
  calc_prop_hss(secdim(stype==PRM.HSS,:));

% RC矩形断面
section_property(stype==PRM.RCRS,1:12) = ...
  calc_prop_rcrs(secdim(stype==PRM.RCRS,:));

% 座屈拘束ブレース
if any(stype==PRM.BRB)
  table = secmgr.getListRecord(secdim(stype==PRM.BRB,end-1:end));
  section_property(stype==PRM.BRB,1) = table.A*100;
  section_property(stype==PRM.BRB,12) = table.A*100;
  section_property(stype==PRM.BRB,15) = table.Lkmax;
end

% 円形鋼管（HSR）
if any(stype==PRM.HSR)
  section_property(stype==PRM.HSR,1:12) = ...
    calc_prop_hsr(secdim(stype==PRM.HSR,:));
end

% 水平ブレース
if any(stype==PRM.HBR)
  sdim = secdim(stype==PRM.HBR,1:3);
  section_property(stype==PRM.HBR,1) = sdim(:,1); % A
  section_property(stype==PRM.HBR,12) = sdim(:,1); % A;
end

section_property = array2table(section_property, ...
  'VariableNames', {...
  'A', 'Asy', 'Asz', 'Iy', 'Iz', ...
  'Zy', 'Zz', 'Zyf', 'Zpy', 'Zpz', ...
  'JJ', 'Aw', 'Af', 'Zys', 'Lkmax'});
end

