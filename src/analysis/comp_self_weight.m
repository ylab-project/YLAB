function sw = comp_self_weight(A, Asy, Iy, Em, Gm, lm_weight, ...
  lm_lower_extension, lm, lrxm, member_property, msdim, slab, cxl, ...
  cyl, nnode, mejoint, weight_deduct, options, member_column, ...
  brace_unit_weight, Df_foundation, girder_level, girder_isfg, ...
  idsup2n, rho_rc_member)
%comp_self_weight - 自重による等価節点荷重を計算
%
%   sw = comp_self_weight(A, Asy, Iy, Em, Gm, lm_weight, ...
%   lm_lower_extension, lm, lrxm, member_property, msdim, slab, cxl, ...
%   cyl, nnode, mejoint, weight_deduct, options, member_column, ...
%   brace_unit_weight, Df_foundation, girder_level, girder_isfg, ...
%   idsup2n, rho_rc_member) は、
%   柱・梁・ブレースの自重および仕上重量から等価節点荷重とCMQを
%   計算する。梁は柱面間の分布荷重に対し、両端固定の固定端モーメント
%   と単純梁反力に固定端モーメント差の補正を加えた端部せん断力を
%   求め、結合条件がピンの端は固定端モーメントを0として他端へ
%   伝達する。options.consider_rigid_zone_cmq がtrueのときは可撓部分で
%   求めた固定端応力を剛域を通して節点へ伝える（SS7 計算編 4.2.10 (3)）。
%
%   入力引数:
%     A               - 断面積配列
%     Asy             - 強軸方向のせん断断面積配列
%     Iy              - 強軸方向の断面2次モーメント配列
%     Em,Gm           - ヤング係数・せん断弾性係数配列
%     lm_weight       - 柱・ブレースの荷重計算用部材長配列
%                       （等価節点荷重用。梁では未使用）
%     lm_lower_extension - 柱脚節点より下に延びる物理長配列
%     lm              - 実際の部材長配列（CMQ計算用）
%     lrxm            - 強軸方向の両端剛域長配列
%     member_property - 部材プロパティ構造体
%     msdim           - 部材断面寸法配列
%     slab            - スラブ情報構造体（RC梁の重複スラブ控除用、
%                       .width/.thickness/.width_lower/.thickness_lower
%                       /.deck_height/.deck_height_lower）。
%                       デッキ高さのNaNは通常床、数値0もデッキ床
%     cxl,cyl         - 部材座標系の方向余弦
%     nnode           - 全節点数
%     mejoint         - 結合条件配列
%     weight_deduct   - 梁の符号付き自重控除長 [nmeg x 2]
%                       （列1: i端, 列2: j端。正値は分布荷重から
%                       控除し、負値は端部集中重量として加算）
%     options         - オプション構造体
%     member_column   - 柱部材構造体（BODYのidsplitはFOUNDATION番号）
%     brace_unit_weight - ブレース単位重量 [nmeb x 1] N/mm
%                         （BRB: メーカー値, 他: 0）
%     Df_foundation   - 基礎柱面寸法配列 [nsec×1]（統一断面ID→Df）
%     girder_level    - 梁レベル調整値（下げが負） [nmeg×1]
%     girder_isfg     - 基礎梁フラグ [nmeg×1]
%     idsup2n         - 支点節点IDの配列 [nsup×1]
%     rho_rc_member   - RC密度 [nme×1] t/m3（Fc依存）
%
%   出力引数:
%     sw - 結果構造体
%          .f   : 等価節点荷重 (nnode, 6)
%          .fc  : 柱の等価節点荷重 (nnode, 6)
%          .fg  : 梁の等価節点荷重 (nnode, 6)
%          .fw  : ブレースの等価節点荷重 (nnode, 6)
%          .ar  : 要素座標系の固定端反力
%          .M0  : 単純梁モーメント

