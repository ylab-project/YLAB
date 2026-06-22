function scgbody = write_cell_section_calculation_girder( ...
  com, result, options)
%write_cell_section_calculation_girder - S梁断面算定表セル配列を生成
%
%   scgbody = write_cell_section_calculation_girder(com, result, options)
%   は、各層の名目梁に対して断面諸量・応力・検定比をまとめた
%   断面算定表のボディ行を出力用セル配列として返す。
%   options.section_calc_all_members=false のときは符号ごとに
%   最大検定比を持つ代表部材のみを出力する。
%
%   入力引数:
%     com     - 共通オブジェクト
%     result  - 解析結果構造体 (secdim, ration, fbn, fcn, nomgc 等)
%     options - 出力オプション構造体
%               section_calc_all_members, consider_web_at_girder_center,
%               consider_web_at_girder_end, output_girder_list_label,
%               section_calc_all_members 等の出力制御
%
%   出力引数:
%     scgbody - 断面算定表のボディ行セル配列 [nrow×16]
%               （15列のデータ + 末尾1列の連結マーカー列）
%
%   備考:
%     - 中央位置は result.nomgc.xc_design(ing) を参照する。
%     - C 補正係数はfbがfb1式で決定したときのみ表示する。

% 定数
nng = com.num.nominal_girder;
nlc = com.nlc;
nstory = com.nstory;
mb = 23;
ncol = 16;

% 共通配列
girder = com.member.girder;
nominal_girder = com.nominal.girder;
secg = com.section.girder;
secmgr = com.secmgr;
secdim = result.secdim;
lm_nominal = result.lm_nominal;
lfg = result.lf.girder;
lb = com.nominal.girder.stiffening_lb;
lbn_nom = result.nomgc.lb;
id_center_sel = result.id_center_sel;
dfn = result.dfn;
fbn = result.fbn;
fbn_by_fb1 = result.fbnByFb1;
fcn = result.fcn;
stn = result.stn;
stcn = result.stcn;
C = result.C;
girder_section_case = result.girderSectionCase;
if options.consider_web_at_girder_center
  Zc = result.msprop.Zy;
else
  Zc = result.msprop.Zyf;
end
if options.consider_web_at_girder_end
  Zij = result.msprop.Zysc;
else
  Zij = result.msprop.Zyf;
end
A = result.msprop.A;
Asc = result.msprop.Asc;
Aw = result.msprop.Aw;
F = result.msprop.F;
slratio = result.slratio;
has_slr = isstruct(slratio);
dangle = result.deflection_angle;
if isempty(dangle)
  dangle = zeros(nng, 1);  % 梁たわみ検討オフ時
end
nstiff_nom = com.nominal.girder.nstiff;
ration = abs(result.ration);
gri_all = result.gri;
grj_all = result.grj;
grc_all = result.grc;
gsi_all = result.gsi;
gsj_all = result.gsj;
idsecg2sec = com.section.girder.idsec;
stype = com.section.property.type;

if isempty(ration)
  scgbody = cell(0, ncol);
  return
end

% 梁許容応力度比
gri = reshape(gri_all, [], nlc) + 1;
grj = reshape(grj_all, [], nlc) + 1;
grc = reshape(grc_all, [], nlc) + 1;
gsi = reshape(gsi_all, [], nlc) + 1;
gsj = reshape(gsj_all, [], nlc) + 1;

% 各名目梁の最大検定比（代表部材選定用）
max_ratio_all = max(max(gri,[],2), max(max(grj,[],2), max(grc,[],2)));

% ID変換
idmeg1_ = nominal_girder.idmeg(:,1);
idnm2stype = girder.section_type(idmeg1_);
idnm2sg = girder.idsecg(idmeg1_);
idnm2dir = girder.idir(idmeg1_, 1);
idnm2story = girder.idstory(idmeg1_, 1);
idnm2x = girder.idx(idmeg1_, 1);
idnm2y = girder.idy(idmeg1_, 1);
idnm2z = girder.idz(idmeg1_, 1);
idnm2mg = nominal_girder.idmeg;
idnmg2nm = nominal_girder.idnominal;
idmg2m = girder.idme;

