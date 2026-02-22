function scbbody = write_cell_section_calculation_brace( ...
  com, result)
%write_cell_section_calculation_brace - 鉛直ブレース断面算定表
%
%   scbbody = write_cell_section_calculation_brace( ...
%     com, result) は、
%   引張ブレースの断面算定表をセル配列で返す。
%   SS7の鉛直ブレース断面算定表に準拠した形式で出力する。
%
%   入力引数:
%     com    - 共通オブジェクト
%     result - 結果構造体
%
%   出力引数:
%     scbbody - データセル配列 [nrow×21]

ncol = 21;
secb = com.section.brace;
brace = com.member.brace;
nominal_brace = com.nominal.brace;
stype = com.section.property.type;
secmgr = com.secmgr;
secdim = result.secdim;
rs0_all = result.rs0;
rs_all = result.rs;
lm = result.lm;
bnij_member = result.bnij_member;
nstory = com.nstory;
nblx = com.nblx;
nbly = com.nbly;
nnb = com.num.nominal_brace;

% 部材→グローバル断面マッピング
idm2s = com.member.property.idsec;

% 早期リターン
if com.nsecb == 0 || isempty(rs0_all)
  scbbody = cell(0, ncol);
  return
end

% TB断面の検出
if ~any(stype == PRM.TB)
  scbbody = cell(0, ncol);
  return
end

% TB断面のリスト情報取得（HTB, GP等）
tblist = getListRecord( ...
  secmgr, secdim(stype == PRM.TB, :));

% ブレース断面インデックス（TB のみ）
idsb_tb = find( ...
  secb.tctype == PRM.BRACE_TENSION);
ntb = length(idsb_tb);

% isb → itb マッピング
isb2itb = zeros(max(idsb_tb), 1);
for itb = 1:ntb
  isb2itb(idsb_tb(itb)) = itb;
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
  header_done = false;

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
        if secb.tctype(isb_) ~= PRM.BRACE_TENSION
          continue
        end
        if ~header_done
          irow = irow + 1;
          scbbody{irow, 1} = ...
            ' 鉄骨： [ ---      ]  Ｆ値   ---';
          header_done = true;
        end
        output_member(inb, isb_);
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
        if secb.tctype(isb_) ~= PRM.BRACE_TENSION
          continue
        end
        if ~header_done
          irow = irow + 1;
          scbbody{irow, 1} = ...
            ' 鉄骨： [ ---      ]  Ｆ値   ---';
          header_done = true;
        end
        output_member(inb, isb_);
      end
    end
  end
end
scbbody = scbbody(1:irow, :);

return

  function output_member(inb_, isb_)
    ibij_ = nominal_brace.idmeb(inb_, :);
    npair_ = nnz(ibij_);
    ib1_ = ibij_(1);
    im1_ = brace.idme(ib1_);
    itb_ = isb2itb(isb_);

    % 断面プロパティ（部材から直接取得）
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
    scbbody{irow, 1} = sprintf('[%-6s]', sec_name_);
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
    for ij_ = 1:max(npair_, 2)
      irow = irow + 1;
      if ij_ == 1
        scbbody{irow, 1} = 'Ab';
        scbbody{irow, 2} = ...
          sprintf('%.2f', A_cm2_);
      else
        scbbody{irow, 1} = 'Ae';
        scbbody{irow, 2} = ...
          sprintf('%.2f', Ae_cm2_);
      end

      if ij_ > npair_
        continue
      end
      ib_ = ibij_(ij_);
      im_ = brace.idme(ib_);

      % 左下り/右下り
      scbbody{irow, 7} = get_pos_label(ib_);

      % 部材長
      scbbody{irow, 8} = ...
        sprintf('%.0f', lm(im_));

      % LNat・sNat（LNac・sNacはTBでは空白）
      scbbody{irow, 10} = ...
        sprintf('%.0f', Ta_kN_ / 1.5);
      scbbody{irow, 12} = ...
        sprintf('%.0f', Ta_kN_);

      % NL（G+P成分）
      scbbody{irow, 13} = sprintf( ...
        '%.0f', rs0_all(im_, 1, 1) * 1e-3);

      % 最大検定比のケース（tiebreak付き）
      tiebreak_ = [eps eps 0 eps 0];
      [~, c_ilc_] = max( ...
        bnij_member(im_, :) + tiebreak_);
      ratio_ = bnij_member(im_, c_ilc_) + 1;

      % NK値（G+P+K、両方向から最大選択）
      [nkp_, nkn_] = get_nk(im_);
      scbbody{irow, 17} = ...
        sprintf('%.0f', nkp_);
      scbbody{irow, 18} = ...
        sprintf('%.0f', nkn_);

      % ケース名・検定比
      scbbody{irow, 19} = ...
        PRM.load_case_name(c_ilc_);
      if Ta_kN_ > 0
        scbbody{irow, 20} = ...
          sprintf('%.2f', ceil(ratio_ * 100) / 100);
      end
    end
  end

  function label_ = get_type_label(ib_)
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

  function label_ = get_pos_label(ib_)
    switch brace.type(ib_)
      case PRM.BRACE_MEMBER_TYPE_X
        if ismember(brace.pair(ib_), ...
            [PRM.BRACE_MEMBER_PAIR_L, ...
             PRM.BRACE_MEMBER_PAIR_BOTH_L])
          label_ = '左下り';
        else
          label_ = '右下り';
        end
      otherwise
        label_ = '';
    end
  end

  function [nkp, nkn] = get_nk(im_)
  %get_nk - 地震時軸力の取得（G+P+K、両方向最大）
    % NK(正): L+Ex, L+Ey の最大検定比ケース
    bp_ = bnij_member( ...
      im_, [PRM.EXP PRM.EYP]);
    [~, idp_] = max(bp_);
    idc_pos_ = [PRM.EXP PRM.EYP];
    nkp = rs_all( ...
      im_, 1, idc_pos_(idp_)) * 1e-3;

    % NK(負): L-Ex, L-Ey の最大検定比ケース
    bn_ = bnij_member( ...
      im_, [PRM.EXN PRM.EYN]);
    [~, idn_] = max(bn_);
    idc_neg_ = [PRM.EXN PRM.EYN];
    nkn = rs_all( ...
      im_, 1, idc_neg_(idn_)) * 1e-3;
  end

end