mtype = member_property.type;
idme2j1 = member_property.idnode1;
idme2j2 = member_property.idnode2;
stype = member_property.section_type;

% 柱タイプ配列の生成
nme = length(mtype);
column_type = zeros(nme, 1);
column_type(member_column.idme) = member_column.type;

% BODYとブレースの自重をFOUNDATIONの柱脚節点へ配分する。
% BODYのidsplitから下側要素を取得する。
for ic = 1:length(member_column.idme)
  if member_column.type(ic) ~= PRM.COLUMN_FOR_BRACE_BODY
    continue
  end
  ic_b1 = member_column.idsplit(ic);
  in_split = member_column.idnode1(ic);
  in_base = member_column.idnode1(ic_b1);
  idme2j1(member_column.idme(ic)) = in_base;
  idme2j1(idme2j1 == in_split & mtype == PRM.BRACE) = in_base;
  idme2j2(idme2j2 == in_split & mtype == PRM.BRACE) = in_base;
end

% 部材ID→梁インデックスの変換マップ（偏心配分用）
idme2ig = zeros(nme, 1);
idme2ig(mtype==PRM.GIRDER) = 1:sum(mtype==PRM.GIRDER);

% 断面種別による部材のマスク。柱と梁はRC矩形断面以外がS造
% （角形鋼管・円形鋼管・H形鋼の柱とH形鋼の梁）
is_rc_member = stype==PRM.RCRS;
is_s_column = mtype==PRM.COLUMN & ~is_rc_member;
is_s_girder = mtype==PRM.GIRDER & ~is_rc_member;
is_rc_column = mtype==PRM.COLUMN & is_rc_member;
is_rc_girder = mtype==PRM.GIRDER & is_rc_member;

% RC梁のスラブ重複体積の差し引き（SS7 計算編 式4.1, 4.3）
% 梁幅 B を左右 B/2 に分け、各半分を対応する側の床（上面＋下面）と
% 独立に差し引く。各半分の差し引き後は 0 でクリップ（スラブ厚が
% 梁せいを上回る入力に対する保護）。
% S梁は対象外（床荷重は梁要素荷重として別途考慮される）。
% デッキ床は SS7 式4.3 の対象外（「床（デッキ床除く）」）のため、
% デッキ高さがNaNの通常床だけを控除する。明示0もデッキ床である。
% t_left/t_right は仕上の周長控除（式4.9 の -Ls・t）にも用いる。
is_rc = is_rc_girder(mtype==PRM.GIRDER);
has_slab_u = slab.width > 0 & isnan(slab.deck_height);
t_u1 = slab.thickness(:,1) .* has_slab_u(:,1);
t_u2 = slab.thickness(:,2) .* has_slab_u(:,2);
has_slab_l = slab.width_lower > 0 & isnan(slab.deck_height_lower);
t_l1 = slab.thickness_lower(:,1) .* has_slab_l(:,1);
t_l2 = slab.thickness_lower(:,2) .* has_slab_l(:,2);
% S梁の t は 0（差し引きなし）
t_left  = (t_u1 + t_l1) .* is_rc;
t_right = (t_u2 + t_l2) .* is_rc;
b_g = msdim(mtype==PRM.GIRDER, 1);
A_half = A(mtype==PRM.GIRDER) / 2;
A_left  = max(A_half - b_g/2 .* t_left, 0);
A_right = max(A_half - b_g/2 .* t_right, 0);
A(mtype==PRM.GIRDER) = A_left + A_right;

% 計算の準備
ar = zeros(nme,12);
fc = zeros(nnode, 6);
fg = zeros(nnode, 6);
fw = zeros(nnode, 6);
M0 = zeros(nme,1);
% S部材の自重は断面積×鋼材の単位容積重量×割増率（計算編 式4.15）。
% ブレースは全てS造。水平ブレースの自重は考慮しない
rho = zeros(nme,1);
if options.consider_self_weight
  rho(is_s_column | is_s_girder | mtype==PRM.BRACE) = PRM.RHOS;
  rho(is_rc_member) = rho_rc_member(is_rc_member);