% 判定ランク
has_drank = isfield(result, 'rank') && isfield(result.rank, 'section');

% 出力順序マッピング（出力制御の符号順）
ogl_ = options.output_girder_list_label;
secg_order = zeros(nng, 1);
if ~isempty(ogl_)
  for ing_ = 1:nng
    name_ = secg.name{idnm2sg(ing_)};
    pos_ = find(matches(ogl_, name_), 1);
    if ~isempty(pos_)
      secg_order(ing_) = pos_;
    else
      secg_order(ing_) = numel(ogl_) + idnm2sg(ing_);
    end
  end
else
  secg_order(:) = idnm2sg;
end

% --- S梁断面算定表 ---
scgbody = cell(mb * nng, ncol);
iggg = 1:nng;
irow = 0;
for i = 1:nstory
  ist = nstory - i + 1;
  prev_mat_key = '';
  for idir = 1:2
    mask_ = idnm2story == ist & idnm2dir == idir ...
      & idnm2stype == PRM.WFS & nominal_girder.is_allowable_stress;
    cands_ = iggg(mask_);
    % SS7 互換: X方向梁はY通り優先、Y方向梁はX通り優先
    if idir == PRM.X
      sort_key_ = [secg_order(cands_), idnm2y(cands_), ...
        idnm2x(cands_), idnm2z(cands_)];
    else
      sort_key_ = [secg_order(cands_), idnm2x(cands_), ...
        idnm2y(cands_), idnm2z(cands_)];
    end
    [~, ord_] = sortrows(sort_key_);
    cands_ = cands_(ord_);
    if ~options.section_calc_all_members
      cands_ = pick_representative(cands_);
    end
    for k_ = 1:length(cands_)
      ing = cands_(k_);
      inm = idnmg2nm(ing);

      isg = idnm2sg(ing);
      ilc = girder_section_case.ilc(ing);
      clc = girder_section_case.clc(ing);
      jlc = girder_section_case.jlc(ing);

      % 箇所ごとの部材番号
      idsub = nominal_girder.idsub(ing, :);
      idsub_nomgc = result.nomgc.idsub(ing, :);
      ig1 = idnm2mg(ing, idsub(1));
      im1 = idmg2m(ig1);
      ig2 = idnm2mg(ing, idsub(2));
      im2 = idmg2m(ig2);
      igc = idnm2mg(ing, idsub_nomgc(3));
      imc = idmg2m(igc);

      has_axial = result.girderSectionHasAxial(ing);

      % 梁エントリの開始行を記録（最終行以外は CONT_MARKER で連結し、
      % SS7 と同じ単一論理行ブロックとして cmp7 で照合できるようにする）
      irow_block_start = irow + 1;

      % --- 鉄骨ヘッダ行 ---
      is_ = idsecg2sec(isg);
      idsl_ = secdim(is_, 6);
      mat_ = secmgr.secList.material_name{idsl_,1};
      F_ = F(im1);
      hkey_ = sprintf('%s_%.0f', mat_, F_);
      if ~strcmp(hkey_, prev_mat_key)
        irow = irow + 1;
        fmt_ = ['鉄骨： 左端  [ %-9s] Ｆ値 %.1f  中央' ...
          '  [ %-9s] Ｆ値 %.1f  右端  [ %-9s] Ｆ値 %.1f'];
        scgbody{irow,1} = sprintf(fmt_, mat_, F_, mat_, F_, mat_, F_);
        irow = irow + 1; % 空行
        prev_mat_key = hkey_;
      end

      % --- 符号行 ---
      ns_ = max(nstiff_nom(ing) - 1, 0);
      lm_ = lm_nominal(im1);
      % 内法スパン (柱面間)。dangle は内法基準で計算されているため
      % たわみδの絶対値も内法スパンを掛けて算出する（SS7仕様）
      lgn_ = lm_ - lfg(ig1, 1) - lfg(ig2, 2);
      da_ = dangle(ing);
      delta_ = abs(da_) * lgn_;
      if da_ ~= 0
        dL_ = min(round(1/abs(da_)), 99999);
      else
        dL_ = 99999;
      end
      irow = irow + 1;
      scgbody{irow,1} = sprintf('[ %s ]', make_section_symbol(secg, isg));
      scgbody{irow,2} = sprintf('[%s', girder.story_name{ig1});
      scgbody{irow,3} = girder.frame_name{ig1};
      scgbody{irow,4} = girder.coord_name{ig1, 1};
      scgbody{irow,5} = '-';
      scgbody{irow,6} = sprintf('%s]', girder.coord_name{ig2, 2});
      scgbody{irow,7} = sprintf('部材長 %.0f', lm_);
      scgbody{irow,9} = sprintf('たわみδ  %.3f δ/L 1/%.0f', delta_, dL_);
      scgbody{irow,13} = sprintf('補剛数 %d', ns_);
      if ns_ > 0 && has_slr
        maxLb_ = slratio.lbmax(ig1);
        scgbody{irow,15} = sprintf('最大Lb %.0f', maxLb_);
      end

      % --- 断面行 ---
      idsection_ = secdim(is_, 7);
      sl_ = secmgr.secList.list{idsl_};
      sym_ = sl_.symbol{idsection_};
      stype_ = stype(is_);
      dim_ = secdim(is_, :);
      secname_ = format_steel_cost_dim(stype_, dim_, sym_);
      if has_drank
        is_r = idsecg2sec(isg);
        rk_v = result.rank.section(is_r);
        if rk_v >= 1 && rk_v <= numel(PRM.MEMBER_RANK_NAME)
          rk_s = PRM.MEMBER_RANK_NAME{rk_v};
        else
          rk_s = '';
        end
      else
        rk_s = '';
      end
      irow = irow + 1;
      scgbody{irow,1} = sprintf('%s [%s]', secname_, rk_s);
      if ns_ > 0
        scgbody{irow, 7} = 'Lb1';
        scgbody{irow, 8} = 'Lb2';
        scgbody{irow, 9} = 'Lb3';
        scgbody{irow,10} = 'Lb4';
      end
      scgbody{irow,11} = '均等';
      if has_slr
        nreq_ = abs(slratio.nreq(ig1));
        lam_ = slratio.lambda(ig1);
        is_ok_equal_ = slratio.isOkEqual(ig1);
        is_ok_end_ = slratio.isOkEnd(ig1);
        is_ok_slr_ = slratio.isOk(ig1);
      else
        nreq_ = 0;
        Iz_ = result.msprop.Iz(im1);
        iy_ = sqrt(Iz_ / A(im1));
        lam_ = lm_ / iy_;
        is_ok_equal_ = true;
        is_ok_end_ = true;
        is_ok_slr_ = true;
      end
      % 等間隔配置の限界Lbを最大Lbが超える場合は補剛不能を示す *
      if ~is_ok_equal_
        scgbody{irow,12} = sprintf('必要補剛数(等) %.0f本*', nreq_);
      else
        scgbody{irow,12} = sprintf('必要補剛数(等) %.0f本', nreq_);
      end
      scgbody{irow,15} = sprintf('λ %d', ceil(lam_));

      % --- 端部行（端部に設ける補剛本数 + 限界Lb） ---
      % 均等配置で満足しなかった場合に端部行を出力する。
      if ~is_ok_equal_
        irow = irow + 1;
        scgbody{irow,11} = '端部';
        lbreq2_ = slratio.lbreq2(ig1);
        % 端部本数: Myを超える範囲を端部限界Lb間隔で配置する切上げ本数
        if lbreq2_ > 0
          nl_ = ceil(slratio.lbmy(ig1, 1) / lbreq2_);
          nr_ = ceil(slratio.lbmy(ig1, 2) / lbreq2_);
        else
          nl_ = 0; nr_ = 0;
        end
        scgbody{irow,12} = sprintf('(左) %d本 (右) %d本', nl_, nr_);
        lbreq2_str_ = fmt_ceil_abs(lbreq2_, 0);
        lbreq2_suffix_ = '';
        if ~is_ok_end_
          lbreq2_suffix_ = '*';
        end
        scgbody{irow,15} = ['限界Lb ' lbreq2_str_ lbreq2_suffix_];
      end

      % --- Lb値行（補剛数>0のとき） ---
      if ns_ > 0 && has_slr
        irow = irow + 1;
        [ns_, lb_report_, has_report_lb_] = ...
          get_stiffening_lb_report(nominal_girder, ing, ns_);
        if has_report_lb_
          for ilb_ = 1:ns_
            scgbody{irow, 6 + ilb_} = ...
              sprintf('%.0f', lb_report_(ilb_));
          end
        else
          lb1_ = slratio.lb(ig1, 1);
          lb4_ = slratio.lb(ig1, 2);
          scgbody{irow, 7} = sprintf('%.0f', lb1_);
          scgbody{irow,10} = sprintf('%.0f', lb4_);
          if ns_ >= 2
            lb_mid_ = lm_ / (ns_ + 1);
            scgbody{irow,8} = sprintf('%.0f', lb_mid_);
          end
          if ns_ >= 3
            scgbody{irow,9} = sprintf('%.0f', lb_mid_);
          end
        end
      end

      % --- ヘッダ行 ---
      irow = irow + 1;
      scgbody(irow, :) = {'', '左端', 'JOINT', '中央', ...
        'JOINT', '右端', '左/-仕口-/右', '', '', '左端', ...
        'JOINT', '中央', 'JOINT', '右端', '左/-仕口-/右', ''};

      % ========== データ行 ==========
      if has_axial
        % --- A ---
        irow = irow + 1;
        scgbody{irow, 1} = 'A';
        scgbody{irow, 2} = sprintf('%.1f', Asc(im1)*1e-2);
        scgbody{irow, 4} = sprintf('%.1f', A(imc)*1e-2);
        scgbody{irow, 6} = sprintf('%.1f', Asc(im2)*1e-2);
        scgbody{irow, 9} = '位置';
        scgbody{irow,10} = sprintf('%.0f', lfg(ig1, 1));
        scgbody{irow,12} = sprintf('%.0f', result.nomgc.xc_design(ing));
        scgbody{irow,14} = sprintf('%.0f', lfg(ig2, 2));
      end

      % --- Z ---
      irow = irow + 1;
      scgbody{irow, 1} = 'Z';
      scgbody{irow, 2} = sprintf('%.0f', ceil(Zij(im1)*1e-3));
      scgbody{irow, 4} = sprintf('%.0f', ceil(Zc(imc)*1e-3));
      scgbody{irow, 6} = sprintf('%.0f', ceil(Zij(im2)*1e-3));
      if ~has_axial
        scgbody{irow, 9} = '位置';
        scgbody{irow,10} = sprintf('%.0f', lfg(ig1, 1));
        scgbody{irow,12} = sprintf('%.0f', result.nomgc.xc_design(ing));
        scgbody{irow,14} = sprintf('%.0f', lfg(ig2, 2));
      end
      if has_axial
        scgbody{irow, 9} = 'fc';
        fci_ = fcn(inm, 1, ilc);
        fcc_ = fcn(inm, 3, clc);
        fcj_ = fcn(inm, 2, jlc);
        scgbody{irow,10} = sprintf('%.1f', fci_);
        scgbody{irow,12} = sprintf('%.1f', fcc_);
        scgbody{irow,14} = sprintf('%.1f', fcj_);
      end

      % --- Aw ---
      irow = irow + 1;
      scgbody{irow, 1} = 'Aw';
      scgbody{irow, 2} = sprintf('%.1f', Aw(im1)*1e-2);
      scgbody{irow, 6} = sprintf('%.1f', Aw(im2)*1e-2);
      scgbody{irow, 9} = 'Lb';
      scgbody{irow,10} = lb(ing, 1);
      sel_ = id_center_sel(ing, clc);
      scgbody{irow,12} = lbn_nom(ing, sel_);
      scgbody{irow,14} = lb(ing, 2);

      % --- ケース ---
      irow = irow + 1;
      scgbody{irow, 1} = 'ｹｰｽ';
      scgbody{irow, 2} = PRM.load_case_combo_name(ilc);
      scgbody{irow, 4} = PRM.load_case_combo_name(clc);
      scgbody{irow, 6} = PRM.load_case_combo_name(jlc);
      scgbody{irow, 9} = 'C';
      % C 補正係数: SS7互換でfbがfb1式で決定したときのみ表示する。
      scgbody{irow, 10} = fmt_C(fbn_by_fb1(inm, 1, ilc), ...
        C(ig1, 1, ilc));
      scgbody{irow, 12} = fmt_C(fbn_by_fb1(inm, 3, clc), ...
        C(igc, 3, clc));
      scgbody{irow, 14} = fmt_C(fbn_by_fb1(inm, 2, jlc), ...
        C(ig2, 2, jlc));

      if has_axial
        % --- N ---
        irow = irow + 1;
        scgbody{irow, 1} = 'N';
        scgbody{irow,2} = fmt1(-dfn(inm,1,ilc)*1e-3);
        nc_ = -result.nomgc.Ncn(inm,clc)*1e-3;
        scgbody{irow,4} = fmt1(nc_);
        scgbody{irow,6} = fmt1(-dfn(inm,7,jlc)*1e-3);
        scgbody{irow, 9} = 'fb';
        scgbody{irow,10} = sprintf('%.1f', fbn(inm,1,ilc));
        scgbody{irow,12} = sprintf('%.1f', fbn(inm,3,clc));
        scgbody{irow,14} = sprintf('%.1f', fbn(inm,2,jlc));
      end

      % --- M ---
      irow = irow + 1;
      scgbody{irow, 1} = 'M';
      scgbody{irow,2} = fmt1(-dfn(inm,5,ilc)*1e-6);
      mc_ = -result.nomgc.Mcn(inm,clc)*1e-6;
      scgbody{irow,4} = fmt1(mc_);
      scgbody{irow,6} = fmt1(dfn(inm,11,jlc)*1e-6);
      if has_axial
        scgbody{irow, 9} = 'σc/fc';
        scgbody{irow,10} = fmt_r(ration(inm,1,ilc));
        scgbody{irow,12} = fmt_r(abs(ration(inm,14,clc)));
        scgbody{irow,14} = fmt_r(ration(inm,7,jlc));
      else
        scgbody{irow, 9} = 'fb';
        scgbody{irow,10} = sprintf('%.1f', fbn(inm,1,ilc));
        scgbody{irow,12} = sprintf('%.1f', fbn(inm,3,clc));
        scgbody{irow,14} = sprintf('%.1f', fbn(inm,2,jlc));
      end

      % --- Q ---
      irow = irow + 1;
      scgbody{irow, 1} = 'Q';
      scgbody{irow,2} = fmt1(dfn(inm,3,ilc)*1e-3);
      scgbody{irow,6} = fmt1(dfn(inm,9,jlc)*1e-3);
      if has_axial
        scgbody{irow, 9} = 'σb/fb';
        scgbody{irow,10} = fmt_r(ration(inm,5,ilc));
        scgbody{irow,12} = fmt_r(ration(inm,13,clc));
        scgbody{irow,14} = fmt_r(ration(inm,11,jlc));
      else
        scgbody{irow, 9} = 'σb/fb';
        scgbody{irow,10} = fmt_r(gri(ing,ilc));
        scgbody{irow,12} = fmt_r(grc(ing,clc));
        scgbody{irow,14} = fmt_r(grj(ing,jlc));
      end

      if has_axial
        % --- σc ---
        irow = irow + 1;
        scgbody{irow, 1} = 'σc';
        scgbody{irow, 2} = fmt1(abs(stn(inm,1,ilc)));
        Ncn_c = result.nomgc.Ncn(inm, clc);
        scgbody{irow, 4} = fmt1(abs(Ncn_c/A(imc)));
        scgbody{irow, 6} = fmt1(abs(stn(inm,7,jlc)));
        scgbody{irow, 9} = 'TOTAL';
        scgbody{irow,10} = fmt_r(gri(ing,ilc));
        scgbody{irow,12} = fmt_r(grc(ing,clc));
        scgbody{irow,14} = fmt_r(grj(ing,jlc));
      end

      % --- σb ---
      irow = irow + 1;
      scgbody{irow, 1} = 'σb';
      scgbody{irow, 2} = fmt1(abs(stn(inm,5,ilc)));
      scgbody{irow, 4} = fmt1(abs(stcn(inm,clc)));
      scgbody{irow, 6} = fmt1(abs(stn(inm,11,jlc)));
      scgbody{irow, 9} = 'τ/fs';
      scgbody{irow,10} = fmt_r(gsi(ing,ilc));
      scgbody{irow,14} = fmt_r(gsj(ing,jlc));

      % --- τ ---
      irow = irow + 1;
      scgbody{irow, 1} = 'τ';
      scgbody{irow, 2} = fmt1(abs(stn(inm,3,ilc)));
      scgbody{irow, 6} = fmt1(abs(stn(inm,9,jlc)));

      % --- 警告行（曲げ検定比が1.0を超えるとき, SS7互換） ---
      if max([gri(ing,ilc), grc(ing,clc), grj(ing,jlc)]) > 1.0
        irow = irow + 1;
        scgbody{irow, 1} = ['　　　警告  672： S梁で曲げ応力度が' ...
          '許容曲げ応力度を超えています。'];
      end

      % --- 注意行（横補剛が制限値未達のとき） ---
      if ~is_ok_slr_
        irow = irow + 1;
        scgbody{irow, 1} = ['注意  676： S梁で横補剛が基準解説書の' ...
          '制限値を満たしていません。'];
      end

      % この梁エントリの最終行以外を CONT_MARKER 連結
      for r_ = irow_block_start:irow-1
        scgbody{r_, ncol} = PRM.CONT_MARKER;
      end
    end
  end
