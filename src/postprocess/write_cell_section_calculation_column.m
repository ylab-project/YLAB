function sccbody = write_cell_section_calculation_column( ...
  com, result, options)
%write_cell_section_calculation_column - S柱断面算定表のセル配列を生成する
%
%   sccbody = write_cell_section_calculation_column(
%     com, result, options) は、各階・各符号の名目柱に対する
%   応力・断面諸量・検定比をまとめた断面算定表のボディ行を
%   出力用セル配列として返す。
%
%   入力引数:
%     com     - 共通データ構造体（部材・断面・管理情報）
%     result  - 解析結果構造体（kcx/kcy, lkx/lky, ration等）
%     options - 出力オプション構造体
%
%   出力引数:
%     sccbody - 断面算定表のボディ行セル配列 [nrow×ncol]

% 定数
nnc = com.num.nominal_column;
nlc = com.nlc;
nstory = com.nstory;
mb = 14;
ncol = 25;

% 共通配列
column = com.member.column;
nominal_column = com.nominal.column;
secc = com.section.column;
secmgr = com.secmgr;
secdim = result.secdim;
stype = com.section.property.type;
dfn = result.dfn;
fbn = result.fbn;
fcn = result.fcn;
A = result.msprop.A;
Asy = result.msprop.Asy;
Asz = result.msprop.Asz;
Iy = result.msprop.Iy;
Iz = result.msprop.Iz;
Zy = result.msprop.Zy;
Zz = result.msprop.Zz;
F = result.msprop.F;
kcx = result.kcx;
kcy = result.kcy;
lkx = result.lkx;
lky = result.lky;
lambday = result.lambday;
lambdaz = result.lambdaz;
ration = abs(result.ration);
lfcx = result.lf.columnx;
lfcy = result.lf.columny;
lm_nominal = result.lm_nominal;
cri_all = result.cri;
crj_all = result.crj;
csi_all = result.csi;
csj_all = result.csj;
idsecc2sec = com.section.column.idsec;

if isempty(ration)
  sccbody = cell(0, ncol);
  return
end

% 断面2次半径
iy_ = sqrt(Iy ./ A);
iz_ = sqrt(Iz ./ A);

% 柱許容応力度比
cri = reshape(cri_all, [], nlc) + 1;
crj = reshape(crj_all, [], nlc) + 1;
csi = reshape(csi_all, nnc, nlc) + 1;
csj = reshape(csj_all, nnc, nlc) + 1;

% 各名目柱の最大検定比（代表部材選定用）
max_ratio_all = max(max(cri, [], 2), max(crj, [], 2));

% ID変換
idnm2sc = column.idsecc(nominal_column.idmec(:, 1));
nmec1_ = nominal_column.idmec(:, 1);
idnm2story = column.idstory(nmec1_, 1);
idnm2mc = nominal_column.idmec;
idnmc2nm = nominal_column.idnominal;
idmc2m = column.idme;

% 判定ランク
has_drank = isfield(result, 'rank') && isfield(result.rank, 'section');

% 出力順序マッピング（出力制御の符号順）
ocl_ = options.output_column_list_label;
secc_order = zeros(nnc, 1);
if ~isempty(ocl_)
  for inc_ = 1:nnc
    name_ = secc.name{idnm2sc(inc_)};
    pos_ = find(matches(ocl_, name_), 1);
    if ~isempty(pos_)
      secc_order(inc_) = pos_;
    else
      secc_order(inc_) = numel(ocl_) + idnm2sc(inc_);
    end
  end
else
  secc_order(:) = idnm2sc;
end

