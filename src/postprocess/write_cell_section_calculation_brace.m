function scbbody = write_cell_section_calculation_brace(com, result)
%write_cell_section_calculation_brace - 鉛直ブレース断面算定表
%
%   scbbody = write_cell_section_calculation_brace(com, result) は、
%   鉛直ブレースの断面算定表をセル配列で返す。TB（メーカー製品
%   引張ブレース）、鋼材ブレース（BWFS/BHSS/BHSR）、BRB（座屈
%   拘束ブレース）に対応し、SS7の出力形式に準拠する。
%
%   入力引数:
%     com    - 共通オブジェクト
%     result - 結果構造体
%
%   出力引数:
%     scbbody - データセル配列 [nrow×ncol]
%
%   備考:
%     - ncol = 23。末尾列は論理ブロック継続マーカ
%       （PRM.CONT_MARKER）を保持し、SS7論理ブロックの制御に用いる。

% 列数: 鋼材ブレースの最大列幅(22) + 末尾の継続マーカ列1
ncol = 23;
secb = com.section.brace;
brace = com.member.brace;
nominal_brace = com.nominal.brace;
stype = com.section.property.type;
secmgr = com.secmgr;
secdim = result.secdim;
rs0_all = result.rs0;
rs_all = result.rs;
% L 値は SS7 マニュアル 3.8.1 のブレース長さ（内法長さ）を
% 使用する。剛性表・応力表で表示される「部材長 mm」（構造心
% 間距離）とは異なる値である。
lm = result.lm_buckling;
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
is_bsteel = ismember(stype, [PRM.BWFS PRM.BHSS PRM.BHSR]);

% 早期リターン
if com.nsecb == 0 || isempty(rs0_all)
  scbbody = cell(0, ncol);
  return
end

has_tb = any(stype == PRM.TB);
has_steel = any(is_bsteel);
has_brb = any(stype == PRM.BRB);
if ~has_tb && ~has_steel && ~has_brb
  scbbody = cell(0, ncol);
  return
end

% TB断面のリスト情報取得（HTB, GP等）
if has_tb
  tblist = getListRecord(secmgr, secdim(stype == PRM.TB, :));
  idsb_tb = find(secb.tctype == PRM.BRACE_TENSION);
  ntb = length(idsb_tb);
  isb2itb = zeros(max(idsb_tb), 1);
  for itb = 1:ntb
    isb2itb(idsb_tb(itb)) = itb;
  end
end

% BRB断面のリスト情報取得（製品記号、座屈拘束鋼管寸法等）
if has_brb
  brblist = getListRecord(secmgr, secdim(stype == PRM.BRB, :));
  idsb_brb = find(secb.type == PRM.BRB);
  nbrb = length(idsb_brb);
  isb2ibrb = zeros(max(idsb_brb), 1);
  isb2ibrb(idsb_brb) = 1:nbrb;
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
      inb_list = find(ids_story == ist & idx_nom(:,1) == ix ...
        & idy_nom(:,1) == iy & idir_nom == PRM.X);
      for jj = 1:length(inb_list)
        inb = inb_list(jj);
        idmeb_row = nominal_brace.idmeb(inb, :);
        ib1 = idmeb_row(find(idmeb_row > 0, 1));
        isb_ = brace.idsecb(ib1);
        idsec_ = idm2s(brace.idme(ib1));
        stype_ = stype(idsec_);
        is_tb_ = stype_ == PRM.TB;
        is_steel_ = is_bsteel(idsec_);
        is_brb_ = stype_ == PRM.BRB;
        if ~is_tb_ && ~is_steel_ && ~is_brb_
          continue
        end
        [irow, prev_material_] = write_header_if_needed( ...
          irow, prev_material_, is_steel_, is_brb_, isb_, ib1);
        if is_tb_
          output_member_tb(inb, isb_);
        elseif is_brb_
          output_member_brb(inb, isb_);
        else
          output_member_steel(inb, isb_);
        end
      end
    end
  end

  % Y方向: ix→iy
  for ix = 1:nblx
    for iy = 1:nbly
      inb_list = find(ids_story == ist & idx_nom(:,1) == ix ...
        & idy_nom(:,1) == iy & idir_nom == PRM.Y);
      for jj = 1:length(inb_list)
        inb = inb_list(jj);
        idmeb_row = nominal_brace.idmeb(inb, :);
        ib1 = idmeb_row(find(idmeb_row > 0, 1));
        isb_ = brace.idsecb(ib1);
        idsec_ = idm2s(brace.idme(ib1));
        stype_ = stype(idsec_);
        is_tb_ = stype_ == PRM.TB;
        is_steel_ = is_bsteel(idsec_);
        is_brb_ = stype_ == PRM.BRB;
        if ~is_tb_ && ~is_steel_ && ~is_brb_
          continue
        end
        [irow, prev_material_] = write_header_if_needed( ...
          irow, prev_material_, is_steel_, is_brb_, isb_, ib1);
        if is_tb_
          output_member_tb(inb, isb_);
        elseif is_brb_
          output_member_brb(inb, isb_);
        else
          output_member_steel(inb, isb_);
        end
      end
    end
  end