end
w = A.*rho*PRM.GRAVITY*1.d-6;
% ブレース: BRBはメーカー指定の単位重量で上書き
wb_ = w(mtype == PRM.BRACE);
mask_brb_ = brace_unit_weight > 0;
wb_(mask_brb_) = brace_unit_weight(mask_brb_);
w(mtype == PRM.BRACE) = wb_;
% S柱・S梁に割増率を適用
w(is_s_column) = w(is_s_column) * options.self_weight_extra_factor_column;
w(is_s_girder) = w(is_s_girder) * options.self_weight_extra_factor_girder;

% 仕上荷重の計算
wf = zeros(nme,1);
if options.consider_finishing_material
  % S梁(両側仕上)
  sg = msdim(is_s_girder,1:2);
  wf(is_s_girder) = (sg(:,1)*2+sg(:,2)) ...
    *options.finishing_material_s_girder;
  % S柱(四面仕上): 仕上の周長は、角形鋼管がコーナー半径rを考慮した
  % 実周長（secdim 列1=D, 列2=t, 列3=r）、円形鋼管が円周、H形鋼が
  % 外接矩形の2(H+B)で向きによらない（計算編 図4.15）
  peri_sc = zeros(nme,1);
  is_col_hss = is_s_column & stype==PRM.HSS;
  sc = msdim(is_col_hss,1:3);
  peri_sc(is_col_hss) = 4*(sc(:,1) - 2*sc(:,3)) + 2*pi*sc(:,3);
  is_col_hsr = is_s_column & stype==PRM.HSR;
  peri_sc(is_col_hsr) = pi*msdim(is_col_hsr,1);
  is_col_h = is_s_column & (stype==PRM.CWFS | stype==PRM.CWFSI);
  peri_sc(is_col_h) = 2*(msdim(is_col_h,1) + msdim(is_col_h,2));
  wf(is_s_column) = peri_sc(is_s_column) ...
    *options.finishing_material_s_column;
  % RC柱(四面仕上): 3列目が荷重剛性用寸法
  wf(is_rc_column) = msdim(is_rc_column,3)*4 ...
    *options.finishing_material_rc_column;
  % RC梁(両側仕上)
  % スラブが取り付く側面は仕上が不要なため、自重側で算出済みの
  % 左右スラブ厚を周長から控除する（式4.9 の -Ls・t 相当、左右別）
  rcg = msdim(is_rc_girder,1:2);
  ded_f = t_left(is_rc) + t_right(is_rc);
  wf(is_rc_girder) = (rcg(:,1) + rcg(:,2)*2 - ded_f) ...
    * options.finishing_material_rc_girder;
end
w = w+wf;

% 部材座標第3軸
czl = cross(cxl, cyl, 2);

% 剛域を考慮した荷重項（SS7 計算編 4.2.10 (3)）では、分布荷重を
% 剛域端で可撓部分と剛域部分に分け、可撓部分の固定端モーメントと
% せん断力を剛域先端の外力として節点（剛域の元端）へ伝える。
% 考慮しない場合は剛域長を0とし、同じ式で節点間の梁として求める。
lr_cmq = lrxm .* options.consider_rigid_zone_cmq;

% 固定端荷重の計算
%   ar: 要素座標系
%   f, fc, fg, fw: 全体座標系
%   座標変換行列は{F}=[T]^T{f}

