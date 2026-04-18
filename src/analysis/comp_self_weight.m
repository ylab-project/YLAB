function sw = comp_self_weight( ...
  A, lm_weight, lm, member_property, msdim, idn2df, ndf, ...
  mejoint, face_deduct, options, member_column, brace_unit_weight, ...
  Df_foundation, idsup2n, rho_rc_member)
%comp_self_weight - 自重による等価節点荷重を計算
%
% 柱・梁・ブレースの自重および仕上重量から等価節点荷重とCMQを計算する。
%
% 梁の等価節点荷重は、柱面間に荷重が分布することを考慮し、
% 荷重重心位置に基づく偏心配分を行う（SS7方式）。
%
% Inputs:
%   A               - 断面積配列
%   lm_weight       - 荷重計算用部材長配列（等価節点荷重用）
%   lm              - 実際の部材長配列（CMQ計算用）
%   member_property - 部材プロパティ構造体
%   msdim           - 部材断面寸法配列
%   idn2df          - 節点→自由度変換配列
%   ndf             - 全体自由度数
%   mejoint         - 結合条件配列
%   face_deduct     - 梁の柱面減算量 [nmeg x 2]（列1: i端, 列2: j端）
%   options         - オプション構造体
%   member_column   - 柱部材構造体
%   brace_unit_weight - ブレース単位重量 [nmeb x 1] N/mm
%                       （BRB: メーカー値, 他: 0）
%   Df_foundation     - 基礎柱面寸法配列 [nsec×1]（統一断面ID→Df）
%   idsup2n           - 支点節点IDの配列 [nsup×1]
%   rho_rc_member     - RC密度 [nme×1] t/m3（Fc依存）
%
% Outputs:
%   sw - 結果構造体
%        .f   : 等価節点荷重ベクトル
%        .fc  : 柱の等価節点荷重
%        .fg  : 梁の等価節点荷重
%        .fw  : ブレースの等価節点荷重
%        .ar  : 要素座標系の固定端反力
%        .M0  : 単純梁モーメント

% 共通配列
cxl = member_property.cxl;
cyl = member_property.cyl;
mtype = member_property.type;
idme2j1 = member_property.idnode1;
idme2j2 = member_property.idnode2;
stype = member_property.section_type;

% 柱タイプ配列の生成
nme = length(mtype);
column_type = zeros(nme, 1);
column_type(member_column.idme) = member_column.type;

% 分割節点→基礎ノードの置換（idnominalペア）
is_brace1_ = member_column.type == PRM.COLUMN_FOR_BRACE_FOUNDATION;
for ic = 1:length(member_column.idme)
  if member_column.type(ic) ~= PRM.COLUMN_FOR_BRACE_BODY
    continue
  end
  ic_b1 = find(member_column.idnominal(:,1) ...
    == member_column.idnominal(ic, 1) & is_brace1_, 1);
  if isempty(ic_b1)
    continue
  end
  in_split = member_column.idnode1(ic);
  in_base = member_column.idnode1(ic_b1);
  idme2j1(member_column.idme(ic)) = in_base;
  idme2j1(idme2j1 == in_split & mtype == PRM.BRACE) = in_base;
  idme2j2(idme2j2 == in_split & mtype == PRM.BRACE) = in_base;
end

% 部材ID→梁インデックスの変換マップ（偏心配分用）
idme2ig = zeros(nme, 1);
idme2ig(mtype==PRM.GIRDER) = 1:sum(mtype==PRM.GIRDER);

% 計算の準備
ar = zeros(nme,12);
fc = zeros(ndf,1);
fg = zeros(ndf,1);
fw = zeros(ndf,1);
M0 = zeros(nme,1);
rho = zeros(nme,1);
if options.consider_self_weight
  rho(stype==PRM.HSS) = PRM.RHOS;
  rho(stype==PRM.WFS) = PRM.RHOS;
  rho(stype==PRM.RCRS) = rho_rc_member(stype==PRM.RCRS);
  % ブレース（全てS造）
  rho(mtype==PRM.BRACE) = PRM.RHOS;