% --- S柱断面算定表 ---
sccbody = cell(mb * nnc, ncol);
iccc = 1:nnc;
irow = 0;
for i = 1:nstory
  ist = nstory - i + 1;
  mask_ = idnm2story == ist & nominal_column.is_allowable_stress;
  cands_ = iccc(mask_);
  [~, ord_] = sort(secc_order(cands_));
  cands_ = cands_(ord_);
  if ~options.section_calc_all_members
    cands_ = pick_representative(cands_);
  end
  if isempty(cands_)
    continue
  end

  % --- 鉄骨ヘッダ行（各階先頭） ---
  inc0_ = cands_(1);
  isc0_ = idnm2sc(inc0_);
  is0_ = idsecc2sec(isc0_);
  idsl0_ = secdim(is0_, 6);
  mat0_ = secmgr.secList.material_name{idsl0_, 1};
  idsub0_ = nominal_column.idsub(inc0_, :);
  ic1_0 = idnm2mc(inc0_, idsub0_(1));
  im1_0 = idmc2m(ic1_0);
  ic2_0 = idnm2mc(inc0_, idsub0_(2));
  im2_0 = idmc2m(ic2_0);
  F_top_ = F(im2_0);
  F_bot_ = F(im1_0);
  irow = irow + 1;
  sccbody{irow, 1} = '鉄骨      柱頭      Ｆ値    柱脚      Ｆ値';
  irow = irow + 1;
  sccbody{irow, 1} = sprintf('[ %-9s]  %.1f  [ %-9s]  %.1f', ...
    mat0_, F_top_, mat0_, F_bot_);
  irow = irow + 1; % 空行

  for k_ = 1:length(cands_)
    inc = cands_(k_);
    inm = idnmc2nm(inc);

    % --- 最大ケースの判定 ---
    cri_x = cri(inc, [1 2 3]) + [eps eps 0];
    cri_y = cri(inc, [1 4 5]) + [eps eps 0];
    crj_x = crj(inc, [1 2 3]) + [eps eps 0];
    crj_y = crj(inc, [1 4 5]) + [eps eps 0];
    csi_x = csi(inc, [1 2 3]) + [eps eps 0];
    csi_y = csi(inc, [1 4 5]) + [eps eps 0];
    csj_x = csj(inc, [1 2 3]) + [eps eps 0];
    csj_y = csj(inc, [1 4 5]) + [eps eps 0];
    [~, ilx] = max(cri_x);
    [~, ily] = max(cri_y);
    [~, jlx] = max(crj_x);
    [~, jly] = max(crj_y);
    [~, isx] = max(csi_x);
    [~, isy] = max(csi_y);
    [~, jsx] = max(csj_x);
    [~, jsy] = max(csj_y);
    if ily > 1
      ily = ily + 2;
    end
    if jly > 1
      jly = jly + 2;
    end
    if isy > 1
      isy = isy + 2;
    end
    if jsy > 1
      jsy = jsy + 2;
    end

    % --- 箇所ごとの部材番号 ---
    idsub = nominal_column.idsub(inc, :);
    ic1 = idnm2mc(inc, idsub(1));
    im1 = idmc2m(ic1);
    ic2 = idnm2mc(inc, idsub(2));
    im2 = idmc2m(ic2);
    isc_ = idnm2sc(inc);

    % === Row 1: 符号行 + 応力ヘッダ ===
    irow = irow + 1;
    sccbody{irow, 1} = sprintf('[%s]', ...
      [secc.subindex{isc_} secc.name{isc_}]);
    flnm_ = column.floor_name{ic1};
    sccbody{irow, 3} = sprintf('[%s', flnm_);
    sccbody{irow, 5} = column.coord_name{ic1, 1};
    cdnm_ = column.coord_name{ic1, 2};
    sccbody{irow, 7} = sprintf('%s]', cdnm_);
    sccbody{irow, 11} = '位置';
    sccbody{irow, 12} = 'NL';
    sccbody{irow, 13} = 'ML''';
    sccbody{irow, 14} = 'QL';
    sccbody{irow, 15} = '[部材]';
    sccbody{irow, 16} = 'ｹｰｽ';
    sccbody{irow, 17} = 'N';
    sccbody{irow, 18} = 'M';
    sccbody{irow, 19} = 'Q';

    % === Row 2: 断面行 + <X>柱頭 応力 ===
    irow = irow + 1;
    is2_ = idsecc2sec(isc_);
    stype_ = stype(is2_);
    dim_ = secdim(is2_, :);
    idsl_ = secdim(is2_, 6);
    idsec_ = secdim(is2_, 7);
    sl_ = secmgr.secList.list{idsl_};
    sym_ = sl_.symbol{idsec_};
    secname_ = format_steel_cost_dim(stype_, dim_, sym_);
    if has_drank
      is_r = idsecc2sec(isc_);
      rk_v = result.rank.section(is_r);
      if rk_v >= 1 && rk_v <= numel(PRM.MEMBER_RANK_NAME)
        rk_s = PRM.MEMBER_RANK_NAME{rk_v};
      else
        rk_s = '';
      end
    else
      rk_s = '';
    end
    sccbody{irow, 1} = sprintf('%s [%s]', secname_, rk_s);
    sccbody{irow, 10} = '<X>柱頭';
    sccbody{irow, 11} = sprintf('%.0f', lfcx(ic2, 2));
    d71_ = -dfn(inm, 7, 1) * 1e-3;
    sccbody{irow, 12} = sprintf('%.0f', d71_);
    d111_ = dfn(inm, 11, 1) * 1e-6;
    sccbody{irow, 13} = sprintf('%.0f', d111_);
    d91_ = dfn(inm, 9, 1) * 1e-3;
    sccbody{irow, 14} = sprintf('%.0f', d91_);
    sccbody{irow, 16} = PRM.load_case_combo_name(jlx);
    d7jlx_ = -dfn(inm, 7, jlx) * 1e-3;
    sccbody{irow, 17} = sprintf('%.0f', d7jlx_);
    d11jlx_ = dfn(inm, 11, jlx) * 1e-6;
    sccbody{irow, 18} = sprintf('%.0f', d11jlx_);
    d9jlx_ = dfn(inm, 9, jlx) * 1e-3;
    sccbody{irow, 19} = sprintf('%.0f', d9jlx_);

    % === Row 3: 部材長 + 柱脚 応力 ===
    irow = irow + 1;
    lm1_ = lm_nominal(im1);
    sccbody{irow, 1} = sprintf('部材長 %.0f', lm1_);
    sccbody{irow, 10} = '柱脚';
    sccbody{irow, 11} = sprintf('%.0f', lfcx(ic1, 1));
    d11_ = -dfn(inm, 1, 1) * 1e-3;
    sccbody{irow, 12} = sprintf('%.0f', d11_);
    d51_ = -dfn(inm, 5, 1) * 1e-6;
    sccbody{irow, 13} = sprintf('%.0f', d51_);
    d31_ = dfn(inm, 3, 1) * 1e-3;
    sccbody{irow, 14} = sprintf('%.0f', d31_);
    sccbody{irow, 16} = PRM.load_case_combo_name(ilx);
    d1ilx_ = -dfn(inm, 1, ilx) * 1e-3;
    sccbody{irow, 17} = sprintf('%.0f', d1ilx_);
    d5ilx_ = -dfn(inm, 5, ilx) * 1e-6;
    sccbody{irow, 18} = sprintf('%.0f', d5ilx_);
    d3ilx_ = dfn(inm, 3, ilx) * 1e-3;
    sccbody{irow, 19} = sprintf('%.0f', d3ilx_);

    % === Row 4: 方向ヘッダ + <Y>柱頭 応力 ===
    irow = irow + 1;
    sccbody{irow, 2} = '<X>';
    sccbody{irow, 5} = '<Y>';
    sccbody{irow, 10} = '<Y>柱頭';
    sccbody{irow, 11} = sprintf('%.0f', lfcy(ic2, 2));
    d71y_ = -dfn(inm, 7, 1) * 1e-3;
    sccbody{irow, 12} = sprintf('%.0f', d71y_);
    d121_ = dfn(inm, 12, 1) * 1e-6;
    sccbody{irow, 13} = sprintf('%.0f', d121_);
    d81_ = -dfn(inm, 8, 1) * 1e-3;
    sccbody{irow, 14} = sprintf('%.0f', d81_);
    sccbody{irow, 16} = PRM.load_case_combo_name(jly);
    d7jly_ = -dfn(inm, 7, jly) * 1e-3;
    sccbody{irow, 17} = sprintf('%.0f', d7jly_);
    d12jly_ = dfn(inm, 12, jly) * 1e-6;
    sccbody{irow, 18} = sprintf('%.0f', d12jly_);
    d8jly_ = -dfn(inm, 8, jly) * 1e-3;
    sccbody{irow, 19} = sprintf('%.0f', d8jly_);

    % === Row 5: Lk/h + Y柱脚 応力 ===
    irow = irow + 1;
    sccbody{irow, 1} = 'Lk/h';
    sccbody{irow, 2} = sprintf('%.2f', kcx(ic1));
    sccbody{irow, 5} = sprintf('%.2f', kcy(ic1));
    sccbody{irow, 10} = '柱脚';
    sccbody{irow, 11} = sprintf('%.0f', lfcy(ic1, 1));
    d11y_ = -dfn(inm, 1, 1) * 1e-3;
    sccbody{irow, 12} = sprintf('%.0f', d11y_);
    d61_ = -dfn(inm, 6, 1) * 1e-6;
    sccbody{irow, 13} = sprintf('%.0f', d61_);
    d21_ = -dfn(inm, 2, 1) * 1e-3;
    sccbody{irow, 14} = sprintf('%.0f', d21_);
    sccbody{irow, 16} = PRM.load_case_combo_name(ily);
    d1ily_ = -dfn(inm, 1, ily) * 1e-3;
    sccbody{irow, 17} = sprintf('%.0f', d1ily_);
    d6ily_ = -dfn(inm, 6, ily) * 1e-6;
    sccbody{irow, 18} = sprintf('%.0f', d6ily_);
    d2ily_ = -dfn(inm, 2, ily) * 1e-3;
    sccbody{irow, 19} = sprintf('%.0f', d2ily_);

    % === Row 6: Lk + 検定ヘッダ ===
    irow = irow + 1;
    sccbody{irow, 1} = 'Lk';
    sccbody{irow, 2} = sprintf('%.0f', lkx(im1));
    sccbody{irow, 5} = sprintf('%.0f', lky(im1, 1));
    sccbody(irow, 11:20) = {'Z', 'A', 'Aw', 'fb', 'σc/fc', ...
      'σbx/fb', 'σby/fb', 'TOTAL', 'τ/fs', '組合せ'};

    % === Row 7: iy + <X>柱頭 検定 ===
    irow = irow + 1;
    sccbody{irow, 1} = 'iy';
    sccbody{irow, 2} = sprintf('%.2f', iy_(im1) * 1e-1);
    sccbody{irow, 5} = sprintf('%.2f', iz_(im1) * 1e-1);
    total_xj = ration(inm, 7, jlx) + ration(inm, 11, jlx) ...
      + ration(inm, 12, jlx);
    tau_xj = ration(inm, 9, jsx);
    sccbody{irow, 10} = '<X>柱頭';
    sccbody{irow, 11} = sprintf('%.0f', Zy(im2) * 1e-3);
    sccbody{irow, 12} = sprintf('%.1f', A(im2) * 1e-2);
    sccbody{irow, 13} = sprintf('%.1f', Asy(im2) * 1e-2);
    sccbody{irow, 14} = sprintf('%.0f', fbn(inm, 2, jlx));
    r7jlx_ = ration(inm, 7, jlx);
    sccbody{irow, 15} = sprintf('%.2f', r7jlx_);
    r11jlx_ = ration(inm, 11, jlx);
    sccbody{irow, 16} = sprintf('%.2f', r11jlx_);
    r12jlx_ = ration(inm, 12, jlx);
    sccbody{irow, 17} = sprintf('%.2f', r12jlx_);
    sccbody{irow, 18} = sprintf('%.2f', total_xj);
    sccbody{irow, 19} = sprintf('%.2f', tau_xj);
    mxj_ = max(total_xj, tau_xj);
    sccbody{irow, 20} = sprintf('%.2f', mxj_);

    % === Row 8: λ + 柱脚 検定 ===
    irow = irow + 1;
    sccbody{irow, 1} = 'λ';
    sccbody{irow, 2} = sprintf('%.1f', lambday(im1));
    sccbody{irow, 5} = sprintf('%.1f', lambdaz(im1));
    total_xi = ration(inm, 1, ilx) + ration(inm, 5, ilx) ...
      + ration(inm, 6, ilx);
    tau_xi = ration(inm, 9, isx);
    sccbody{irow, 10} = '柱脚';
    sccbody{irow, 11} = sprintf('%.0f', Zy(im1) * 1e-3);
    sccbody{irow, 12} = sprintf('%.1f', A(im1) * 1e-2);
    sccbody{irow, 13} = sprintf('%.1f', Asy(im1) * 1e-2);
    sccbody{irow, 14} = sprintf('%.0f', fbn(inm, 1, ilx));
    r1ilx_ = ration(inm, 1, ilx);
    sccbody{irow, 15} = sprintf('%.2f', r1ilx_);
    r5ilx_ = ration(inm, 5, ilx);
    sccbody{irow, 16} = sprintf('%.2f', r5ilx_);
    r6ilx_ = ration(inm, 6, ilx);
    sccbody{irow, 17} = sprintf('%.2f', r6ilx_);
    sccbody{irow, 18} = sprintf('%.2f', total_xi);
    sccbody{irow, 19} = sprintf('%.2f', tau_xi);
    mxi_ = max(total_xi, tau_xi);
    sccbody{irow, 20} = sprintf('%.2f', mxi_);

    % === Row 9: fcL + <Y>柱頭 検定 ===
    irow = irow + 1;
    fcl_ = fcn(inm, 1, 1);
    sccbody{irow, 2} = sprintf('fcL  %.0f', fcl_);
    total_yj = ration(inm, 7, jly) + ration(inm, 11, jly) ...
      + ration(inm, 12, jly);
    tau_yj = ration(inm, 8, jsy);
    sccbody{irow, 10} = '<Y>柱頭';
    sccbody{irow, 11} = sprintf('%.0f', Zy(im2) * 1e-3);
    sccbody{irow, 12} = sprintf('%.1f', A(im2) * 1e-2);
    sccbody{irow, 13} = sprintf('%.1f', Asz(im2) * 1e-2);
    sccbody{irow, 14} = sprintf('%.0f', fbn(inm, 2, jly));
    r7jly_ = ration(inm, 7, jly);
    sccbody{irow, 15} = sprintf('%.2f', r7jly_);
    r11jly_ = ration(inm, 11, jly);
    sccbody{irow, 16} = sprintf('%.2f', r11jly_);
    r12jly_ = ration(inm, 12, jly);
    sccbody{irow, 17} = sprintf('%.2f', r12jly_);
    sccbody{irow, 18} = sprintf('%.2f', total_yj);
    sccbody{irow, 19} = sprintf('%.2f', tau_yj);
    myj_ = max(total_yj, tau_yj);
    sccbody{irow, 20} = sprintf('%.2f', myj_);

    % === Row 10: fcS + Y柱脚 検定 ===
    irow = irow + 1;
    fcs_ = fcn(inm, 1, 2);
    sccbody{irow, 2} = sprintf('fcS  %.0f', fcs_);
    total_yi = ration(inm, 1, ily) + ration(inm, 5, ily) ...
      + ration(inm, 6, ily);
    tau_yi = ration(inm, 8, isy);
    sccbody{irow, 10} = '柱脚';
    sccbody{irow, 11} = sprintf('%.0f', Zz(im1) * 1e-3);
    sccbody{irow, 12} = sprintf('%.1f', A(im1) * 1e-2);
    sccbody{irow, 13} = sprintf('%.1f', Asy(im1) * 1e-2);
    sccbody{irow, 14} = sprintf('%.0f', fbn(inm, 1, ily));
    r1ily_ = ration(inm, 1, ily);
    sccbody{irow, 15} = sprintf('%.2f', r1ily_);
    r5ily_ = ration(inm, 5, ily);
    sccbody{irow, 16} = sprintf('%.2f', r5ily_);
    r6ily_ = ration(inm, 6, ily);
    sccbody{irow, 17} = sprintf('%.2f', r6ily_);
    sccbody{irow, 18} = sprintf('%.2f', total_yi);
    sccbody{irow, 19} = sprintf('%.2f', tau_yi);
    myi_ = max(total_yi, tau_yi);
    sccbody{irow, 20} = sprintf('%.2f', myi_);

  end
end
sccbody = sccbody(1:irow, :);

return

  function reps = pick_representative(cands)
  %pick_representative - 符号グループごとに代表1部材を選定する
  %
  %   reps = pick_representative(cands) は、候補部材を断面
  %   符号でグルーピングし、各グループから最大検定比を持つ
  %   部材を代表として選定する。
  %
  %   入力引数:
  %     cands - 候補名目柱番号の配列
  %
  %   出力引数:
  %     reps - 代表名目柱番号の配列
    if isempty(cands)
      reps = cands;
      return
    end
    isc_list = idnm2sc(cands);
    [~, ia] = unique(isc_list, 'stable');
    uisc = isc_list(ia);
    reps = zeros(size(uisc));
    for u_ = 1:numel(uisc)
      grp_ = cands(isc_list == uisc(u_));
      [~, best_] = max(max_ratio_all(grp_));
      reps(u_) = grp_(best_);
    end

    return
  end
end