for im = 1:nme
  % --- 共通 ---
  li_w = lm_weight(im);  % 柱・ブレースの等価節点荷重用（梁では未使用）
  wi = w(im);
  in1 = idme2j1(im);
  in2 = idme2j2(im);

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
    % lm_lower_extension は柱脚節点より下に延びる物理長である。
    % この区間の自重は柱脚節点へ全量、残りは両端へ等分する。
    W_lower = wi * lm_lower_extension(im);
    fi_global = [0, 0, (W + W_lower)/2, 0, 0, 0];
    fj_global = [0, 0, (W - W_lower)/2, 0, 0, 0];

    fc(in1, :) = fc(in1, :) + fi_global;
    fc(in2, :) = fc(in2, :) + fj_global;
  elseif mtype(im) == PRM.GIRDER
    % === 梁の処理 ===
    L = lm(im);  % 部材長（通り心間距離）
    t = [cxl(im,:); cyl(im,:); czl(im,:)];
    wv = t*[0; 0; wi];  % 要素座標系での荷重（CMQ計算用）

    % 符号付き自重控除長を分布区間と端部集中重量へ分離する。
    % 正値は分布荷重から控除し、負値は節点外側の重量として
    % 対応する端部PZへ加算する。
    ig = idme2ig(im);
    deduct_i = weight_deduct(ig, 1);
    deduct_j = weight_deduct(ig, 2);
    a = max(deduct_i, 0);       % 分布荷重のi端控除長
    b = max(deduct_j, 0);       % 分布荷重のj端控除長
    lump_i = max(-deduct_i, 0); % i端へ集中させる節点外長さ
    lump_j = max(-deduct_j, 0); % j端へ集中させる節点外長さ
    Lb = L - b;                 % 分布荷重の右端位置

    % 荷重項の可撓長さ Lf と、せん断変形係数の可撓長さ Ly（梁剛性
    % 行列の強軸と同じ定義）
    lr1 = lr_cmq(im,1);
    lr2 = lr_cmq(im,2);
    Lf = L - lr1 - lr2;
    Ly = L - sum(lrxm(im,:));
    xa = max(a, lr1) - lr1;               % 可撓部分の荷重左端
    xb = max(min(Lb, L - lr2) - lr1, xa); % 可撓部分の荷重右端
    % 剛域内に掛かる分布荷重の長さと、節点からその重心までの距離
    li = max(min(Lb, lr1) - a, 0);
    ei = a + li/2;
    lj = max(Lb - max(a, L - lr2), 0);
    ej = L - Lb + lj/2;

    % 以下は分布荷重の強さを1として求め、最後に鉛直力は wi、
    % モーメントは要素座標系の鉛直成分 w3 を掛ける。
    % 可撓部分の両端固定の固定端モーメントは、単位集中荷重 P が
    % 可撓座標 x に作用するときの
    %   MA(x) = P·x·(Lf-x)^2/Lf^2, MB(x) = P·x^2·(Lf-x)/Lf^2
    % を区間 [xa, xb] で積分して求める。
    Lf2 = Lf^2;
    FA_xb = Lf2*xb^2/2 - 2*Lf*xb^3/3 + xb^4/4;
    FA_xa = Lf2*xa^2/2 - 2*Lf*xa^3/3 + xa^4/4;
    ca = (FA_xb - FA_xa)/Lf2;
    GB_xb = Lf*xb^3/3 - xb^4/4;
    GB_xa = Lf*xa^3/3 - xa^4/4;
    cb = (GB_xb - GB_xa)/Lf2;
    % 可撓部分の単純梁反力
    ra = (xb - xa)*(Lf - (xa + xb)/2)/Lf;
    rb = (xb - xa)*(xa + xb)/2/Lf;

    % 接合条件に応じた可撓端の固定端モーメント
    % mejoint: 1:i端(強軸), 2:j端(強軸), 3:i端(弱軸), 4:j端(弱軸)
    joint = mejoint(im,:);
    w3 = wv(3);              % 要素座標系での鉛直荷重成分
    if options.consider_shear_deformation
      ry = calc_shear_deformation_ratio(Em(im), Iy(im), Gm(im), ...
        Asy(im), Ly);
    else
      ry = 0;
    end
    if joint(1)==PRM.PIN && joint(2)==PRM.PIN
      % 両端ピン: 可撓部分の固定端モーメントなし
      ca_fix = 0;
      cb_fix = 0;
    elseif joint(1)==PRM.PIN
      % i端ピン: 剛性比によりi端解放分をj端へ伝達
      ca_fix = 0;
      cb_fix = cb + ca*(1-ry)/(2+ry);
    elseif joint(2)==PRM.PIN
      % j端ピン: 剛性比によりj端解放分をi端へ伝達
      ca_fix = ca + cb*(1-ry)/(2+ry);
      cb_fix = 0;
    else
      % 両端固定: SS7 計算編 4.2.10 (1) 一般分布荷重式
      ca_fix = ca;
      cb_fix = cb;
    end
    % 可撓端のせん断力は単純梁反力に固定端モーメント差の補正を加える
    va = ra + (ca_fix - cb_fix)/Lf;
    vb = rb - (ca_fix - cb_fix)/Lf;
    % 剛域部分を片持梁とみなし、可撓端の固定端応力と剛域内荷重を
    % 節点へ伝える。ピン端でも剛域があれば節点モーメントは残る
    % （両端ピンを含む。SS7の梁CMoQo表で確認）
    ma = ca_fix + va*lr1 + li*ei;
    mb = cb_fix + vb*lr2 + lj*ej;
    pa = va + li;
    pb = vb + lj;
    fvi = [0; 0; wi*(pa + lump_i)];
    fvj = [0; 0; wi*(pb + lump_j)];
    cvi = [0; w3*ma; 0];
    cvj = [0; w3*mb; 0];

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

    fg(in1, :) = fg(in1, :) + [fi_force; fi_moment]';
    fg(in2, :) = fg(in2, :) + [fj_force; fj_moment]';
    % 区間 [a, L-b] に等分布する荷重の単純梁中央 M (SS7 互換)
    % M(L/2) = w * (L²/8 - (a² + b²)/4)
    % SS7 マニュアル 4.1.1(1) 式 4.5: 自重は柱面間 L で計算
    m0m = wv(3)*(L^2/8 - (a^2 + b^2)/4);
    M0(im) = m0m;
  elseif mtype(im) == PRM.BRACE
    % === ブレースの処理 ===
    % W/2ずつ両端PZに配分（固定端反力なし）
    ar(im,:) = zeros(1,12);
    W = wi * li_w;
    fi_global = [0, 0, W/2, 0, 0, 0];
    fj_global = [0, 0, W/2, 0, 0, 0];
    fw(in1, :) = fw(in1, :) + fi_global;
    fw(in2, :) = fw(in2, :) + fj_global;
  end