end
w = A.*rho*PRM.GRAVITY*1.d-6;
% ブレース: BRBはメーカー指定の単位重量で上書き
wb_ = w(mtype == PRM.BRACE);
mask_brb_ = brace_unit_weight > 0;
wb_(mask_brb_) = brace_unit_weight(mask_brb_);
w(mtype == PRM.BRACE) = wb_;
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
  % 角形鋼管のコーナー半径 r を考慮した実周長で仕上重量を算出
  % HSS secdim: 列1=D, 列2=t, 列3=r
  sc = msdim(mtype==PRM.COLUMN&stype==PRM.HSS,1:3);
  peri_sc = 4*(sc(:,1) - 2*sc(:,3)) + 2*pi*sc(:,3);
  wfsc = peri_sc * options.finishing_material_s_column;
  wf(mtype==PRM.COLUMN&stype==PRM.HSS) = wfsc;
  % RC柱(四面仕上)
  rcc = msdim(mtype==PRM.COLUMN&stype==PRM.RCRS,3:4);  % 3,4列目が実寸法
  wfrcc = rcc(:,1)*4*options.finishing_material_rc_column;
  wf(mtype==PRM.COLUMN&stype==PRM.RCRS) = wfrcc;
  % RC梁(両側仕上)
  rcg = msdim(mtype==PRM.GIRDER&stype==PRM.RCRS,1:2);
  wfrcg = (rcg(:,1)+rcg(:,2)*2)*options.finishing_material_rc_girder;
  wf(mtype==PRM.GIRDER&stype==PRM.RCRS) = wfrcg;
end
w = w+wf;

% 部材座標第3軸
czl = cross(cxl, cyl, 2);

% 固定端荷重の計算
%   ar: 要素座標系
%   f, fc, fg, fw: 全体座標系
%   座標変換行列は{F}=[T]^T{f}

