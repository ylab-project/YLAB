function section_property = calc_secprop(secdim, stype, scallop, secmgr)
%calc_secprop - 断面タイプに応じた断面諸量の計算
%
%   section_property = calc_secprop(secdim, stype, scallop,
%   secmgr) は、断面寸法と断面タイプから断面諸量を計算し
%   tableとして返す。WFS断面はスカラップを考慮する。
%
%   入力引数:
%     secdim  - 断面寸法 [n×m double]
%     stype   - 断面タイプ (スカラーまたは [1×n])
%     scallop - スカラップサイズ (省略時: 0)
%     secmgr  - 断面マネージャ (BRB用)
%
%   出力引数:
%     section_property - 断面諸量 [n×17 table]
%       A,Asy,Asz,Iy,Iz,Zy,Zz,Zyf,Zpy,Zpz,JJ,Aw,Af,
%       Zysc,Lkmax,Iyr,Asc

if nargin<3 || isempty(scallop)
  scallop = 0;
end

% 計算の準備
n = size(secdim,1);
section_property = zeros(n,17);
if isscalar(stype)
  stype = stype*ones(1,n);
end

% H形鋼（大梁 WFS）: スカラップ考慮
iw = stype==PRM.WFS;
if any(iw)
  props = calc_prop_wfs(secdim(iw,:), scallop);
  section_property(iw,1:14) = props(:,1:14);
  section_property(iw,16) = props(:,15);  % Iyr
  section_property(iw,17) = props(:,16);  % Asc
end

% H形鋼ブレース（BWFS）: ガセット接合のためスカラップなし
% Iyr/Ascは大梁専用のため代入しない（noAsでAsc=Aに設定）
ibw = stype==PRM.BWFS;
if any(ibw)
  props = calc_prop_wfs(secdim(ibw,:), 0);
  section_property(ibw,1:14) = props(:,1:14);
end

% 角形鋼管（HSS + BHSS）
ih = stype==PRM.HSS | stype==PRM.BHSS;
if any(ih)
  section_property(ih,1:12) = calc_prop_hss(secdim(ih,:));
end

% RC矩形断面
irc = stype==PRM.RCRS;
if any(irc)
  section_property(irc,1:12) = calc_prop_rcrs(secdim(irc,:));
end

% 座屈拘束ブレース
ibrb = stype==PRM.BRB;
if any(ibrb)
  tbl = secmgr.getListRecord(secdim(ibrb,:));
  section_property(ibrb,1) = tbl.A*100;
  section_property(ibrb,12) = tbl.A*100;
  section_property(ibrb,15) = tbl.Lkmax;
end

% 円形鋼管（HSR + BHSR）
ir = stype==PRM.HSR | stype==PRM.BHSR;
if any(ir)
  section_property(ir,1:12) = calc_prop_hsr(secdim(ir,:));
end

% 水平ブレース
ihbr = stype==PRM.HBR;
if any(ihbr)
  section_property(ihbr,1) = secdim(ihbr,1);
  section_property(ihbr,12) = secdim(ihbr,1);
end

% 引張ブレース
itb = stype==PRM.TB;
if any(itb)
  section_property(itb,1) = secdim(itb,2);
  section_property(itb,12) = secdim(itb,3);
end

% 非WFS断面のAscはAと同値（スカラップなし）
noAs = section_property(:,17)==0 & section_property(:,1)>0;
section_property(noAs,17) = section_property(noAs,1);

vnames = {'A', 'Asy', 'Asz', 'Iy', 'Iz', 'Zy', 'Zz', ...
  'Zyf', 'Zpy', 'Zpz', 'JJ', 'Aw', 'Af', 'Zysc', 'Lkmax', ...
  'Iyr', 'Asc'};
section_property = array2table(section_property, 'VariableNames', vnames);

return
end