end

% --- 基礎柱自重 ---
% SS7計算編 4.1.2(4): W = gamma_RC * A_B * L_B
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
  % 支点節点にとりつく基礎梁から基礎柱高さL_Bを取得
  ztop_max = -inf;
  zbot_min = inf;
  for im_ = 1:nme_
    if mtype(im_) ~= PRM.GIRDER
      continue
    end
    if idme2j1(im_) ~= in_sup && idme2j2(im_) ~= in_sup
      continue
    end
    ig_ = idme2ig(im_);
    if ~girder_isfg(ig_) || stype(im_) ~= PRM.RCRS
      continue
    end
    ztop_ = girder_level(ig_);
    zbot_ = ztop_ - msdim(im_, 2);
    ztop_max = max(ztop_max, ztop_);
    zbot_min = min(zbot_min, zbot_);
  end
  L_B_ = ztop_max - zbot_min;
  if ~isfinite(L_B_) || L_B_ <= 0
    continue
  end
  % 基礎柱自重の計算と加算（Fc依存密度）
  gamma_rc_ = rho_rc_member(im_col_) * PRM.GRAVITY * 1.d-6;
  W_ = gamma_rc_ * Df_ * Df_ * L_B_;
  fc(in_sup, :) = fc(in_sup, :) + [0, 0, W_, 0, 0, 0];
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