for im = 1:nme
  % --- 共通 ---
  li_w = lm_weight(im);  % 等価節点荷重用（荷重計算用部材長）
  wi = w(im);
  ns = idn2df(idme2j1(im),:);
  ne = idn2df(idme2j2(im),:);

  if mtype(im) == PRM.COLUMN
    % === 柱の処理 ===
    % 固定端反力なし、等価節点荷重はPZのみ（全体座標系で直接計算）
    % 柱の自重は常に鉛直方向に作用するため、PZのみに寄与

    % BRACE1: 基礎梁内のRC部分でありS柱自重の対象外
    if column_type(im) == PRM.COLUMN_FOR_BRACE_FOUNDATION
      continue
    end

    ar(im,:) = zeros(1,12);
    W = wi * li_w;  % 総自重
    fi_global = [0; 0; W/2; 0; 0; 0];
    fj_global = [0; 0; W/2; 0; 0; 0];

    fc(ns) = fc(ns)+fi_global;
    fc(ne) = fc(ne)+fj_global;
  elseif mtype(im) == PRM.GIRDER
    % === 梁の処理 ===
    li_m = lm(im);  % CMQ用（実際の部材長）
    t = [cxl(im,:); cyl(im,:); czl(im,:)];
    wv = t*[0; 0; wi];  % 要素座標系での荷重（CMQ計算用）

    % 等価節点荷重の計算（柱面間分布荷重の偏心配分）
    % 鉛直荷重成分（PX, PY, PZ）は全体座標系で直接計算（SS7方式）
    ig = idme2ig(im);
    d1 = face_deduct(ig, 1);  % i端の柱面減算量
    % d2 = face_deduct(ig, 2) は li_w = li_m - d1 - d2 に既に反映済み
    W = wi * li_w;            % 総荷重
    x_cg = d1 + li_w / 2;     % 荷重重心のi端節点からの距離
    % 偏心配分（モーメントのつり合いから）
    fv_i3 = W * (li_m - x_cg) / li_m;  % i端の鉛直荷重
    fv_j3 = W * x_cg / li_m;           % j端の鉛直荷重
    % 等価節点荷重は全体座標系で直接設定（PX=0, PY=0）
    fvi = [0; 0; fv_i3];
    fvj = [0; 0; fv_j3];

    % 接合条件に応じたCMQ計算
    % mejoint: 1:i端(強軸), 2:j端(強軸), 3:i端(弱軸), 4:j端(弱軸)
    joint = mejoint(im,:);
    a = face_deduct(ig, 1);  % i端の柱面減算量
    % j端の柱面減算量（変数名 b との重複を避けるため末尾_）
    b_ = face_deduct(ig, 2);
    L = li_m;                % 通り心間距離
    Lb = L - b_;             % = a + L' (荷重右端位置)
    w3 = wv(3);              % 要素座標系での鉛直荷重成分
    if joint(1)==PRM.PIN && joint(2)==PRM.PIN
      % 両端ピン: 固定端モーメントなし
      cvi = [0; 0; 0];
      cvj = [0; 0; 0];
    elseif joint(1)==PRM.PIN
      % i端ピン: j端のみ固定端モーメント
      % 片持ち梁としてj端まわりのモーメント
      % M_B = ∫[a to Lb] w*(Lb-x) dx = w*[(Lb-a)^2/2] = w*L'^2/2
      % ただしピン支持による反力調整後: M_B = w*L'^2/8 相当（近似）
      cvi = [0; 0; 0];
      cvj = [0; w3*li_w^2/8; 0];
    elseif joint(2)==PRM.PIN
      % j端ピン: i端のみ固定端モーメント
      cvi = [0; w3*li_w^2/8; 0];
      cvj = [0; 0; 0];
    else
      % 両端固定: SS7 計算編 4.2.10 (1) 一般分布荷重の固定端モーメント式
      % 柱面間分布荷重に対し区間 [a, L-b] で積分して算出する。
      %   単位集中荷重 P が位置 x に作用するときの固定端 M:
      %     MA(x) = P·x·(L-x)²/L², MB(x) = P·x²·(L-x)/L²
      %   区間 [a, L-b] で積分:
      %     CA = ∫[a,Lb] w·x(L-x)²/L² dx
      %     CB = ∫[a,Lb] w·x²(L-x)/L² dx
      %   積分結果:
      %     ∫x(L-x)²dx = L²x²/2 - 2Lx³/3 + x⁴/4
      %     ∫x²(L-x)dx = Lx³/3 - x⁴/4
      L2 = L^2;
      FA_Lb = L2*Lb^2/2 - 2*L*Lb^3/3 + Lb^4/4;
      FA_a  = L2*a^2/2  - 2*L*a^3/3  + a^4/4;
      CA = w3/L2 * (FA_Lb - FA_a);
      GB_Lb = L*Lb^3/3 - Lb^4/4;
      GB_a  = L*a^3/3  - a^4/4;
      CB = w3/L2 * (GB_Lb - GB_a);
      cvi = [0; CA; 0];
      cvj = [0; CB; 0];
    end

    % ピン端のモーメント解放に伴うせん断力の再配分
    if joint(1)==PRM.PIN && joint(2)~=PRM.PIN
      % i端ピン: CMQ_jに応じてPZを再配分
      dv = cvj(2) / li_m;
      fvi(3) = fvi(3) - dv;
      fvj(3) = fvj(3) + dv;
    elseif joint(2)==PRM.PIN && joint(1)~=PRM.PIN
      % j端ピン: CMQ_iに応じてPZを再配分
      dv = cvi(2) / li_m;
      fvi(3) = fvi(3) + dv;
      fvj(3) = fvj(3) - dv;
    end

    % 固定端反力（要素座標系）
    % fvi, fvjは全体座標系で計算済みなので、要素座標系に変換してarに格納
    fvi_local = t * fvi;
    fvj_local = t * fvj;
    ari = [fvi_local; -cvi]; arj = [fvj_local; cvj];
    ar(im,:) = [ari; arj];

    % 等価節点荷重（全体座標系）
    % 力成分: 全体座標系で直接計算済み（座標変換不要）
    fi_force = fvi;
    fj_force = fvj;

    % モーメント成分: XY平面内の2D変換のみ適用
    % 梁方向の単位ベクトル（XY平面内で正規化）
    cxl_xy_norm = norm(cxl(im, 1:2));
    if cxl_xy_norm > 0
      cos_theta = cxl(im, 1) / cxl_xy_norm;
      sin_theta = cxl(im, 2) / cxl_xy_norm;
    else
      % 鉛直梁の場合（通常は存在しない）
      cos_theta = 1;
      sin_theta = 0;
    end
    % 要素座標系のMy（強軸）を全体座標系のMX, MYに変換
    % cvi(2), cvj(2)は要素座標系の強軸回りモーメント
    fi_moment = [-sin_theta * (-cvi(2)); cos_theta * (-cvi(2)); 0];
    fj_moment = [-sin_theta * cvj(2); cos_theta * cvj(2); 0];

    fg(ns) = fg(ns) + [fi_force; fi_moment];
    fg(ne) = fg(ne) + [fj_force; fj_moment];
    m0m = wv(3)*li_m^2/8;  % M0も実際の部材長を使用
    M0(im) = m0m;
  elseif mtype(im) == PRM.BRACE
    % === ブレースの処理 ===
    % W/2ずつ両端PZに配分（固定端反力なし）
    ar(im,:) = zeros(1,12);
    W = wi * li_w;
    fi_global = [0; 0; W/2; 0; 0; 0];
    fj_global = [0; 0; W/2; 0; 0; 0];
    fw(ns) = fw(ns) + fi_global;
    fw(ne) = fw(ne) + fj_global;
  end