end
scbbody = scbbody(1:irow, :);

return

  function [ir, pm] = write_header_if_needed(ir, pm, ...
      is_steel_arg, is_brb_arg, isb_arg, ib1_arg)
  %write_header_if_needed - 材料ヘッダ行を出力
  %
  %   [ir, pm] = write_header_if_needed(ir, pm, is_steel_arg, ...
  %     is_brb_arg, isb_arg, ib1_arg) は、必要に応じて材料情報の
  %   ヘッダ行を1行追加し、更新後の行カウンタと識別キーを返す。
  %
  %   入力引数:
  %     ir           - 現在の行カウンタ
  %     pm           - 直前に出力した材料識別キー
  %     is_steel_arg - 鋼材ブレース判定フラグ
  %     is_brb_arg   - BRB判定フラグ
  %     isb_arg      - 断面リストインデックス
  %     ib1_arg      - 代表部材インデックス
  %
  %   出力引数:
  %     ir - 更新後の行カウンタ
  %     pm - 更新後の材料識別キー
    if is_steel_arg || is_brb_arg
      idsl_ = secb.id_section_list(isb_arg);
      mat_ = secmgr.secList.material_name{idsl_, 1};
      F_hdr_ = msprop_F(brace.idme(ib1_arg));
      hkey_ = sprintf('%s_%.0f', mat_, F_hdr_);
    else
      hkey_ = 'TB';
    end
    if ~strcmp(hkey_, pm)
      ir = ir + 1;
      if is_steel_arg || is_brb_arg
        scbbody{ir, 1} = sprintf(' 鉄骨： [ %-9s]  Ｆ値   %.0f', ...
          mat_, F_hdr_);
      else
        scbbody{ir, 1} = ' 鉄骨： [ ---      ]  Ｆ値   ---';
      end
      scbbody{ir, ncol} = PRM.CONT_MARKER;
      pm = hkey_;
    end
  end

  function output_member_tb(inb_, isb_)
  %output_member_tb - TB（メーカー製品引張ブレース）用の出力処理
  %
  %   output_member_tb(inb_, isb_) は、TBブレース1呼称分の
  %   断面符号行・ラベル行・Ab/Aeデータ行を scbbody に追記する。
  %
  %   入力引数:
  %     inb_ - 呼称ブレースインデックス
  %     isb_ - 断面リストインデックス
    ibij_ = nominal_brace.idmeb(inb_, :);
    nz_cols_ = find(ibij_ > 0);
    ib1_ = ibij_(nz_cols_(1));
    im1_ = brace.idme(ib1_);
    itb_ = isb2itb(isb_);

    % 断面プロパティ
    idsec_ = idm2s(im1_);
    A_cm2_ = secdim(idsec_, 2) * 1e-2;
    Ae_cm2_ = secdim(idsec_, 3) * 1e-2;
    Ta_kN_ = secdim(idsec_, 4);
    sec_name_ = secb.name{isb_};
    type_name_ = tblist.label{itb_};
    HTB_str_ = tblist.HTB{itb_};
    GP_str_ = tblist.GP{itb_};

    % 断面符号行
    irow = irow + 1;
    scbbody{irow, 1} = sprintf('[%-6s]', sec_name_);
    scbbody{irow, 7} = 'TYPE';
    scbbody{irow, 8} = sprintf('%s [ %s  %s  %s ]', ...
      get_type_label(ib1_, stype(idsec_)), type_name_, HTB_str_, GP_str_);
    scbbody{irow, ncol} = PRM.CONT_MARKER;

    % 配置・列ラベル行
    irow = irow + 1;
    scbbody{irow, 1} = sprintf('[%s', nominal_brace.floor_name{inb_});
    scbbody{irow, 3} = nominal_brace.frame_name{inb_, 1};
    scbbody{irow, 4} = nominal_brace.coord_name{inb_, 1};
    scbbody{irow, 5} = '-';
    scbbody{irow, 6} = sprintf('%s]', nominal_brace.coord_name{inb_, 2});
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
    scbbody{irow, ncol} = PRM.CONT_MARKER;

    % Ab・Ae データ行
    % X形: 左→右の固定順、K形: 部材登録順
    is_x_ = brace.type(ib1_) == PRM.BRACE_MEMBER_TYPE_X;
    if is_x_
      targets_ = [PRM.BRACE_MEMBER_PAIR_L PRM.BRACE_MEMBER_PAIR_BOTH_L; ...
        PRM.BRACE_MEMBER_PAIR_R PRM.BRACE_MEMBER_PAIR_BOTH_R];
    end
    for ilr_ = 1:2
      irow = irow + 1;
      if ilr_ < 2
        scbbody{irow, ncol} = PRM.CONT_MARKER;
      end
      if ilr_ == 1
        scbbody{irow, 1} = 'Ab';
        scbbody{irow, 2} = sprintf('%.2f', A_cm2_);
      else
        scbbody{irow, 1} = 'Ae';
        scbbody{irow, 2} = sprintf('%.2f', Ae_cm2_);
      end

      if is_x_
        ibij_nz_ = ibij_(nz_cols_);
        hit_ = find(brace.pair(ibij_nz_) == targets_(ilr_,1) ...
          | brace.pair(ibij_nz_) == targets_(ilr_,2), 1);
        if isempty(hit_)
          continue
        end
        ib_ = ibij_nz_(hit_);
      else
        if ibij_(ilr_) == 0
          continue
        end
        ib_ = ibij_(ilr_);
      end
      im_ = brace.idme(ib_);

      scbbody{irow, 7} = get_pos_label(ib_);
      scbbody{irow, 8} = sprintf('%.0f', lm(im_));
      scbbody{irow, 10} = sprintf('%.0f', Ta_kN_ / 1.5);
      scbbody{irow, 12} = sprintf('%.0f', Ta_kN_);

      % NL（G+P成分）
      scbbody{irow, 13} = sprintf('%.0f', rs0_all(im_, 1, 1) * 1e-3);

      % 最大検定比のケース
      tiebreak_ = zeros(1, size(bnij, 2));
      tiebreak_(PRM.LT) = eps;
      tiebreak_(PRM.EXP) = eps;
      tiebreak_(PRM.EYP) = eps;
      [~, c_ilc_] = max(bnij(ib_, :) + tiebreak_);
      ratio_ = bnij(ib_, c_ilc_) + 1;

      % NK値
      [nkp_, nkn_] = get_nk(ib_, im_);
      scbbody{irow, 17} = sprintf('%.0f', nkp_);
      scbbody{irow, 18} = sprintf('%.0f', nkn_);

      % ケース名・検定比
      scbbody{irow, 19} = PRM.load_case_combo_name(c_ilc_);
      if Ta_kN_ > 0
        scbbody{irow, 20} = sprintf('%.2f', ceil(ratio_ * 100) / 100);
      end
    end
  end

  function output_member_steel(inb_, isb_)
  %output_member_steel - 鋼材ブレース（BWFS/BHSS/BHSR）用の出力処理
  %
  %   output_member_steel(inb_, isb_) は、鋼材ブレース1呼称分の
  %   断面符号行・ラベル行・Ab/Aeデータ行を scbbody に追記する。
  %
  %   入力引数:
  %     inb_ - 呼称ブレースインデックス
  %     isb_ - 断面リストインデックス
    ibij_ = nominal_brace.idmeb(inb_, :);
    nz_cols_ = find(ibij_ > 0);
    ib1_ = ibij_(nz_cols_(1));
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
    scbbody{irow, 1} = sprintf('[%-6s]', sec_name_);
    scbbody{irow, 7} = 'TYPE';
    type_label_ = get_type_label(ib1_, stype_);
    shape_name_ = format_shape_name(stype_, secdim(idsec_, :));
    scbbody{irow, 8} = sprintf('%s [ %s ]', type_label_, shape_name_);
    scbbody{irow, ncol} = PRM.CONT_MARKER;

    % 配置・列ラベル行
    irow = irow + 1;
    scbbody{irow, 1} = sprintf('[%s', nominal_brace.floor_name{inb_});
    scbbody{irow, 3} = nominal_brace.frame_name{inb_, 1};
    scbbody{irow, 4} = nominal_brace.coord_name{inb_, 1};
    scbbody{irow, 5} = '-';
    scbbody{irow, 6} = sprintf('%s]', nominal_brace.coord_name{inb_, 2});
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
    scbbody{irow, ncol} = PRM.CONT_MARKER;

    % Ab・Ae データ行
    % X形: 左→右の固定順、K形: 部材登録順
    is_x_ = brace.type(ib1_) == PRM.BRACE_MEMBER_TYPE_X;
    if is_x_
      targets_ = [PRM.BRACE_MEMBER_PAIR_L PRM.BRACE_MEMBER_PAIR_BOTH_L; ...
        PRM.BRACE_MEMBER_PAIR_R PRM.BRACE_MEMBER_PAIR_BOTH_R];
    end
    for ilr_ = 1:2
      irow = irow + 1;
      if ilr_ < 2
        scbbody{irow, ncol} = PRM.CONT_MARKER;
      end
      if ilr_ == 1
        scbbody{irow, 1} = 'Ab';
        scbbody{irow, 2} = sprintf('%.2f', A_cm2_);
        scbbody{irow, 4} = sprintf('%s', 'Λ');
        scbbody{irow, 6} = sprintf('%.1f ', Lambda_);
      else
        scbbody{irow, 1} = 'Ae';
        scbbody{irow, 2} = sprintf('%.2f', Ae_cm2_);
      end

      if is_x_
        ibij_nz_ = ibij_(nz_cols_);
        hit_ = find(brace.pair(ibij_nz_) == targets_(ilr_,1) ...
          | brace.pair(ibij_nz_) == targets_(ilr_,2), 1);
        if isempty(hit_)
          scbbody{irow, 7} = get_pos_label_lr(ilr_, ib1_);
          scbbody{irow, 21} = ' ----';
          continue
        end
        ib_ = ibij_nz_(hit_);
      else
        if ibij_(ilr_) == 0
          continue
        end
        ib_ = ibij_(ilr_);
      end
      im_ = brace.idme(ib_);

      % 引張なし側の判定
      if is_no_tension_side_(ib_)
        scbbody{irow, 7} = get_pos_label(ib_);
        scbbody{irow, 21} = ' ----';
        continue
      end

      % 位置ラベル
      scbbody{irow, 7} = get_pos_label(ib_);

      % L（座屈長）
      scbbody{irow, 8} = sprintf('%.0f', lkx(im_));

      % λ（細長比）
      lambda_ = max(lambday(im_), lambdaz(im_, 1));
      scbbody{irow, 9} = sprintf('%.1f', lambda_);

      % fc 再計算
      [Lfc_, sfc_] = calc_fc_steel(lambda_, Lambda_, F_);

      % 引張のみ判定
      is_tonly_ = is_tension(ib_);

      % Lfc, Lft, sfc, sft
      if ~is_tonly_
        scbbody{irow, 10} = sprintf('%.0f', Lfc_);
        scbbody{irow, 12} = sprintf('%.0f', sfc_);
      end
      scbbody{irow, 11} = sprintf('%.0f', ftn(inm_, 1));
      scbbody{irow, 13} = sprintf('%.0f', ftn(inm_, 2));

      % NL（G+P成分）
      scbbody{irow, 14} = sprintf('%.0f', rs0_all(im_, 1, 1) * 1e-3);

      % NK値
      [nkp_, nkn_] = get_nk(ib_, im_);
      scbbody{irow, 18} = sprintf('%.0f', nkp_);
      scbbody{irow, 19} = sprintf('%.0f', nkn_);

      % ケース・検定比
      [c_ilc_, rt_, rc_] = calc_ratios_steel(im_, A_mm2_, F_, Lfc_, ...
        is_tonly_);
      scbbody{irow, 20} = PRM.load_case_combo_name(c_ilc_);
      scbbody{irow, 21} = sprintf('%.2f ', ceil(rt_ * 100) / 100);
      if ~is_tonly_ && rc_ > 0
        scbbody{irow, 22} = sprintf('%.2f ', ceil(rc_ * 100) / 100);
      end
    end
  end

  function output_member_brb(inb, isb)
  %output_member_brb - 座屈拘束ブレース（BRB）用の出力処理
  %
  %   output_member_brb(inb, isb) は、BRB1呼称分の断面符号行・
  %   空白継続行・ラベル行・Ag/L1データ行を scbbody に追記する。
  %   Lk>Lkmax の場合はブロック末尾に警告714行も追記する。
  %
  %   入力引数:
  %     inb - 呼称ブレースインデックス
  %     isb - 断面リストインデックス
    ibij_ = nominal_brace.idmeb(inb, :);
    nz_cols_ = find(ibij_ > 0);
    ib1_ = ibij_(nz_cols_(1));
    im1_ = brace.idme(ib1_);
    ibrb_ = isb2ibrb(isb);

    % 断面プロパティ
    idsec_ = idm2s(im1_);
    Ag_cm2_ = msprop_A(im1_) * 1e-2;
    F_ = msprop_F(im1_);
    sec_name_ = secb.name{isb};
    Lkmax_ = brblist.Lkmax(ibrb_);
    sym_str_ = brblist.symbol{ibrb_};
    shape_str_ = brblist.shape{ibrb_};
    D_ = brblist.D(ibrb_);
    t_ = brblist.t(ibrb_);

    % 断面符号行
    irow = irow + 1;
    scbbody{irow, 1} = sprintf('[%-6s]', sec_name_);
    scbbody{irow, 7} = 'TYPE';
    type_label_ = get_type_label(ib1_, stype(idsec_));
    brb_type_str_ = format_brb_type_string(sym_str_, shape_str_, D_, t_);
    scbbody{irow, 8} = sprintf('%s [ %s ]', type_label_, brb_type_str_);
    scbbody{irow, ncol} = PRM.CONT_MARKER;

    % 配置・列ラベル行
    irow = irow + 1;
    scbbody{irow, 1} = sprintf('[%s', nominal_brace.floor_name{inb});
    scbbody{irow, 3} = nominal_brace.frame_name{inb, 1};
    scbbody{irow, 4} = nominal_brace.coord_name{inb, 1};
    scbbody{irow, 5} = '-';
    scbbody{irow, 6} = sprintf('%s]', nominal_brace.coord_name{inb, 2});
    scbbody{irow, 8} = 'L';
    scbbody{irow, 9} = 'Lk';
    scbbody{irow, 10} = 'Lft';
    scbbody{irow, 11} = 'sft';
    scbbody{irow, 12} = 'NL';
    scbbody{irow, 13} = 'NS';
    scbbody{irow, 14} = 'NW(正)';
    scbbody{irow, 15} = 'NW(負)';
    scbbody{irow, 16} = 'NK(正)';
    scbbody{irow, 17} = 'NK(負)';
    scbbody{irow, 18} = 'ｹｰｽ';
    scbbody{irow, 19} = sprintf('%s', 'σt/ft');
    scbbody{irow, 20} = sprintf('%s', 'σc/fc');
    scbbody{irow, ncol} = PRM.CONT_MARKER;

    % Ag行・L1行（2行構造）
    % X形: 左→右の固定順、K形: 部材登録順
    is_x_ = brace.type(ib1_) == PRM.BRACE_MEMBER_TYPE_X;
    if is_x_
      targets_ = [PRM.BRACE_MEMBER_PAIR_L PRM.BRACE_MEMBER_PAIR_BOTH_L; ...
        PRM.BRACE_MEMBER_PAIR_R PRM.BRACE_MEMBER_PAIR_BOTH_R];
    end
    for ilr_ = 1:2
      irow = irow + 1;
      if ilr_ < 2
        scbbody{irow, ncol} = PRM.CONT_MARKER;
      end
      if ilr_ == 1
        scbbody{irow, 1} = 'Ag';
        scbbody{irow, 2} = sprintf('%.2f', Ag_cm2_);
        scbbody{irow, 4} = 'Lkmax';
        scbbody{irow, 6} = sprintf('%.0f ', Lkmax_);
      else
        scbbody{irow, 4} = 'L1';
        scbbody{irow, 6} = sprintf('%.0f ', 0);
      end

      if is_x_
        ibij_nz_ = ibij_(nz_cols_);
        hit_ = find(brace.pair(ibij_nz_) == targets_(ilr_,1) ...
          | brace.pair(ibij_nz_) == targets_(ilr_,2), 1);
        if isempty(hit_)
          scbbody{irow, 7} = get_pos_label_lr(ilr_, ib1_);
          scbbody{irow, 18} = ' ----';
          continue
        end
        ib_ = ibij_nz_(hit_);
      else
        if ibij_(ilr_) == 0
          continue
        end
        ib_ = ibij_(ilr_);
      end
      im_ = brace.idme(ib_);

      % 検定比を先に求める。Lk 列の記入要否（圧縮検定の有無）に
      % rc_ を用いるため、L/Lk 記入より前に算定する。
      [c_ilc_, rt_, rc_] = calc_ratios_brb(im_, Ag_cm2_ * 1e2, F_);

      % 位置ラベル
      scbbody{irow, 7} = get_pos_label(ib_);

      % L（内法長さ）。Lk（座屈長）は圧縮検定が生じる側のみ記入
      % する。SS7 は引張のみ・軸力なし側の Lk を空欄とする。
      % Lk>Lkmax は SS7 同様 * を付す。
      scbbody{irow, 8} = sprintf('%.0f', lm(im_));
      if rc_ > 0
        if lkx(im_) > Lkmax_
          lk_str_ = sprintf('%.0f*', lkx(im_));
        else
          lk_str_ = sprintf('%.0f', lkx(im_));
        end
        scbbody{irow, 9} = lk_str_;
      end

      % Lft, sft（許容引張応力度。BRB は F/1.5 / F）
      scbbody{irow, 10} = sprintf('%.0f', F_ / 1.5);
      scbbody{irow, 11} = sprintf('%.0f', F_);

      % NL（G+P成分）。SS7 は応力を絶対値方向へ切り上げ表示
      nl_ = ceil_abs(rs0_all(im_, 1, 1) * 1e-3, 0);
      scbbody{irow, 12} = sprintf('%.0f', nl_);

      % NK値。SS7 は応力を絶対値方向へ切り上げ表示
      [nkp_, nkn_] = get_nk(ib_, im_);
      scbbody{irow, 16} = sprintf('%.0f', ceil_abs(nkp_, 0));
      scbbody{irow, 17} = sprintf('%.0f', ceil_abs(nkn_, 0));

      % ケース＝決定ケース。σt/ft・σc/fc は引張側・圧縮側の
      % 全ケース独立最大（SS7 出力編 7.4.5）
      scbbody{irow, 18} = PRM.load_case_combo_name(c_ilc_);
      if rt_ > 0
        scbbody{irow, 19} = sprintf('%.2f ', ceil(rt_ * 100) / 100);
      end
      if rc_ > 0
        scbbody{irow, 20} = sprintf('%.2f ', ceil(rc_ * 100) / 100);
      end
    end

    % 警告714: 座屈拘束ブレースの Lk>Lkmax（存在斜材で判定）
    ims_ = brace.idme(ibij_(nz_cols_));
    over_lk_ = any(lkx(ims_) > Lkmax_);
    if over_lk_
      % 直前行（L1行）を継続行化し、警告行をブロック終端にする
      scbbody{irow, ncol} = PRM.CONT_MARKER;
      irow = irow + 1;
      scbbody{irow, 1} = ['警告  714： 座屈拘束ブレースで座屈' ...
        '長さ（Lk）が限界座屈長さ（Lkmax）を超えています。'];
    end
  end

  function [c_ilc, max_rt, max_rc] = calc_ratios_brb(im, A, F)
  %calc_ratios_brb - BRBの検定比計算
  %
  %   [c_ilc, max_rt, max_rc] = calc_ratios_brb(im, A, F) は、
  %   全荷重ケースについて引張・圧縮の検定比を求め、決定ケース
  %   番号と引張側・圧縮側それぞれの最大検定比を返す。BRBは引張・
  %   圧縮ともに ft（長期 F/1.5、短期 F）を許容応力度として用いる。
  %
  %   入力引数:
  %     im - 部材インデックス
  %     A  - 断面積 [mm^2]
  %     F  - F値 [N/mm^2]
  %
  %   出力引数:
  %     c_ilc  - 最大検定比となる荷重ケース番号
  %     max_rt - 全ケースの引張検定比最大値
  %     max_rc - 全ケースの圧縮検定比最大値
    nlc_ = size(rs_all, 3);
    rt_ = zeros(1, nlc_);
    rc_ = zeros(1, nlc_);
    for ilc_ = 1:nlc_
      N_ = rs_all(im, 1, ilc_);
      if ilc_ == 1
        ft_ = F / 1.5;
      else
        ft_ = F;
      end
      if N_ < 0
        rt_(ilc_) = abs(N_) / (A * ft_);
      else
        rc_(ilc_) = N_ / (A * ft_);
      end
    end
    overall_ = max(rt_, rc_);
    tiebreak_ = zeros(1, nlc_);
    tiebreak_(PRM.LT) = eps;
    tiebreak_(PRM.EXP) = eps;
    tiebreak_(PRM.EYP) = eps;
    [~, c_ilc] = max(overall_ + tiebreak_);
    max_rt = max(rt_);
    max_rc = max(rc_);
  end

  function str = format_brb_type_string(symbol, shape, D, t)
  %format_brb_type_string - BRB TYPE 行の型文字列を生成
  %
  %   str = format_brb_type_string(symbol, shape, D, t) は、
  %   製品記号・型式・座屈拘束鋼管寸法を SS7 形式で連結した
  %   文字列を返す。
  %
  %   入力引数:
  %     symbol - 製品記号文字列
  %     shape  - 型式名（'-'/'+' 等の記号）
  %     D      - 座屈拘束鋼管の外径 [mm]
  %     t      - 座屈拘束鋼管の板厚 [mm]
  %
  %   出力引数:
  %     str - 連結後の文字列
    str = sprintf('製品記号：%s (%s型)  座屈拘束鋼管：φ－%.1f×%4.1f', ...
      symbol, shape, D, t);
  end

  function flag = is_no_tension_side_(ib_)
  %is_no_tension_side_ - 引張なし側の判定
  %
  %   flag = is_no_tension_side_(ib_) は、当該ブレース部材の
  %   全荷重ケースで軸力が0なら true を返す。
  %
  %   入力引数:
  %     ib_ - ブレース部材インデックス
  %
  %   出力引数:
  %     flag - 引張なし側であれば true
    im_ = brace.idme(ib_);
    flag = all(rs_all(im_, 1, :) == 0);
  end

  function label_ = get_type_label(ib_, stype_)
  %get_type_label - TYPE行のラベル生成
  %
  %   label_ = get_type_label(ib_, stype_) は、部材形状（X/K上/
  %   K下）と引張・圧縮属性を組合せたラベル文字列を返す。
  %
  %   入力引数:
  %     ib_    - ブレース部材インデックス
  %     stype_ - 断面種別（PRM定数）
  %
  %   出力引数:
  %     label_ - TYPE行に表示するラベル文字列
    if stype_ == PRM.TB
      tc_str_ = '引張のみ';
    elseif is_tension(ib_)
      tc_str_ = '引張のみ';
    else
      tc_str_ = '引張・圧縮有効';
    end
    switch brace.type(ib_)
      case PRM.BRACE_MEMBER_TYPE_X
        if brace.idpair(ib_) ~= ib_
          % BOTH展開によるペアあり: X形（両方）
          label_ = sprintf('X形(%s)', tc_str_);
        elseif brace.pair(ib_) == PRM.BRACE_MEMBER_PAIR_L
          label_ = sprintf('X形(／)(%s)', tc_str_);
        else
          label_ = sprintf('X形(＼)(%s)', tc_str_);
        end
      case PRM.BRACE_MEMBER_TYPE_K_UPPER
        label_ = sprintf('K上形(%s)', tc_str_);
      case PRM.BRACE_MEMBER_TYPE_K_LOWER
        label_ = sprintf('K下形(%s)', tc_str_);
      otherwise
        label_ = sprintf('(%s)', tc_str_);
    end
  end

  function label_ = get_pos_label(ib_)
  %get_pos_label - 位置ラベル生成（pair属性ベース）
  %
  %   label_ = get_pos_label(ib_) は、ブレース部材の pair 属性と
  %   形状種別から位置ラベル（左下り/右下り/左側/右側）を返す。
  %   K下形は左右反転（左下がり=右側、右下がり=左側）する。
  %
  %   入力引数:
  %     ib_ - ブレース部材インデックス
  %
  %   出力引数:
  %     label_ - 位置ラベル文字列
    pair_left_ = [PRM.BRACE_MEMBER_PAIR_L, PRM.BRACE_MEMBER_PAIR_BOTH_L];
    switch brace.type(ib_)
      case PRM.BRACE_MEMBER_TYPE_X
        if ismember(brace.pair(ib_), pair_left_)
          label_ = '左下り';
        else
          label_ = '右下り';
        end
      case PRM.BRACE_MEMBER_TYPE_K_UPPER
        if ismember(brace.pair(ib_), pair_left_)
          label_ = '左側';
        else
          label_ = '右側';
        end
      case PRM.BRACE_MEMBER_TYPE_K_LOWER
        % K下形: 左下がり=右側、右下がり=左側
        if ismember(brace.pair(ib_), pair_left_)
          label_ = '右側';
        else
          label_ = '左側';
        end
      otherwise
        label_ = '';
    end
  end

  function label_ = get_pos_label_lr(ilr_, ib_)
  %get_pos_label_lr - 左右番号から位置ラベル生成
  %
  %   label_ = get_pos_label_lr(ilr_, ib_) は、左右番号（1/2）と
  %   形状種別から位置ラベルを返す。X形対の片側欠落時など、
  %   pair属性が参照できない場合の代替として使用する。
  %
  %   入力引数:
  %     ilr_ - 左右番号（1=左、2=右）
  %     ib_  - 参照部材インデックス（形状判定用）
  %
  %   出力引数:
  %     label_ - 位置ラベル文字列
    switch brace.type(ib_)
      case PRM.BRACE_MEMBER_TYPE_X
        if ilr_ == 1, label_ = '左下り';
        else,         label_ = '右下り'; end
      case {PRM.BRACE_MEMBER_TYPE_K_UPPER, PRM.BRACE_MEMBER_TYPE_K_LOWER}
        if ilr_ == 1, label_ = '左側';
        else,         label_ = '右側'; end
      otherwise
        label_ = '';
    end
  end

  function [nkp, nkn] = get_nk(ib_, im_)
  %get_nk - 地震時軸力の取得（両方向最大）
  %
  %   [nkp, nkn] = get_nk(ib_, im_) は、X/Y方向の正側・負側に
  %   ついてそれぞれ検定比最大のケースを選び、当該ケースの
  %   軸力を kN 単位で返す。
  %
  %   入力引数:
  %     ib_ - ブレース部材インデックス（検定比参照用）
  %     im_ - 全体部材インデックス（軸力参照用）
  %
  %   出力引数:
  %     nkp - 正側ケース軸力 [kN]
  %     nkn - 負側ケース軸力 [kN]
    bp_ = bnij(ib_, [PRM.EXP PRM.EYP]);
    [~, idp_] = max(bp_);
    idc_pos_ = [PRM.EXP PRM.EYP];
    nkp = rs_all(im_, 1, idc_pos_(idp_)) * 1e-3;

    bn_ = bnij(ib_, [PRM.EXN PRM.EYN]);
    [~, idn_] = max(bn_);
    idc_neg_ = [PRM.EXN PRM.EYN];
    nkn = rs_all(im_, 1, idc_neg_(idn_)) * 1e-3;
  end

  function name = format_shape_name(stype_, dim_)
  %format_shape_name - 鋼材ブレースの断面形状名生成
  %
  %   name = format_shape_name(stype_, dim_) は、断面種別と寸法
  %   配列から SS7 形式の形状名（H-../□-../○-..）を生成する。
  %
  %   入力引数:
  %     stype_ - 断面種別（PRM.BWFS/BHSS/BHSR）
  %     dim_   - 寸法行ベクトル（secdim の1行）
  %
  %   出力引数:
  %     name - 形状名文字列
    v = @(x) sprintf('%g', x);
    switch stype_
      case PRM.BWFS
        name = sprintf('H-%s*%s*%s*%s*%s', v(dim_(1)), ...
          v(dim_(2)), v(dim_(3)), v(dim_(4)), v(dim_(5)));
      case PRM.BHSS
        name = sprintf('□-%s*%s*%s*%s', v(dim_(1)), v(dim_(1)), ...
          v(dim_(2)), v(dim_(3)));
      case PRM.BHSR
        name = sprintf('○-%s*%s', v(dim_(1)), v(dim_(2)));
      otherwise
        name = '';
    end
  end

  function [Lfc, sfc] = calc_fc_steel(lambda, Lambda, F)
  %calc_fc_steel - 鋼材ブレースの許容圧縮応力度を算定
  %
  %   [Lfc, sfc] = calc_fc_steel(lambda, Lambda, F) は、細長比
  %   と限界細長比から長期・短期の許容圧縮応力度を計算する。
  %
  %   入力引数:
  %     lambda - 細長比
  %     Lambda - 限界細長比
  %     F      - F値 [N/mm^2]
  %
  %   出力引数:
  %     Lfc - 長期許容圧縮応力度 [N/mm^2]
  %     sfc - 短期許容圧縮応力度 [N/mm^2]
    ratio = lambda / Lambda;
    if ratio <= 1.0
      nu = 3/2 + 2/3 * ratio^2;
      Lfc = F / nu * (1.0 - 0.4 * ratio^2);
    else
      Lfc = 0.277 * F / ratio^2;
    end
    sfc = Lfc * 1.5;
  end

  function [c_ilc, max_rt, max_rc] = calc_ratios_steel( ...
    im_, A_, F_, Lfc_, is_tonly_)
  %calc_ratios_steel - 鋼材ブレースの検定比計算
  %
  %   [c_ilc, max_rt, max_rc] = calc_ratios_steel(im_, A_, F_, ...
  %     Lfc_, is_tonly_) は、全荷重ケースの引張・圧縮検定比を
  %   求め、最大値と最大ケース番号を返す。引張のみ判定なら
  %   圧縮側はゼロのまま返す。
  %
  %   入力引数:
  %     im_       - 全体部材インデックス
  %     A_        - 断面積 [mm^2]
  %     F_        - F値 [N/mm^2]
  %     Lfc_      - 長期許容圧縮応力度 [N/mm^2]
  %     is_tonly_ - 引張のみ判定フラグ
  %
  %   出力引数:
  %     c_ilc  - 最大検定比となる荷重ケース番号
  %     max_rt - 全ケースの引張検定比最大値
  %     max_rc - 全ケースの圧縮検定比最大値
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