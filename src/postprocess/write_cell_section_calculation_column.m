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
mb = 18;
ncol = 25;

% 共通配列
column = com.member.column;
nominal_column = com.nominal.column;
secc = com.section.column;
secmgr = com.secmgr;
secdim = result.secdim;
stype = com.section.property.type;
idm2s = com.member.property.idsec;
msdim = secdim(idm2s, :);
mstype = stype(idm2s);
dfn = result.dfn;
fbn = result.fbn;
fcn_display = result.fcnDisplay;
A = result.msprop.A;
Asc = result.msprop.Asc;
Asy = result.msprop.Asy;
Asz = result.msprop.Asz;
Aw = result.msprop.Aw;
Iy = result.msprop.Iy;
Iz = result.msprop.Iz;
Zy = result.msprop.Zy;
Zz = result.msprop.Zz;
F = result.msprop.F;
[Aeff, ~, Asyeff, Aszeff, ~, Zyeff, Zzeff] = ...
  calc_effective_stress_secprop(A, Asc, Asy, Asz, Aw, Zy, Zz, ...
  msdim, mstype, F);
idmaterial = result.msprop.idmaterial;
material_name = result.msprop.material_name;
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
lbc_nominal = result.lbc_nominal;
cri_all = result.cri;
crj_all = result.crj;
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

% 各名目柱の最大検定比（代表部材選定用）
max_ratio_all = max(max(cri, [], 2), max(crj, [], 2));

% ID変換
idnm2sc = column.idsecc(nominal_column.idmec(:, 1));
nmec1_ = nominal_column.idmec(:, 1);
idnm2story = column.idstory(nmec1_, 1);
idnm2x = column.idx(nmec1_, 1);
idnm2y = column.idy(nmec1_, 1);
idnm2z = column.idz(nmec1_, 1);
idnm2mc = nominal_column.idmec;
idnmc2nm = nominal_column.idnominal;
idmc2m = column.idme;

% 判定ランク
has_drank = isfield(result, 'rank') && isfield(result.rank, 'section');