end

% --- 基礎柱自重 ---
% SS7計算編 4.1.2(4): W = γ_RC × Df² × D（基礎梁せい）
nme_ = length(mtype);
idm2s_ = member_property.idsec;
for isup = 1:length(idsup2n)
  in_sup = idsup2n(isup);
  % 支点節点にとりつく柱からDfを取得
  Df_ = 0; im_col_ = 0;
  for ic = 1:length(member_column.idme)
    im_ = member_column.idme(ic);
    if idme2j1(im_) ~= in_sup && idme2j2(im_) ~= in_sup
      continue
    end
    Df_ = Df_foundation(idm2s_(im_));
    if Df_ > 0
      im_col_ = im_;
      break
    end
  end
  if Df_ <= 0
    continue
  end
  % 支点節点にとりつくRC梁から基礎梁せいを取得（最大値）
  D_beam = 0;
  for im_ = 1:nme_
    if mtype(im_) ~= PRM.GIRDER
      continue
    end
    if idme2j1(im_) ~= in_sup && idme2j2(im_) ~= in_sup
      continue
    end
    if stype(im_) == PRM.RCRS
      D_beam = max(D_beam, msdim(im_, 2));
    end
  end
  if D_beam <= 0
    continue
  end
  % 基礎柱自重の計算と加算（Fc依存密度）
  gamma_rc_ = rho_rc_member(im_col_) * PRM.GRAVITY * 1.d-6;
  W_ = gamma_rc_ * Df_ * Df_ * D_beam;
  ns_ = idn2df(in_sup, :);
  fc(ns_) = fc(ns_) + [0; 0; W_; 0; 0; 0];
end

% 結果の保存
sw.f = fc+fg+fw;
sw.fc = fc;
sw.fg = fg;
sw.fw = fw;
sw.ar = ar;
sw.M0 = M0;
return
end

