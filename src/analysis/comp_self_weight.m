function sw = comp_self_weight(...
  A, lm, member_property, msdim, slab, idn2df, mejoint, options)

% 共通配列
cxl = member_property.cxl;
cyl = member_property.cyl;
mtype = member_property.type;
idme2j1 = member_property.idnode1;
idme2j2 = member_property.idnode2;
% l = sqrt(lx.^2+ly.^2+lz.^2);
stype = member_property.section_type;
gstype = stype(mtype==PRM.GIRDER);

% 共通定数
nme = length(mtype);
ndf = max(idn2df,[],'all');

% 重複スラブの考慮
slab_thickness = max(slab.thickness,[],2);
slab_thickness(gstype~=PRM.RCRS,:) = 0;
b = msdim(mtype==PRM.GIRDER,1);
A(mtype==PRM.GIRDER) = A(mtype==PRM.GIRDER)-b.*slab_thickness;

% 計算の準備
ar = zeros(nme,12);
fc = zeros(ndf,1);
fg = zeros(ndf,1);
M0 = zeros(nme,1);
rho = zeros(nme,1);
if options.consider_self_weight
  rho(stype==PRM.HSS) = PRM.RHOS;
  rho(stype==PRM.WFS) = PRM.RHOS;
  rho(stype==PRM.RCRS) = PRM.RHORC;
end
w = A.*rho*PRM.GRAVITY*1.d-6;
efc = options.self_weight_extra_factor_column;
efg = options.self_weight_extra_factor_girder;
% S柱のみに割増率適用
w(mtype==PRM.COLUMN & stype==PRM.HSS) = ...
  w(mtype==PRM.COLUMN & stype==PRM.HSS) * efc;
% S梁のみに割増率適用
w(mtype==PRM.GIRDER & stype==PRM.WFS) = ...
  w(mtype==PRM.GIRDER & stype==PRM.WFS) * efg;

% 仕上荷重の計算
wf = zeros(nme,1);
if options.consider_finishing_material
  % S梁(両側仕上)
  sg = msdim(mtype==PRM.GIRDER&stype==PRM.WFS,1:2);
  wfsg = (sg(:,1)*2+sg(:,2))*options.finishing_material_s_girder;
  wf(mtype==PRM.GIRDER&stype==PRM.WFS) = wfsg;
  % S柱(四面仕上)
  sc = msdim(mtype==PRM.COLUMN&stype==PRM.HSS,1:2);
  wfsc = sc(:,1)*4*options.finishing_material_s_column;
  wf(mtype==PRM.COLUMN&stype==PRM.HSS) = wfsc;
  % RC柱(四面仕上)
  rcc = msdim(mtype==PRM.COLUMN&stype==PRM.RCRS,3:4);  % 3,4列目が実寸法
  wfrcc = rcc(:,1)*4*options.finishing_material_rc_column;
  wf(mtype==PRM.COLUMN&stype==PRM.RCRS) = wfrcc;
  % RC梁(両側仕上)
  rcg = msdim(mtype==PRM.GIRDER&stype==PRM.RCRS,1:2);
  % rcgt = slab_thickness(gstype==PRM.RCRS);
  rcgt = slab.thickness(gstype==PRM.RCRS);
  wfrcg = (rcg(:,1)+rcg(:,2)*2-rcgt)*options.finishing_material_rc_girder;
  wf(mtype==PRM.GIRDER&stype==PRM.RCRS) = wfrcg;
end
w = w+wf;

% 部材座標第3軸
czl = cross(cxl, cyl, 2);

% 固定端荷重の計算
%   ar: 要素座標系
%   f,fc,fg: 全体座標系
%   座標変換行列は{F}=[T]^T{f}

for im = 1:nme
  % --- 共通 ---
  li = lm(im); wi = w(im);
  t = [cxl(im,:); cyl(im,:); czl(im,:)];

  % --- 要素座標系 ---
  wv = t*[0; 0; wi];
  fv = [wv(1)*li/2; 0; wv(3)*li/2];

  % 接合条件に応じたCMQ計算
  % mejoint: 1:i端(強軸), 2:j端(強軸), 3:i端(弱軸), 4:j端(弱軸)
  joint = mejoint(im,:);
  if mtype(im) == PRM.GIRDER
    if joint(1)==PRM.PIN && joint(2)==PRM.PIN
      % 両端ピン
      cvi = [0; 0; 0];
      cvj = [0; 0; 0];
    elseif joint(1)==PRM.PIN
      % i端ピン
      cvi = [0; 0; 0];
      cvj = [0; wv(3)*li^2/8; 0];
    elseif joint(2)==PRM.PIN
      % j端ピン
      cvi = [0; wv(3)*li^2/8; 0];
      cvj = [0; 0; 0];
    else
      % 両端固定
      cvi = [0; wv(3)*li^2/12; 0];
      cvj = [0; wv(3)*li^2/12; 0];
    end
  else
    % 柱は常に両端固定
    cvi = [0; wv(3)*li^2/12; 0];
    cvj = [0; wv(3)*li^2/12; 0];
  end
  ari = [fv; -cvi]; arj = [fv; cvj];
  ar(im,:) = [ari; arj];

  % --- 全体座標系 ---
  fi = [t'*ari(1:3); t'*ari(4:6)];
  fj = [t'*arj(1:3); t'*arj(4:6)];
  ns = idn2df(idme2j1(im),:);
  ne = idn2df(idme2j2(im),:);
  switch mtype(im)
    case PRM.COLUMN
      fc(ns) = fc(ns)+fi;
      fc(ne) = fc(ne)+fj;
    case PRM.GIRDER
      fg(ns) = fg(ns)+fi;
      fg(ne) = fg(ne)+fj;
      m0m = wv(3)*li^2/8;
      M0(im) = m0m;
  end
end

% 結果の保存
sw.f = fc+fg;
sw.fc = fc;
sw.fg = fg;
sw.ar = ar;
sw.M0 = M0;
return
end