% 出力順序マッピング（出力制御の符号順）
ocl_ = options.output_column_list_label;
secc_order = zeros(nnc, 1);
if ~isempty(ocl_)
  names_ = secc.name(idnm2sc);
  [found_, pos_] = ismember(names_(:), ocl_(:));
  secc_order(found_) = pos_(found_);
  secc_order(~found_) = numel(ocl_) + idnm2sc(~found_);
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
  % SS7 互換: 符号 → Y → X → Z 順
  sort_key_ = [secc_order(cands_), idnm2y(cands_), idnm2x(cands_), ...
    idnm2z(cands_)];
  [~, ord_] = sortrows(sort_key_);
  cands_ = cands_(ord_);
  if ~options.section_calc_all_members
    cands_ = pick_representative(cands_);
  end
  if isempty(cands_)
    continue
  end

  [group_no_, group_count_] = group_by_material_pair(cands_);
  for ig_ = 1:group_count_
    group_cands_ = cands_(group_no_ == ig_);
    write_material_header(group_cands_(1));

    for icand_ = 1:length(group_cands_)
      inc = group_cands_(icand_);
      inm = idnmc2nm(inc);
      warn_axial_bending = false;
      warn_shear = false;
      warn_combined = false;

      % --- 最大ケースの判定 ---
      ilx = pick_max_case(cri, inc, false);
      ily = pick_max_case(cri, inc, true);
      jlx = pick_max_case(crj, inc, false);
      jly = pick_max_case(crj, inc, true);

      % --- 箇所ごとの部材番号 ---
      idsub = nominal_column.idsub(inc, :);
      ic1 = idnm2mc(inc, idsub(1));
      im1 = idmc2m(ic1);
      warn_slenderness = max(lambday(im1), lambdaz(im1)) > 200.0;
      ic2 = idnm2mc(inc, idsub(2));
      im2 = idmc2m(ic2);
      isc_ = idnm2sc(inc);

      % 通し柱判定（nominal_column.isthrough = 入力通し柱由来で
      % 束ねた名目柱。ブレース脚分割は countup で除外済み）
      is_through = nominal_column.isthrough(inc);
      if is_through
        % 中央断面諸量取得元 = 最下サブメンバー
        ic_mid = idnm2mc(inc, 1);
        im_mid = idmc2m(ic_mid);
      end

      % === Row 1: 符号行 + 応力ヘッダ ===
      irow = irow + 1;
      sccbody{irow, 1} = sprintf('[%s]', make_section_symbol(secc, isc_));
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
      sccbody{irow, ncol} = PRM.CONT_MARKER;

      % === Row 2: 断面行 + <X>柱頭 応力 ===
      % 軸力 col index = 1（柱脚軸力で統一）。旧実装は柱頭側 7 を
      % 使っていたが、SS7 S柱断面算定表は最大軸力（柱脚値）を表示
      % する仕様のため、独立柱の自重分の微差は無視して 1 に統一する。
      irow = irow + 1;
      [name_, ~, rk_v] = make_section_label(isc_);
      sccbody{irow, 1} = name_;
      write_stress_row(irow, '<X>柱頭', lfcx(ic2, 2), ...
        stress_spec_top_x, 1, jlx);

      if ~is_through
        % === 独立柱: 応力 4 + 検定ヘッダ + 検定 4 ===

        % 部材長 + 柱脚 X 応力
        irow = irow + 1;
        write_length_label(irow, im1);
        write_stress_row(irow, '柱脚', lfcx(ic1, 1), stress_spec_bot_x, ...
          1, ilx);

        % 方向ヘッダ + <Y>柱頭 応力
        irow = irow + 1;
        write_direction_label(irow);
        write_stress_row(irow, '<Y>柱頭', lfcy(ic2, 2), ...
          stress_spec_top_y, 1, jly);

        % Lk/h + 柱脚 Y 応力
        irow = irow + 1;
        write_lkh_label(irow, ic1);
        write_stress_row(irow, '柱脚', lfcy(ic1, 1), stress_spec_bot_y, ...
          1, ily);

        % Lk + 検定ヘッダ
        irow = irow + 1;
        write_lk_label(irow, im1);
        write_check_header(irow);

        % iy + <X>柱頭 検定
        irow = irow + 1;
        write_iy_label(irow, im1);
        write_check_row(irow, '<X>柱頭', Zyeff(im2), ...
          Aeff(im2), Asyeff(im2), fbn(inm, 2, jlx), ...
          ration(inm, 1, jlx), ration(inm, 11, jlx), ...
          ration(inm, 12, jlx), ration(inm, 9, jlx), ration(inm, 17, jlx));

        % λ + 柱脚 X 検定
        irow = irow + 1;
        write_lambda_label(irow, im1);
        write_check_row(irow, '柱脚', Zyeff(im1), Aeff(im1), ...
          Asyeff(im1), fbn(inm, 1, ilx), ration(inm, 1, ilx), ...
          ration(inm, 5, ilx), ration(inm, 6, ilx), ...
          ration(inm, 9, ilx), ration(inm, 15, ilx));

        % fcL + <Y>柱頭 検定
        irow = irow + 1;
        write_fcl_label(irow);
        write_check_row(irow, '<Y>柱頭', Zyeff(im2), ...
          Aeff(im2), Aszeff(im2), fbn(inm, 2, jly), ...
          ration(inm, 1, jly), ration(inm, 11, jly), ...
          ration(inm, 12, jly), ration(inm, 8, jly), ration(inm, 18, jly));

        % fcS + 柱脚 Y 検定（柱エントリ末尾、CONT_MARKER は付与しない）
        irow = irow + 1;
        write_fcs_label(irow);
        write_check_row(irow, '柱脚', Zzeff(im1), Aeff(im1), ...
          Asyeff(im1), fbn(inm, 1, ily), ration(inm, 1, ily), ...
          ration(inm, 5, ily), ration(inm, 6, ily), ...
          ration(inm, 8, ily), ration(inm, 16, ily));
        sccbody{irow, ncol} = '';

      else
        % === 通し柱: 応力 4 + 中央 2 + 検定ヘッダ + 検定 4 + 中央 2 ===
        %   col 1-7 のラベル列は SS7 互換に row 2-10 に詰める。
        %   中央行 (row 3,6,10,13) の応力/検定値は解析層が未計算で、
        %   断面諸量 (Zy/Zz, A) のみを SS7 マニュアル準拠で出力する。
        %   col 7 の補剛数/Lb1/Lb2 は LTB 用 ℓb として
        %   λ最大方向に直交する梁の補剛を出力する。

        % λx ≷ λy で対の方向の lbc_nominal を選択
        % λx > λy → y方向梁の補剛、λy > λx → x方向梁の補剛
        if lambday(im1) > lambdaz(im1)
          lbc_sel = lbc_nominal.y;
        else
          lbc_sel = lbc_nominal.x;
        end
        lbc_count = lbc_sel.count(inc);
        lbc_is = lbc_sel.is(inc);
        lbc_ie = lbc_sel.ie(inc);

        % 部材長 + 中央 X 応力（値は未出力）
        irow = irow + 1;
        write_length_label(irow, im1);
        sccbody{irow, 10} = '中央';
        sccbody{irow, ncol} = PRM.CONT_MARKER;

        % 方向ヘッダ + 補剛数 + 柱脚 X 応力
        irow = irow + 1;
        write_direction_label(irow);
        if lbc_count > 1
          sccbody{irow, 7} = sprintf('補剛数 %d', lbc_count - 1);
        end
        write_stress_row(irow, '柱脚', lfcx(ic1, 1), stress_spec_bot_x, ...
          1, ilx);

        % Lk/h + Lb2 + <Y>柱頭 応力
        irow = irow + 1;
        write_lkh_label(irow, ic1);
        if lbc_count > 1
          sccbody{irow, 7} = sprintf('Lb2 %.0f', lbc_ie);
        end
        write_stress_row(irow, '<Y>柱頭', lfcy(ic2, 2), ...
          stress_spec_top_y, 1, jly);

        % Lk + Lb1 + 中央 Y 応力（値は未出力）
        irow = irow + 1;
        write_lk_label(irow, im1);
        if lbc_count > 1
          sccbody{irow, 7} = sprintf('Lb1 %.0f', lbc_is);
        end
        sccbody{irow, 10} = '中央';
        sccbody{irow, ncol} = PRM.CONT_MARKER;

        % iy + 柱脚 Y 応力
        irow = irow + 1;
        write_iy_label(irow, im1);
        write_stress_row(irow, '柱脚', lfcy(ic1, 1), stress_spec_bot_y, ...
          1, ily);

        % λ + 検定ヘッダ
        irow = irow + 1;
        write_lambda_label(irow, im1);
        write_check_header(irow);

        % fcL + <X>柱頭 検定
        irow = irow + 1;
        write_fcl_label(irow);
        write_check_row(irow, '<X>柱頭', Zyeff(im2), ...
          Aeff(im2), Asyeff(im2), fbn(inm, 2, jlx), ...
          ration(inm, 1, jlx), ration(inm, 11, jlx), ...
          ration(inm, 12, jlx), ration(inm, 9, jlx), ration(inm, 17, jlx));

        % fcS + 中央 X 検定（Zy/A のみ）
        irow = irow + 1;
        write_fcs_label(irow);
        sccbody{irow, 10} = '中央';
        sccbody{irow, 11} = fmt_ceil_abs(Zyeff(im_mid) * 1e-3, 0);
        sccbody{irow, 12} = fmt_ceil_abs(Aeff(im_mid) * 1e-2, 1);
        sccbody{irow, ncol} = PRM.CONT_MARKER;

        % 柱脚 X 検定
        irow = irow + 1;
        write_check_row(irow, '柱脚', Zyeff(im1), Aeff(im1), ...
          Asyeff(im1), fbn(inm, 1, ilx), ration(inm, 1, ilx), ...
          ration(inm, 5, ilx), ration(inm, 6, ilx), ...
          ration(inm, 9, ilx), ration(inm, 15, ilx));

        % <Y>柱頭 検定
        irow = irow + 1;
        write_check_row(irow, '<Y>柱頭', Zyeff(im2), ...
          Aeff(im2), Aszeff(im2), fbn(inm, 2, jly), ...
          ration(inm, 1, jly), ration(inm, 11, jly), ...
          ration(inm, 12, jly), ration(inm, 8, jly), ration(inm, 18, jly));

        % 中央 Y 検定（Zz/A のみ）
        irow = irow + 1;
        sccbody{irow, 10} = '中央';
        sccbody{irow, 11} = fmt_ceil_abs(Zzeff(im_mid) * 1e-3, 0);
        sccbody{irow, 12} = fmt_ceil_abs(Aeff(im_mid) * 1e-2, 1);
        sccbody{irow, ncol} = PRM.CONT_MARKER;

        % 柱脚 Y 検定（柱エントリ末尾、CONT_MARKER は付与しない）
        irow = irow + 1;
        write_check_row(irow, '柱脚', Zzeff(im1), Aeff(im1), ...
          Asyeff(im1), fbn(inm, 1, ily), ration(inm, 1, ily), ...
          ration(inm, 5, ily), ration(inm, 6, ily), ...
          ration(inm, 8, ily), ration(inm, 16, ily));
        sccbody{irow, ncol} = '';
      end

      % SS7 互換の警告行を柱エントリ末尾に出力する
      if warn_axial_bending
        append_warning_row(['警告  692： S柱で軸力と' ...
          '曲げモーメントによる応力度が許容応力度を' ...
          '超えています。']);
      end
      if warn_shear
        append_warning_row(['警告  693： S柱でせん断応力度が' ...
          '許容せん断応力度を超えています。']);
      end
      if warn_combined
        append_warning_row(['警告  694： S柱で組合せ応力度が' ...
          '許容応力度を超えています。']);
      end
      if warn_slenderness
        append_warning_row(['警告  697： S柱で細長比が' ...
          '200を超えています。']);
      end

      % FD ランク = S 規準幅厚比超過。SS7 互換の注意を末尾に出力する
      if has_drank && rk_v == PRM.COLUMN_RANK_FD
        append_warning_row(['　　　注意  695： S柱で幅厚比がS規準の' ...
          '制限値を超えています。']);
      end

    end
  end