end
scgbody = scgbody(1:irow, :);

return

  function reps = pick_representative(cands)
  %pick_representative - 符号グループごとに代表1部材を選定
  %
  %   reps = pick_representative(cands) は、候補名目梁番号配列を
  %   断面符号でグループ化し、各グループから最大検定比を持つ
  %   名目梁を1本ずつ選定して返す。
  %
  %   入力引数:
  %     cands - 候補名目梁番号の配列
  %
  %   出力引数:
  %     reps - 各符号で最大検定比を持つ代表名目梁番号の配列
    if isempty(cands)
      reps = cands;
      return
    end
    isg_list = idnm2sg(cands);
    [~, ia] = unique(isg_list, 'stable');
    uisg = isg_list(ia);
    reps = zeros(size(uisg));
    for u_ = 1:numel(uisg)
      grp_ = cands(isg_list == uisg(u_));
      [~, best_] = max(max_ratio_all(grp_));
      reps(u_) = grp_(best_);
    end

    return
  end

  function s = fmt_C(show_c, Cv)
  %fmt_C - C 補正係数の表示文字列を生成
  %
  %   s = fmt_C(show_c, Cv) は、fbがfb1式で決定した場合だけ
  %   C補正係数を '%.3f' で書式化して返す。
  %
  %   入力引数:
  %     show_c - C補正係数を表示するかどうか
  %     Cv     - C補正係数値
  %
  %   出力引数:
  %     s - 書式化文字列または空文字
    if show_c
      s = sprintf('%.3f', Cv);
    else
      s = '';
    end

    return
  end

  function s = fmt1(x)
  %fmt1 - 応力を絶対値方向へ小数1桁切り上げて文字列化（SS7出力編A.9）
  %
  %   s = fmt1(x) は S梁断面算定表の応力表示。丸め・文字列化は共通
  %   ヘルパ fmt_ceil_abs に委譲し、小数1桁で切り上げ表示する。
    s = fmt_ceil_abs(x, 1);

    return
  end

  function s = fmt_r(r)
  %fmt_r - 検定比を SS7 互換で小数2桁切り上げ表示する
  %
  %   s = fmt_r(r) は検定比 r を小数2桁で切り上げ（ceil_ratio）した
  %   文字列を返す。1.0 を超える（NG）場合は SS7 互換で末尾に '*' を
  %   付す。切り上げ規則は検定比一覧・S柱断面算定表と統一する。
    rc = ceil_ratio(r);
    if rc > 1.0
      s = sprintf('%.2f*', rc);
    else
      s = sprintf('%.2f', rc);
    end

    return
  end
end
