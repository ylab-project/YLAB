function section_property = calc_secprop(secdim, stype, scallop, secmgr)
%calc_secprop - 断面タイプに応じた断面諸量の計算
%
%   section_property = calc_secprop(secdim, stype, scallop,
%   secmgr) は、断面寸法と断面タイプから断面諸量を計算し、
%   scalar struct-of-arraysとして返す。H形鋼の梁と柱はスカラップを
%   考慮する。断面諸量は部材局所軸（y・z）で表し、Y方向強軸の
%   H形鋼柱（CWFSI）は局所y・z軸の対を入れ替えて返す。
%
%   入力引数:
%     secdim  - 断面寸法 [n×m double]
%     stype   - 断面タイプ (スカラーまたは [1×n])
%     scallop - スカラップサイズ (省略時: 0)
%     secmgr  - 断面マネージャ (BRB用)
%
%   出力引数:
%     section_property - 断面諸量のscalar struct-of-arrays
%       A,Asy,Asz,Iy,Iz,Zy,Zz,Zyf,Zpy,Zpz,JJ,Aw,Af,Zysc,Lkmax,
%       Iyr,Asc,Aqy,Aqz,Zzsc,Zzf（各フィールド [n×1 double]）
%       Aqy,Aqz は応力度計算でせん断力Qy,Qzを除す面積、
%       Zzsc,Zzf は局所z軸まわりの端部断面係数（Zysc,Zyfと対）

if nargin<3 || isempty(scallop)
  scallop = 0;
end

% 計算の準備
n = size(secdim,1);
secprop_values = zeros(n,21);
if isscalar(stype)
  stype = stype*ones(1,n);
end

% H形鋼（大梁WFS、柱CWFS・CWFSI）: 柱頭・柱脚も梁端と同じ
% スカラップ欠損を考慮する（計算編6.5.1）
iw = stype==PRM.WFS | stype==PRM.CWFS | stype==PRM.CWFSI;
if any(iw)
  props = calc_prop_wfs(secdim(iw,:), scallop);
  secprop_values(iw,1:14) = props(:,1:14);
  secprop_values(iw,16) = props(:,15);  % Iyr
  secprop_values(iw,17) = props(:,16);  % Asc
  secprop_values(iw,20:21) = props(:,17:18);  % Zzsc, Zzf
end

% H形鋼ブレース（BWFS）: ガセット接合のためスカラップなし
% Iyr/Ascは大梁専用のため代入しない（noAsでAsc=Aに設定）
ibw = stype==PRM.BWFS;
if any(ibw)
  props = calc_prop_wfs(secdim(ibw,:), 0);
  secprop_values(ibw,1:14) = props(:,1:14);
  secprop_values(ibw,20:21) = props(:,17:18);  % Zzsc, Zzf
end

% 角形鋼管（HSS + BHSS）
ih = stype==PRM.HSS | stype==PRM.BHSS;
if any(ih)
  secprop_values(ih,1:12) = calc_prop_hss(secdim(ih,:));
end

% RC矩形断面
irc = stype==PRM.RCRS;
if any(irc)
  secprop_values(irc,1:12) = calc_prop_rcrs(secdim(irc,:));
end

% 座屈拘束ブレース
ibrb = stype==PRM.BRB;
if any(ibrb)
  tbl = secmgr.getListRecord(secdim(ibrb,:));
  Abrb = tbl.A*100;
  secprop_values(ibrb,1) = Abrb;
  secprop_values(ibrb,12) = Abrb;
  secprop_values(ibrb,15) = tbl.Lkmax;
end

% 円形鋼管（HSR + BHSR）
ir = stype==PRM.HSR | stype==PRM.BHSR;
if any(ir)
  secprop_values(ir,1:12) = calc_prop_hsr(secdim(ir,:));
end

% 水平ブレース
ihbr = stype==PRM.HBR;
if any(ihbr)
  secprop_values(ihbr,1) = secdim(ihbr,1);
  secprop_values(ihbr,12) = secdim(ihbr,1);
end

% 引張ブレース
itb = stype==PRM.TB;
if any(itb)
  secprop_values(itb,1) = secdim(itb,2);
  secprop_values(itb,12) = secdim(itb,3);
end

% 非WFS断面のAscはAと同値（スカラップなし）
noAs = secprop_values(:,17)==0 & secprop_values(:,1)>0;
secprop_values(noAs,17) = secprop_values(noAs,1);

% 応力度計算用のせん断面積。既定はせん断力検討用断面積Aw（角形鋼管・
% 円形鋼管はSS7のAw）をQy・Qzの両方に用いる。H形鋼はウェブ方向の
% せん断をスカラップ控除後のウェブ面積Aw、フランジ方向のせん断を
% フランジ面積の2/3（SS7の2B・tf／1.5）で受ける（計算編6.4.2、
% 付録1.1）
secprop_values(:,18) = secprop_values(:,12);
secprop_values(:,19) = secprop_values(:,12);
iws = PRM.list_type_of_section_type(stype) == PRM.WFS;
secprop_values(iws,18) = secprop_values(iws,13)*2/3;

% 数値計算結果を列番号順の名前付き列配列へ分離
prop_names = {'A', 'Asy', 'Asz', 'Iy', 'Iz', 'Zy', 'Zz', 'Zyf', ...
  'Zpy', 'Zpz', 'JJ', 'Aw', 'Af', 'Zysc', 'Lkmax', 'Iyr', 'Asc', ...
  'Aqy', 'Aqz', 'Zzsc', 'Zzf'};
for k = 1:numel(prop_names)
  section_property.(prop_names{k}) = secprop_values(:,k);
end

% Y方向強軸のH形鋼柱は局所y・z軸の対を入れ替える。柱の回転角0では
% 局所y軸が全体Y軸に一致し、局所y軸まわりの曲げがX方向フレームの
% 曲げになるため、Iyが弱軸になる。断面積・ねじり定数・ウェブ面積・
% フランジ面積は向きによらない
ii = stype(:)==PRM.CWFSI;
if any(ii)
  yz_pairs = {'Asy', 'Asz'; 'Iy', 'Iz'; 'Zy', 'Zz'; 'Zpy', 'Zpz'; ...
    'Zysc', 'Zzsc'; 'Zyf', 'Zzf'; 'Aqy', 'Aqz'};
  for k = 1:size(yz_pairs, 1)
    values_y = section_property.(yz_pairs{k,1})(ii);
    section_property.(yz_pairs{k,1})(ii) = ...
      section_property.(yz_pairs{k,2})(ii);
    section_property.(yz_pairs{k,2})(ii) = values_y;
  end
end

return
end