end
sccbody = sccbody(1:irow, :);

return

  function write_stress_row(irow_, label, lf_val, spec_, lc1, lc2)
  %write_stress_row - 応力行 1 行を埋める（col 10-19, 25）
  %
  %   write_stress_row(irow_, label, lf_val, spec_, lc1, lc2) は、
  %   S柱断面算定表の応力行 1 行に長期/組合せ時の N, M, Q を
  %   埋める。spec_ は stress_spec_* 関数が返す成分仕様。
  %   外側スコープの dfn, inm, sccbody, ncol を共有する。
  %
  %   入力引数:
  %     irow_  - 書き込み行番号
  %     label  - 位置ラベル（'<X>柱頭' 等）
  %     lf_val - 梁フェイス長 [mm]（lf.columnx/y の柱頭または柱脚値）
  %     spec_  - 応力成分仕様（n_idx/m_idx/q_idx/sign_n/sign_m/sign_q）
  %     lc1    - 長期側荷重ケース番号
  %     lc2    - 組合せ側荷重ケース番号
  %
  %   備考:
  %     col 10:ラベル / 11:フェイス長 / 12-14:設計時力 (N/M/Q) /
  %     16:ケース名 / 17-19:組合せ時力 / 25:CONT_MARKER
    ni = spec_.n_idx;
    mi = spec_.m_idx;
    qi = spec_.q_idx;
    sn = spec_.sign_n;
    sm = spec_.sign_m;
    sq = spec_.sign_q;
    sccbody{irow_, 10} = label;
    sccbody{irow_, 11} = sprintf('%.0f', lf_val);
    sccbody{irow_, 12} = fmt_ceil_abs(sn * dfn(inm, ni, lc1) * 1e-3, 0);
    sccbody{irow_, 13} = fmt_ceil_abs(sm * dfn(inm, mi, lc1) * 1e-6, 0);
    sccbody{irow_, 14} = fmt_ceil_abs(sq * dfn(inm, qi, lc1) * 1e-3, 0);
    sccbody{irow_, 16} = PRM.load_case_combo_name(lc2);
    sccbody{irow_, 17} = fmt_ceil_abs(sn * dfn(inm, ni, lc2) * 1e-3, 0);
    sccbody{irow_, 18} = fmt_ceil_abs(sm * dfn(inm, mi, lc2) * 1e-6, 0);
    sccbody{irow_, 19} = fmt_ceil_abs(sq * dfn(inm, qi, lc2) * 1e-3, 0);
    sccbody{irow_, ncol} = PRM.CONT_MARKER;
    return
  end

  function write_check_row(irow_, label, Z_val, A_val, Aw_val, ...
    fb_val, r_n, r_bx, r_by, tau, combined)
  %write_check_row - 検定行 1 行を埋める（col 10-20, 25）
  %
  %   write_check_row(irow_, label, Z_val, A_val, Aw_val,
  %     fb_val, r_n, r_bx, r_by, tau, combined) は、S柱断面
  %   算定表の検定行 1 行に断面諸量と各応力比・合算値を埋める。
  %   検定比は SS7 互換で切り上げ（ceil）表示する。外側スコープの
  %   sccbody, ncol を共有する。
  %
  %   入力引数:
  %     irow_  - 書き込み行番号
  %     label  - 位置ラベル（'<X>柱頭' 等）
  %     Z_val  - 断面係数 Z [mm3]
  %     A_val  - 断面積 A [mm2]
  %     Aw_val - せん断有効断面積 Aw [mm2]
  %     fb_val - 許容曲げ応力度 fb [N/mm2]
  %     r_n    - 軸応力比 σc/fc
  %     r_bx   - 曲げ応力比 σbx/fb
  %     r_by   - 曲げ応力比 σby/fb
  %     tau    - せん断応力比 τ/fs
  %     combined - 組合せ応力比 sqrt(σ^2+3τ^2)/ft（分析層算定値）
  %
  %   備考:
  %     col 10:ラベル / 11:Z / 12:A / 13:Aw / 14:fb /
  %     15:σc/fc / 16:σbx/fb / 17:σby/fb / 18:TOTAL / 19:τ/fs /
  %     20:組合せ / 25:CONT_MARKER
    total = r_n + r_bx + r_by;
    warn_axial_bending = warn_axial_bending || total > 1.0;
    warn_shear = warn_shear || tau > 1.0;
    warn_combined = warn_combined || combined > 1.0;
    % 検定比は SS7 互換で小数2桁切り上げ表示(丸め規則を一元化)
    fmt2 = @(r) fmt_ratio(r, true);
    sccbody{irow_, 10} = label;
    sccbody{irow_, 11} = fmt_ceil_abs(Z_val * 1e-3, 0);
    sccbody{irow_, 12} = fmt_ceil_abs(A_val * 1e-2, 1);
    sccbody{irow_, 13} = fmt_ceil_abs(Aw_val * 1e-2, 1);
    sccbody{irow_, 14} = sprintf('%.0f', fb_val);
    sccbody{irow_, 15} = fmt2(r_n);
    sccbody{irow_, 16} = fmt2(r_bx);
    sccbody{irow_, 17} = fmt2(r_by);
    sccbody{irow_, 18} = fmt2(total);
    sccbody{irow_, 19} = fmt2(tau);
    sccbody{irow_, 20} = fmt2(combined);
    sccbody{irow_, ncol} = PRM.CONT_MARKER;
    return
  end

  function append_warning_row(message)
  %append_warning_row - 現在の柱エントリ末尾に警告・注意行を追加する
    sccbody{irow, ncol} = PRM.CONT_MARKER;
    irow = irow + 1;
    sccbody{irow, 1} = message;
    return
  end

  function write_check_header(irow_)
  %write_check_header - 検定行のカラムヘッダを書き込む（col 11-20）
  %
  %   write_check_header(irow_) は、S柱断面算定表の検定行群の
  %   直前に置くカラムヘッダ（Z/A/Aw/fb/σc/fc/σbx/fb/σby/fb/
  %   TOTAL/τ/fs/組合せ）を書き込む。外側スコープの sccbody,
  %   ncol を共有する。
  %
  %   入力引数:
  %     irow_ - 書き込み行番号
    sccbody(irow_, 11:20) = {'Z', 'A', 'Aw', 'fb', 'σc/fc', ...
      'σbx/fb', 'σby/fb', 'TOTAL', 'τ/fs', '組合せ'};
    sccbody{irow_, ncol} = PRM.CONT_MARKER;
    return
  end

  function reps = pick_representative(cands)
  %pick_representative - 符号・材料IDペアごとに代表を選定する
  %
  %   reps = pick_representative(cands) は、候補部材を断面符号、
  %   柱頭材料ID、柱脚材料IDの組でグルーピングし、各グループから
  %   最大検定比を持つ部材を代表として選定する。
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
    cands_row_ = cands(:)';
    key_ = [idnm2sc(cands_row_(:)), get_material_pairs(cands_row_)];
    used_ = false(numel(cands_row_), 1);
    reps = zeros(1, 0);
    for ikey_ = 1:numel(cands_row_)
      if used_(ikey_)
        continue
      end
      mask_ = all(key_ == key_(ikey_, :), 2);
      grp_ = cands_row_(mask_');
      [~, best_] = max(max_ratio_all(grp_));
      reps(end + 1) = grp_(best_); %#ok<AGROW>
      used_(mask_) = true;
    end

    return
  end

  function [group_no, group_count] = group_by_material_pair(cands)
  %group_by_material_pair - 候補柱を柱頭・柱脚材料IDペアで束ねる
  %
  %   [group_no, group_count] = group_by_material_pair(cands) は、
  %   候補柱配列の順序を保ったまま、同じ柱頭・柱脚材料IDを持つ
  %   柱を同一グループに割り当てる。
  %
  %   入力引数:
  %     cands - 候補名目柱番号の配列
  %
  %   出力引数:
  %     group_no    - 各候補の材料グループ番号
  %     group_count - 材料グループ数
    pairs_ = get_material_pairs(cands);
    group_pairs_ = zeros(numel(cands), 2);
    group_no = zeros(size(cands));
    group_count = 0;
    for igcand_ = 1:numel(cands)
      if group_count == 0
        hit_ = [];
      else
        hit_ = find(all(group_pairs_(1:group_count, :) ...
          == pairs_(igcand_, :), 2), 1);
      end
      if isempty(hit_)
        group_count = group_count + 1;
        group_pairs_(group_count, :) = pairs_(igcand_, :);
        hit_ = group_count;
      end
      group_no(igcand_) = hit_;
    end

    return
  end

  function pairs = get_material_pairs(cands)
  %get_material_pairs - 候補柱の柱頭・柱脚材料IDペアを返す
  %
  %   pairs = get_material_pairs(cands) は、候補名目柱番号ごとに
  %   [柱頭材料ID, 柱脚材料ID] の行列を返す。
  %
  %   入力引数:
  %     cands - 候補名目柱番号の配列
  %
  %   出力引数:
  %     pairs - 柱頭・柱脚材料IDペア [numel(cands)×2]
    pairs = zeros(numel(cands), 2);
    for ipair_ = 1:numel(cands)
      [idmat_top_, idmat_bot_] = get_material_pair(cands(ipair_));
      pairs(ipair_, :) = [idmat_top_, idmat_bot_];
    end

    return
  end

  function [idmat_top, idmat_bot, im_top, im_bot] = get_material_pair(inc_)
  %get_material_pair - 名目柱の柱頭・柱脚材料IDを返す
  %
  %   [idmat_top, idmat_bot, im_top, im_bot] = get_material_pair(inc_)
  %   は、名目柱 inc_ の柱頭・柱脚部材に対応する材料IDと部材番号を
  %   返す。
  %
  %   入力引数:
  %     inc_ - 名目柱番号
  %
  %   出力引数:
  %     idmat_top - 柱頭材料ID
  %     idmat_bot - 柱脚材料ID
  %     im_top    - 柱頭部材番号
  %     im_bot    - 柱脚部材番号
    idsub_ = nominal_column.idsub(inc_, :);
    ic_bot_ = idnm2mc(inc_, idsub_(1));
    im_bot = idmc2m(ic_bot_);
    ic_top_ = idnm2mc(inc_, idsub_(2));
    im_top = idmc2m(ic_top_);
    idmat_top = idmaterial(im_top);
    idmat_bot = idmaterial(im_bot);

    return
  end

  function write_material_header(inc_)
  %write_material_header - 材料IDペアに対応する鉄骨ヘッダを出力する
  %
  %   write_material_header(inc_) は、名目柱 inc_ の柱頭・柱脚材料名と
  %   F値を用いて、S柱断面算定表の鉄骨ヘッダ3行を出力する。
  %
  %   入力引数:
  %     inc_ - 材料グループの代表名目柱番号
    [~, ~, im_top_, im_bot_] = get_material_pair(inc_);
    mat_top_ = material_name{im_top_};
    mat_bot_ = material_name{im_bot_};
    F_top_ = F(im_top_);
    F_bot_ = F(im_bot_);
    irow = irow + 1;
    material_header_ = ['鉄　骨   　   柱頭　     Ｆ値　 　 ', ...
      '柱脚　     Ｆ値'];
    sccbody{irow, 1} = material_header_;
    sccbody{irow, ncol} = PRM.CONT_MARKER;
    irow = irow + 1;
    sccbody{irow, 1} = sprintf('[ %-9s]  %.1f  [ %-9s]  %.1f', ...
      mat_top_, F_top_, mat_bot_, F_bot_);
    sccbody{irow, ncol} = PRM.CONT_MARKER;
    irow = irow + 1; % 空行（全フィールド空のため CSV 上も空行）

    return
  end

  function ilc = pick_max_case(table_, inc_, is_y)
  %pick_max_case - 最大検定比ケース番号を返す（Y は +2 補正込み）
  %
  %   ilc = pick_max_case(table_, inc_, is_y) は、cri/crj
  %   テーブルから X 方向（[1 2 3] 列）または Y 方向（[1 4 5] 列）
  %   の最大検定比ケース番号を返す。eps による同値解消と、
  %   Y 方向ケース番号の +2 補正を内部で行う。
  %
  %   入力引数:
  %     table_ - cri/crj のいずれか [nnc×nlc]
  %     inc_   - 名目柱番号
  %     is_y   - true で Y 方向、false で X 方向
  %
  %   出力引数:
  %     ilc - 最大検定比ケース番号（X: 1-3, Y: 1, 4, 5）
    if is_y
      vals_ = table_(inc_, [1 4 5]) + [eps eps 0];
    else
      vals_ = table_(inc_, [1 2 3]) + [eps eps 0];
    end
    [~, ilc] = max(vals_);
    if is_y && ilc > 1
      ilc = ilc + 2;
    end
    return
  end

  function [name_, rank_str, rank_v] = make_section_label(isc_)
  %make_section_label - 断面名と判定ランクラベル/値を返す
  %
  %   [name_, rank_str, rank_v] = make_section_label(isc_) は、
  %   柱断面番号 isc_ に対応する断面表示文字列と、判定ランクの
  %   表示用文字列および数値を返す。判定ランクが未設定の場合、
  %   rank_v=0, rank_str='' を返す。外側スコープの idsecc2sec,
  %   stype, secdim, secmgr, has_drank, result を共有する。
  %
  %   入力引数:
  %     isc_ - 柱断面番号
  %
  %   出力引数:
  %     name_     - 断面表示文字列（'<断面名> [<ランク>]' 形式）
  %     rank_str  - 判定ランク文字列（'FA' 等。無ければ空）
  %     rank_v    - 判定ランク数値（無ければ 0）
    is2_ = idsecc2sec(isc_);
    stype_ = stype(is2_);
    dim_ = secdim(is2_, :);
    idsl_ = secdim(is2_, 6);
    idsec_ = secdim(is2_, 7);
    sl_ = secmgr.secList.list{idsl_};
    sym_ = sl_.symbol{idsec_};
    secname_ = format_steel_cost_dim(stype_, dim_, sym_);
    if has_drank
      rank_v = result.rank.section(is2_);
      if rank_v >= 1 && rank_v <= numel(PRM.MEMBER_RANK_NAME)
        rank_str = PRM.MEMBER_RANK_NAME{rank_v};
      else
        rank_str = '';
      end
    else
      rank_v = 0;
      rank_str = '';
    end
    name_ = sprintf('%s [%s]', secname_, rank_str);
    return
  end

  function write_length_label(irow_, im_)
  %write_length_label - 部材長ラベルを col 1 に書き込む
  %
  %   write_length_label(irow_, im_) は、部材番号 im_ の部材長
  %   lm_nominal(im_) を col 1 に '部材長 <値>' として書き込む。
  %   外側スコープの sccbody, lm_nominal を共有する。
  %
  %   入力引数:
  %     irow_ - 書き込み行番号
  %     im_   - 部材番号
    sccbody{irow_, 1} = sprintf('部材長 %.0f', lm_nominal(im_));
    return
  end

  function write_direction_label(irow_)
  %write_direction_label - 方向ヘッダ <X>/<Y> を col 2, 5 に書く
  %
  %   write_direction_label(irow_) は、断面算定表の方向ヘッダ
  %   '<X>' を col 2 に、'<Y>' を col 5 に書き込む。
  %   外側スコープの sccbody を共有する。
  %
  %   入力引数:
  %     irow_ - 書き込み行番号
    sccbody{irow_, 2} = '<X>';
    sccbody{irow_, 5} = '<Y>';
    return
  end

  function write_lkh_label(irow_, ic_)
  %write_lkh_label - Lk/h ラベルと値を col 1, 2, 5 に書き込む
  %
  %   write_lkh_label(irow_, ic_) は、柱部材番号 ic_ の座屈長係数
  %   kcx/kcy を col 1 に 'Lk/h' ラベル、col 2/5 に値として書き込む。
  %   外側スコープの sccbody, kcx, kcy を共有する。
  %
  %   入力引数:
  %     irow_ - 書き込み行番号
  %     ic_   - 柱部材番号
    sccbody{irow_, 1} = 'Lk/h';
    sccbody{irow_, 2} = fmt_ceil_abs(kcx(ic_), 2);
    sccbody{irow_, 5} = fmt_ceil_abs(kcy(ic_), 2);
    return
  end

  function write_lk_label(irow_, im_)
  %write_lk_label - Lk ラベルと値を col 1, 2, 5 に書き込む
  %
  %   write_lk_label(irow_, im_) は、部材番号 im_ の座屈長 lkx/lky
  %   を col 1 に 'Lk' ラベル、col 2/5 に値として書き込む。
  %   外側スコープの sccbody, lkx, lky を共有する。
  %
  %   入力引数:
  %     irow_ - 書き込み行番号
  %     im_   - 部材番号
    sccbody{irow_, 1} = 'Lk';
    sccbody{irow_, 2} = fmt_ceil_abs(lkx(im_), 0);
    sccbody{irow_, 5} = fmt_ceil_abs(lky(im_, 1), 0);
    return
  end

  function write_iy_label(irow_, im_)
  %write_iy_label - 断面 2 次半径 iy/iz を col 1, 2, 5 に書き込む
  %
  %   write_iy_label(irow_, im_) は、部材番号 im_ の断面 2 次半径
  %   iy_/iz_ を [cm] 単位で col 1 に 'iy' ラベル、col 2/5 に値
  %   として書き込む。外側スコープの sccbody, iy_, iz_ を共有する。
  %
  %   入力引数:
  %     irow_ - 書き込み行番号
  %     im_   - 部材番号
    sccbody{irow_, 1} = 'iy';
    sccbody{irow_, 2} = sprintf('%.2f', iy_(im_) * 1e-1);
    sccbody{irow_, 5} = sprintf('%.2f', iz_(im_) * 1e-1);
    return
  end

  function write_lambda_label(irow_, im_)
  %write_lambda_label - 細長比 λ を col 1, 2, 5 に書き込む
  %
  %   write_lambda_label(irow_, im_) は、部材番号 im_ の細長比
  %   lambday/lambdaz を col 1 に 'λ' ラベル、col 2/5 に値として
  %   書き込む。外側スコープの sccbody, lambday, lambdaz を共有する。
  %
  %   入力引数:
  %     irow_ - 書き込み行番号
  %     im_   - 部材番号
    sccbody{irow_, 1} = 'λ';
    sccbody{irow_, 2} = fmt_ceil_abs(lambday(im_), 1);
    sccbody{irow_, 5} = fmt_ceil_abs(lambdaz(im_), 1);
    return
  end

  function write_fcl_label(irow_)
  %write_fcl_label - 長期側許容圧縮応力度 fcL ラベルを col 2 に書く
  %
  %   write_fcl_label(irow_) は、長期側許容圧縮応力度
  %   fcn_display(inm, 1, 1) を col 2 に 'fcL <値>' として書き込む。
  %   引張置換前の fc を表示する（SS7出力編7.3.11）。
  %   外側スコープの sccbody, fcn_display, inm を共有する。
  %
  %   入力引数:
  %     irow_ - 書き込み行番号
    fcl_ = ceil_abs(fcn_display(inm, 1, 1), 0);
    sccbody{irow_, 2} = sprintf('fcL  %.0f', fcl_);
    return
  end

  function write_fcs_label(irow_)
  %write_fcs_label - 短期側許容圧縮応力度 fcS ラベルを col 2 に書く
  %
  %   write_fcs_label(irow_) は、短期側許容圧縮応力度
  %   fcn_display(inm, 1, 2) を col 2 に 'fcS <値>' として書き込む。
  %   引張置換前の fc を表示する（SS7出力編7.3.11）。
  %   外側スコープの sccbody, fcn_display, inm を共有する。
  %
  %   入力引数:
  %     irow_ - 書き込み行番号
    fcs_ = ceil_abs(fcn_display(inm, 1, 2), 0);
    sccbody{irow_, 2} = sprintf('fcS  %.0f', fcs_);
    return
  end

  function s = stress_spec_top_x
  %stress_spec_top_x - <X>柱頭の応力成分仕様
  %
  %   s = stress_spec_top_x は、<X>柱頭の応力行に書き出す N/M/Q の
  %   成分インデックスと符号を struct で返す。write_stress_row の
  %   spec_ 引数として使う。
  %
  %   出力引数:
  %     s - 応力成分仕様 struct（n_idx/m_idx/q_idx/sign_n/sign_m/sign_q）
    s = struct('n_idx', 1, 'm_idx', 11, 'q_idx', 9, ...
      'sign_n', -1, 'sign_m', +1, 'sign_q', +1);
    return
  end

  function s = stress_spec_bot_x
  %stress_spec_bot_x - 柱脚 X 応力行の成分仕様
  %
  %   s = stress_spec_bot_x は、柱脚 X 方向の応力行に書き出す N/M/Q
  %   の成分インデックスと符号を struct で返す。write_stress_row の
  %   spec_ 引数として使う。
  %
  %   出力引数:
  %     s - 応力成分仕様 struct（n_idx/m_idx/q_idx/sign_n/sign_m/sign_q）
    s = struct('n_idx', 1, 'm_idx', 5, 'q_idx', 3, 'sign_n', -1, ...
      'sign_m', -1, 'sign_q', +1);
    return
  end

  function s = stress_spec_top_y
  %stress_spec_top_y - <Y>柱頭の応力成分仕様
  %
  %   s = stress_spec_top_y は、<Y>柱頭の応力行に書き出す N/M/Q の
  %   成分インデックスと符号を struct で返す。write_stress_row の
  %   spec_ 引数として使う。
  %
  %   出力引数:
  %     s - 応力成分仕様 struct（n_idx/m_idx/q_idx/sign_n/sign_m/sign_q）
    s = struct('n_idx', 1, 'm_idx', 12, 'q_idx', 8, ...
      'sign_n', -1, 'sign_m', +1, 'sign_q', -1);
    return
  end

  function s = stress_spec_bot_y
  %stress_spec_bot_y - 柱脚 Y 応力行の成分仕様
  %
  %   s = stress_spec_bot_y は、柱脚 Y 方向の応力行に書き出す N/M/Q
  %   の成分インデックスと符号を struct で返す。write_stress_row の
  %   spec_ 引数として使う。
  %
  %   出力引数:
  %     s - 応力成分仕様 struct（n_idx/m_idx/q_idx/sign_n/sign_m/sign_q）
    s = struct('n_idx', 1, 'm_idx', 6, 'q_idx', 2, 'sign_n', -1, ...
      'sign_m', -1, 'sign_q', -1);
    return
  end
end

