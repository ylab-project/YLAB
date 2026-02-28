function scbbody = write_cell_section_calculation_brace( ...
  com, result)
%write_cell_section_calculation_brace - 鉛直ブレース断面算定表
%
%   scbbody = write_cell_section_calculation_brace( ...
%     com, result) は、
%   鉛直ブレースの断面算定表をセル配列で返す。
%   TB（メーカー製品引張ブレース）と鋼材ブレース
%   （BWFS/BHSS/BHSR）の両方に対応する。
%   SS7の鉛直ブレース断面算定表に準拠した形式で出力。
%
%   入力引数:
%     com    - 共通オブジェクト
%     result - 結果構造体
%
%   出力引数:
%     scbbody - データセル配列 [nrow×22]

ncol = 22;
secb = com.section.brace;
brace = com.member.brace;
nominal_brace = com.nominal.brace;
stype = com.section.property.type;
secmgr = com.secmgr;
secdim = result.secdim;
rs0_all = result.rs0;
rs_all = result.rs;
lm = result.lm;
lkx = result.lkx;
bnij = result.bnij;
nstory = com.nstory;
nblx = com.nblx;
nbly = com.nbly;
nnb = com.num.nominal_brace;
msprop_F = result.msprop.F;
msprop_A = result.msprop.A;
lambday = result.lambday;
lambdaz = result.lambdaz;
ftn = result.ftn;
is_tension = result.state.tb.is_tension;

% 部材→グローバル断面マッピング
idm2s = com.member.property.idsec;

% 鋼材ブレース判定
is_bsteel = ismember(stype, ...
  [PRM.BWFS PRM.BHSS PRM.BHSR]);

% 早期リターン
if com.nsecb == 0 || isempty(rs0_all)
  scbbody = cell(0, ncol);
  return
end

has_tb = any(stype == PRM.TB);
has_steel = any(is_bsteel);
if ~has_tb && ~has_steel
  scbbody = cell(0, ncol);
  return
end

% TB断面のリスト情報取得（HTB, GP等）
if has_tb
  tblist = getListRecord( ...
    secmgr, secdim(stype == PRM.TB, :));
  idsb_tb = find( ...
    secb.tctype == PRM.BRACE_TENSION);
  ntb = length(idsb_tb);
  isb2itb = zeros(max(idsb_tb), 1);
  for itb = 1:ntb
    isb2itb(idsb_tb(itb)) = itb;
  end
end

% 走査用配列
ids_story = nominal_brace.idstory;
idx_nom = nominal_brace.idx;
idy_nom = nominal_brace.idy;
idir_nom = nominal_brace.idir;

% 出力バッファ確保
scbbody = cell(5 * nnb + nstory, ncol);
irow = 0;

% 階→方向→通りの順で走査
for ist = nstory:-1:1
  prev_material_ = '';

  % X方向: iy→ix
  for iy = 1:nbly
    for ix = 1:nblx
      inb_list = find(ids_story == ist ...
        & idx_nom(:,1) == ix ...
        & idy_nom(:,1) == iy ...
        & idir_nom == PRM.X);
      for jj = 1:length(inb_list)
        inb = inb_list(jj);
        ib1 = nominal_brace.idmeb(inb, 1);
        isb_ = brace.idsecb(ib1);
        idsec_ = idm2s(brace.idme(ib1));
        stype_ = stype(idsec_);
        is_tb_ = stype_ == PRM.TB;
        is_steel_ = is_bsteel(idsec_);
        if ~is_tb_ && ~is_steel_
          continue
        end
        [irow, prev_material_] = ...
          write_header_if_needed( ...
          irow, prev_material_, ...
          is_steel_, isb_, ib1);
        if is_tb_
          output_member_tb(inb, isb_);
        else
          output_member_steel(inb, isb_);
        end
      end
    end
  end

  % Y方向: ix→iy
  for ix = 1:nblx
    for iy = 1:nbly
      inb_list = find(ids_story == ist ...
        & idx_nom(:,1) == ix ...
        & idy_nom(:,1) == iy ...
        & idir_nom == PRM.Y);
      for jj = 1:length(inb_list)
        inb = inb_list(jj);
        ib1 = nominal_brace.idmeb(inb, 1);
        isb_ = brace.idsecb(ib1);
        idsec_ = idm2s(brace.idme(ib1));
        stype_ = stype(idsec_);
        is_tb_ = stype_ == PRM.TB;
        is_steel_ = is_bsteel(idsec_);
        if ~is_tb_ && ~is_steel_
          continue
        end
        [irow, prev_material_] = ...
          write_header_if_needed( ...
          irow, prev_material_, ...
          is_steel_, isb_, ib1);
        if is_tb_
          output_member_tb(inb, isb_);
        else
          output_member_steel(inb, isb_);
        end
      end
    end
  end
end
scbbody = scbbody(1:irow, :);

return

  function [ir, pm] = write_header_if_needed( ...
    ir, pm, is_steel_arg, isb_arg, ib1_arg)
  %write_header_if_needed - 材料ヘッダ行を出力
    if is_steel_arg
      idsl_ = secb.id_section_list(isb_arg);
      mat_ = ...
        secmgr.secList.material_name{idsl_, 1};
      F_hdr_ = msprop_F(brace.idme(ib1_arg));
      hkey_ = sprintf('%s_%.0f', mat_, F_hdr_);
    else
      hkey_ = 'TB';
    end
    if ~strcmp(hkey_, pm)
      ir = ir + 1;
      if is_steel_arg
        scbbody{ir, 1} = sprintf( ...
          ' 鉄骨： [ %-9s]  Ｆ値   %.0f', ...
          mat_, F_hdr_);
      else
        scbbody{ir, 1} = ...
          ' 鉄骨： [ ---      ]  Ｆ値   ---';
      end
      pm = hkey_;
    end
  end

  function output_member_tb(inb_, isb_)
  %output_member_tb - TB用の出力処理
    ibij_ = nominal_brace.idmeb(inb_, :);
    npair_ = nnz(ibij_);
    ib1_ = ibij_(1);
    im1_ = brace.idme(ib1_);
    itb_ = isb2itb(isb_);

    % 断面プロパティ
    idsec_ = idm2s(im1_);
    A_cm2_ = secdim(idsec_, 2) * 1e-2;
    Ae_cm2_ = secdim(idsec_, 3) * 1e-2;
    Ta_kN_ = secdim(idsec_, 4);
    sec_name_ = secb.name{isb_};
    type_name_ = tblist.type{itb_};
    HTB_str_ = tblist.HTB{itb_};
    GP_str_ = tblist.GP{itb_};

    % 断面符号行
    irow = irow + 1;
    scbbody{irow, 1} = ...
      sprintf('[%-6s]', sec_name_);
    scbbody{irow, 7} = 'TYPE';
    scbbody{irow, 8} = sprintf( ...
      '%s [ %s  %s  %s ]', ...
      get_type_label(ib1_), ...
      type_name_, HTB_str_, GP_str_);

    % 配置・列ラベル行
    irow = irow + 1;
    scbbody{irow, 1} = sprintf('[%s', ...
      nominal_brace.floor_name{inb_});
    scbbody{irow, 3} = ...
      nominal_brace.frame_name{inb_, 1};
    scbbody{irow, 4} = ...
      nominal_brace.coord_name{inb_, 1};
    scbbody{irow, 5} = '-';
    scbbody{irow, 6} = sprintf('%s]', ...
      nominal_brace.coord_name{inb_, 2});
    scbbody{irow, 8} = 'L';
    scbbody{irow, 9} = 'LNac';
    scbbody{irow, 10} = 'LNat';
    scbbody{irow, 11} = 'sNac';
    scbbody{irow, 12} = 'sNat';
    scbbody{irow, 13} = 'NL';
    scbbody{irow, 14} = 'NS';
    scbbody{irow, 15} = 'NW(正)';
    scbbody{irow, 16} = 'NW(負)';
    scbbody{irow, 17} = 'NK(正)';
    scbbody{irow, 18} = 'NK(負)';
    scbbody{irow, 19} = 'ｹｰｽ';
    scbbody{irow, 20} = 'Nt/Nat';
    scbbody{irow, 21} = 'Nc/Nac';

    % Ab・Ae データ行
    % X形: 左→右の固定順、K形: 部材登録順
    is_x_ = brace.type(ib1_) ...
      == PRM.BRACE_MEMBER_TYPE_X;
    if is_x_
      targets_ = [ ...
        PRM.BRACE_MEMBER_PAIR_L ...
        PRM.BRACE_MEMBER_PAIR_BOTH_L; ...
        PRM.BRACE_MEMBER_PAIR_R ...
        PRM.BRACE_MEMBER_PAIR_BOTH_R];
    end
    for ilr_ = 1:2
      irow = irow + 1;
      if ilr_ == 1
        scbbody{irow, 1} = 'Ab';
        scbbody{irow, 2} = ...
          sprintf('%.2f', A_cm2_);
      else
        scbbody{irow, 1} = 'Ae';
        scbbody{irow, 2} = ...
          sprintf('%.2f', Ae_cm2_);
      end

      if is_x_
        hit_ = find( ...
          brace.pair(ibij_(1:npair_)) ...
          == targets_(ilr_,1) ...
          | brace.pair(ibij_(1:npair_)) ...
          == targets_(ilr_,2), 1);
        if isempty(hit_)
          continue
        end
        ib_ = ibij_(hit_);
      else
        if ilr_ > npair_
          continue
        end
        ib_ = ibij_(ilr_);
      end
      im_ = brace.idme(ib_);

      scbbody{irow, 7} = get_pos_label(ib_);
      scbbody{irow, 8} = ...
        sprintf('%.0f', lm(im_));
      scbbody{irow, 10} = ...
        sprintf('%.0f', Ta_kN_ / 1.5);
      scbbody{irow, 12} = ...
        sprintf('%.0f', Ta_kN_);

      % NL（G+P成分）
      scbbody{irow, 13} = sprintf( ...
        '%.0f', rs0_all(im_, 1, 1) * 1e-3);

      % 最大検定比のケース
      tiebreak_ = zeros(1, size(bnij, 2));
      tiebreak_(PRM.LT) = eps;
      tiebreak_(PRM.EXP) = eps;
      tiebreak_(PRM.EYP) = eps;
      [~, c_ilc_] = max( ...
        bnij(ib_, :) + tiebreak_);
      ratio_ = bnij(ib_, c_ilc_) + 1;

      % NK値
      [nkp_, nkn_] = get_nk(ib_, im_);
      scbbody{irow, 17} = ...
        sprintf('%.0f', nkp_);
      scbbody{irow, 18} = ...
        sprintf('%.0f', nkn_);

      % ケース名・検定比
      scbbody{irow, 19} = ...
        PRM.load_case_name(c_ilc_);
      if Ta_kN_ > 0
        scbbody{irow, 20} = sprintf( ...
          '%.2f', ceil(ratio_ * 100) / 100);
      end
    end
  end

  function output_member_steel(inb_, isb_)
  %output_member_steel - 鋼材ブレース用の出力処理
    ibij_ = nominal_brace.idmeb(inb_, :);
    npair_ = nnz(ibij_);
    ib1_ = ibij_(1);
    im1_ = brace.idme(ib1_);

    % 断面プロパティ
    idsec_ = idm2s(im1_);
    stype_ = stype(idsec_);
    A_mm2_ = msprop_A(im1_);
    A_cm2_ = A_mm2_ * 1e-2;
    Ae_cm2_ = A_cm2_;
    F_ = msprop_F(im1_);
    inm_ = nominal_brace.idnominal(inb_);
    sec_name_ = secb.name{isb_};

    % Λ（限界細長比）
    E_ = 205000;
    Lambda_ = pi * sqrt(E_ / (0.6 * F_));

    % 断面符号行
    irow = irow + 1;
    scbbody{irow, 1} = ...
      sprintf('[%-6s]', sec_name_);
    scbbody{irow, 7} = 'TYPE';
    scbbody{irow, 8} = sprintf( ...
      '%s [ %s ]', ...
      get_type_label_steel(ib1_, im1_), ...
      format_shape_name( ...
      stype_, secdim(idsec_, :)));

    % 配置・列ラベル行
    irow = irow + 1;
    scbbody{irow, 1} = sprintf('[%s', ...
      nominal_brace.floor_name{inb_});
    scbbody{irow, 3} = ...
      nominal_brace.frame_name{inb_, 1};
    scbbody{irow, 4} = ...
      nominal_brace.coord_name{inb_, 1};
    scbbody{irow, 5} = '-';
    scbbody{irow, 6} = sprintf('%s]', ...
      nominal_brace.coord_name{inb_, 2});
    scbbody{irow, 8} = 'L';
    scbbody{irow, 9} = sprintf('%s', 'λ');
    scbbody{irow, 10} = 'Lfc';
    scbbody{irow, 11} = 'Lft';
    scbbody{irow, 12} = 'sfc';
    scbbody{irow, 13} = 'sft';
    scbbody{irow, 14} = 'NL';
    scbbody{irow, 15} = 'NS';
    scbbody{irow, 16} = 'NW(正)';
    scbbody{irow, 17} = 'NW(負)';
    scbbody{irow, 18} = 'NK(正)';
    scbbody{irow, 19} = 'NK(負)';
    scbbody{irow, 20} = 'ｹｰｽ';
    scbbody{irow, 21} = sprintf('%s', 'σt/ft');
    scbbody{irow, 22} = sprintf('%s', 'σc/fc');

    % Ab・Ae データ行
    % X形: 左→右の固定順、K形: 部材登録順
    is_x_ = brace.type(ib1_) ...
      == PRM.BRACE_MEMBER_TYPE_X;
    if is_x_
      targets_ = [ ...
        PRM.BRACE_MEMBER_PAIR_L ...
        PRM.BRACE_MEMBER_PAIR_BOTH_L; ...
        PRM.BRACE_MEMBER_PAIR_R ...
        PRM.BRACE_MEMBER_PAIR_BOTH_R];
    end
    for ilr_ = 1:2
      irow = irow + 1;
      if ilr_ == 1
        scbbody{irow, 1} = 'Ab';
        scbbody{irow, 2} = ...
          sprintf('%.2f', A_cm2_);
        scbbody{irow, 4} = sprintf( ...
          '%s', 'Λ');
        scbbody{irow, 6} = ...
          sprintf('%.1f ', Lambda_);
      else
        scbbody{irow, 1} = 'Ae';
        scbbody{irow, 2} = ...
          sprintf('%.2f', Ae_cm2_);
      end

      if is_x_
        hit_ = find( ...
          brace.pair(ibij_(1:npair_)) ...
          == targets_(ilr_,1) ...
          | brace.pair(ibij_(1:npair_)) ...
          == targets_(ilr_,2), 1);
        if isempty(hit_)
          scbbody{irow, 7} = ...
            get_pos_label_lr(ilr_, ib1_);
          scbbody{irow, 21} = ' ----';
          continue
        end
        ib_ = ibij_(hit_);
      else
        if ilr_ > npair_
          continue
        end
        ib_ = ibij_(ilr_);
      end
      im_ = brace.idme(ib_);

      % 引張なし側の判定
      if is_no_tension_side_(ib_)
        scbbody{irow, 7} = ...
          get_pos_label(ib_);
        scbbody{irow, 21} = ' ----';
        continue
      end

      % 位置ラベル
      scbbody{irow, 7} = get_pos_label(ib_);

      % L（座屈長）
      scbbody{irow, 8} = ...
        sprintf('%.0f', lkx(im_));

      % λ（細長比）
      lambda_ = max( ...
        lambday(im_), lambdaz(im_, 1));
      scbbody{irow, 9} = ...
        sprintf('%.1f', lambda_);

      % fc 再計算
      [Lfc_, sfc_] = ...
        calc_fc_steel(lambda_, Lambda_, F_);

      % 引張のみ判定
      is_tonly_ = is_tension(im_);

      % Lfc, Lft, sfc, sft
      if ~is_tonly_
        scbbody{irow, 10} = ...
          sprintf('%.0f', Lfc_);
        scbbody{irow, 12} = ...
          sprintf('%.0f', sfc_);
      end
      scbbody{irow, 11} = ...
        sprintf('%.0f', ftn(inm_, 1));
      scbbody{irow, 13} = ...
        sprintf('%.0f', ftn(inm_, 2));

      % NL（G+P成分）
      scbbody{irow, 14} = sprintf( ...
        '%.0f', rs0_all(im_, 1, 1) * 1e-3);

      % NK値
      [nkp_, nkn_] = get_nk(ib_, im_);
      scbbody{irow, 18} = ...
        sprintf('%.0f', nkp_);
      scbbody{irow, 19} = ...
        sprintf('%.0f', nkn_);

      % ケース・検定比
      [c_ilc_, rt_, rc_] = ...
        calc_ratios_steel( ...
        im_, A_mm2_, F_, Lfc_, is_tonly_);
      scbbody{irow, 20} = ...
        PRM.load_case_name(c_ilc_);
      scbbody{irow, 21} = sprintf( ...
        '%.2f ', ceil(rt_ * 100) / 100);
      if ~is_tonly_ && rc_ > 0
        scbbody{irow, 22} = sprintf( ...
          '%.2f ', ceil(rc_ * 100) / 100);
      end
    end
  end

  function flag = is_no_tension_side_(ib_)
  %is_no_tension_side_ - 引張なし側の判定
    im_ = brace.idme(ib_);
    flag = all(rs_all(im_, 1, :) == 0);
  end

  function label_ = get_type_label(ib_)
  %get_type_label - TB用のTYPEラベル生成
    switch brace.type(ib_)
      case PRM.BRACE_MEMBER_TYPE_X
        if ismember(brace.pair(ib_), ...
            [PRM.BRACE_MEMBER_PAIR_BOTH_L, ...
             PRM.BRACE_MEMBER_PAIR_BOTH_R])
          label_ = 'X形(引張のみ)';
        elseif ismember(brace.pair(ib_), ...
            PRM.BRACE_MEMBER_PAIR_L)
          label_ = '／形(引張のみ)';
        else
          label_ = '＼形(引張のみ)';
        end
      case PRM.BRACE_MEMBER_TYPE_K_UPPER
        label_ = 'K上形(引張のみ)';
      case PRM.BRACE_MEMBER_TYPE_K_LOWER
        label_ = 'K下形(引張のみ)';
      otherwise
        label_ = '(引張のみ)';
    end
  end

  function label_ = get_type_label_steel( ...
    ib_, im_)
  %get_type_label_steel - 鋼材用のTYPEラベル生成
    is_tonly_ = is_tension(im_);
    if is_tonly_
      tc_str_ = '引張のみ';
    else
      tc_str_ = '引張・圧縮有効';
    end
    switch brace.type(ib_)
      case PRM.BRACE_MEMBER_TYPE_X
        if ismember(brace.pair(ib_), ...
            [PRM.BRACE_MEMBER_PAIR_BOTH_L, ...
             PRM.BRACE_MEMBER_PAIR_BOTH_R])
          label_ = sprintf( ...
            'X形(%s)', tc_str_);
        elseif ismember(brace.pair(ib_), ...
            PRM.BRACE_MEMBER_PAIR_L)
          label_ = sprintf( ...
            'X形(／)(%s)', tc_str_);
        else
          label_ = sprintf( ...
            'X形(＼)(%s)', tc_str_);
        end
      case PRM.BRACE_MEMBER_TYPE_K_UPPER
        label_ = sprintf( ...
          'K上形(%s)', tc_str_);
      case PRM.BRACE_MEMBER_TYPE_K_LOWER
        label_ = sprintf( ...
          'K下形(%s)', tc_str_);
      otherwise
        label_ = sprintf('(%s)', tc_str_);
    end
  end

  function label_ = get_pos_label(ib_)
  %get_pos_label - 位置ラベル生成
    switch brace.type(ib_)
      case PRM.BRACE_MEMBER_TYPE_X
        if ismember(brace.pair(ib_), ...
            [PRM.BRACE_MEMBER_PAIR_L, ...
             PRM.BRACE_MEMBER_PAIR_BOTH_L])
          label_ = '左下り';
        else
          label_ = '右下り';
        end
      case PRM.BRACE_MEMBER_TYPE_K_UPPER
        if ismember(brace.pair(ib_), ...
            [PRM.BRACE_MEMBER_PAIR_L, ...
             PRM.BRACE_MEMBER_PAIR_BOTH_L])
          label_ = '左側';
        else
          label_ = '右側';
        end
      case PRM.BRACE_MEMBER_TYPE_K_LOWER
        % K下形: 左下がり=右側、右下がり=左側
        if ismember(brace.pair(ib_), ...
            [PRM.BRACE_MEMBER_PAIR_L, ...
             PRM.BRACE_MEMBER_PAIR_BOTH_L])
          label_ = '右側';
        else
          label_ = '左側';
        end
      otherwise
        label_ = '';
    end
  end

  function label_ = get_pos_label_lr(ilr_, ib_)
  %get_pos_label_lr - 左右番号からラベル生成
    switch brace.type(ib_)
      case PRM.BRACE_MEMBER_TYPE_X
        if ilr_ == 1, label_ = '左下り';
        else,         label_ = '右下り'; end
      case {PRM.BRACE_MEMBER_TYPE_K_UPPER, ...
          PRM.BRACE_MEMBER_TYPE_K_LOWER}
        if ilr_ == 1, label_ = '左側';
        else,         label_ = '右側'; end
      otherwise
        label_ = '';
    end
  end

  function [nkp, nkn] = get_nk(ib_, im_)
  %get_nk - 地震時軸力の取得（G+P+K、両方向最大）
    bp_ = bnij(ib_, [PRM.EXP PRM.EYP]);
    [~, idp_] = max(bp_);
    idc_pos_ = [PRM.EXP PRM.EYP];
    nkp = rs_all( ...
      im_, 1, idc_pos_(idp_)) * 1e-3;

    bn_ = bnij(ib_, [PRM.EXN PRM.EYN]);
    [~, idn_] = max(bn_);
    idc_neg_ = [PRM.EXN PRM.EYN];
    nkn = rs_all( ...
      im_, 1, idc_neg_(idn_)) * 1e-3;
  end

  function name = format_shape_name( ...
    stype_, dim_)
  %format_shape_name - 断面形状名生成
    v = @(x) sprintf('%g', x);
    switch stype_
      case PRM.BWFS
        name = sprintf( ...
          'H-%s*%s*%s*%s*%s', ...
          v(dim_(1)), v(dim_(2)), ...
          v(dim_(3)), v(dim_(4)), ...
          v(dim_(5)));
      case PRM.BHSS
        name = sprintf( ...
          '□-%s*%s*%s*%s', ...
          v(dim_(1)), v(dim_(1)), ...
          v(dim_(2)), v(dim_(3)));
      case PRM.BHSR
        name = sprintf('○-%s*%s', ...
          v(dim_(1)), v(dim_(2)));
      otherwise
        name = '';
    end
  end

  function [Lfc, sfc] = calc_fc_steel( ...
    lambda, Lambda, F)
  %calc_fc_steel - 鋼材ブレースのfc再計算
    ratio = lambda / Lambda;
    if ratio <= 1.0
      nu = 3/2 + 2/3 * ratio^2;
      Lfc = F / nu * (1.0 - 0.4 * ratio^2);
    else
      Lfc = 0.277 * F / ratio^2;
    end
    sfc = Lfc * 1.5;
  end

  function [c_ilc, max_rt, max_rc] = ...
    calc_ratios_steel( ...
    im_, A_, F_, Lfc_, is_tonly_)
  %calc_ratios_steel - 鋼材ブレースの検定比計算
    nlc_ = size(rs_all, 3);
    rt_ = zeros(1, nlc_);
    rc_ = zeros(1, nlc_);
    Ae_ = A_;

    for ilc_ = 1:nlc_
      N_ = rs_all(im_, 1, ilc_);
      if ilc_ == 1
        ft_ = F_ / 1.5;
        fc_ = Lfc_;
      else
        ft_ = F_;
        fc_ = Lfc_ * 1.5;
      end
      if N_ < 0
        rt_(ilc_) = abs(N_) / (Ae_ * ft_);
      elseif ~is_tonly_ && fc_ > 0
        rc_(ilc_) = N_ / (A_ * fc_);
      end
    end

    max_rt = max(rt_);
    max_rc = max(rc_);
    overall_ = max(rt_, rc_);
    tiebreak_ = zeros(1, nlc_);
    tiebreak_(PRM.LT) = eps;
    tiebreak_(PRM.EXP) = eps;
    tiebreak_(PRM.EYP) = eps;
    [~, c_ilc] = max(overall_ + tiebreak_);
  end

end