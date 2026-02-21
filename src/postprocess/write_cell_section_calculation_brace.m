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
rs_all = result.rs;
rs0_all = result.rs0;
lm = result.lm;
nlc = com.nlc;
nstory = com.nstory;
nblx = com.nblx;
nbly = com.nbly;
nnb = com.num.nominal_brace;

% 早期リターン
if com.nsecb == 0 || isempty(rs_all)
  scbbody = cell(0, ncol);
  return
end

% TB断面の検出（グローバル断面タイプ）
isTB_global = (stype == PRM.TB);
if ~any(isTB_global)
  scbbody = cell(0, ncol);
  return
end

% TB断面のリスト情報取得（HTB, GP等）
tblist = getListRecord( ...
  secmgr, secdim(isTB_global, end-1:end));

% ブレース断面インデックス（TB のみ）
idsb_tb = find( ...
  secb.tctype == PRM.BRACE_TENSION);
ntb = length(idsb_tb);

% 部材→グローバル断面マッピング
idm2s = com.member.property.idsec;

% 出力バッファ確保
mb = 5;
scbbody = cell(mb * nnb + ntb, ncol);
irow = 0;

% TB断面ごとにループ
for itb = 1:ntb
  isb = idsb_tb(itb);

  % 断面の代表部材から寸法を取得
  ib_first_ = find(brace.idsecb == isb, 1);
  if isempty(ib_first_)
    continue
  end
  im_first_ = brace.idme(ib_first_);
  idsec_ = idm2s(im_first_);
  A_cm2 = secdim(idsec_, 2) * 1e-2;
  Ae_cm2 = secdim(idsec_, 3) * 1e-2;
  Ta_kN = secdim(idsec_, 4);
  sec_name = secb.name{isb};
  type_name = tblist.type{itb};
  HTB_str = tblist.HTB{itb};
  GP_str = tblist.GP{itb};

  % 鉄骨セクションヘッダ
  irow = irow + 1;
  scbbody{irow, 1} = ...
    ' 鉄骨: [ ---      ]  Ｆ値   ---';

  % 階・方向・通りの順で走査
  for ist = nstory:-1:1
    for idir = [PRM.X PRM.Y]
      if idir == PRM.X
        for iy = 1:nbly
          for ix = 1:nblx
            scan_loc(ist, ix, iy, idir);
          end
        end
      else
        for ix = 1:nblx
          for iy = 1:nbly
            scan_loc(ist, ix, iy, idir);
          end
        end
      end
    end
  end
end
scbbody = scbbody(1:irow, :);

return

  function scan_loc(ist_, ix_, iy_, idir_)
    inb_list_ = find( ...
      nominal_brace.idstory == ist_ ...
      & nominal_brace.idx(:,1) == ix_ ...
      & nominal_brace.idy(:,1) == iy_ ...
      & nominal_brace.idir == idir_);
    for jj_ = 1:length(inb_list_)
      inb_ = inb_list_(jj_);
      ib1_ = nominal_brace.idmeb(inb_, 1);
      if brace.idsecb(ib1_) ~= isb
        continue
      end
      output_member(inb_);
    end
  end

  function output_member(inb_)
    ibij_ = nominal_brace.idmeb(inb_, :);
    npair_ = nnz(ibij_);
    ib1_ = ibij_(1);
    idir_ = nominal_brace.idir(inb_);

    % 断面符号行
    irow = irow + 1;
    scbbody{irow, 1} = ...
      sprintf('[%s]', sec_name);
    scbbody{irow, 7} = 'TYPE';
    scbbody{irow, 8} = sprintf( ...
      '%s [ %s  %s  %s ]', ...
      get_type_label(ib1_), ...
      type_name, HTB_str, GP_str);

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
    scbbody{irow, 19} = 'ケース';
    scbbody{irow, 20} = 'Nt/Nat';
    scbbody{irow, 21} = 'Nc/Nac';

    % Ab・Ae データ行
    for ij_ = 1:max(npair_, 2)
      irow = irow + 1;
      if ij_ == 1
        scbbody{irow, 1} = 'Ab';
        scbbody{irow, 2} = ...
          sprintf('%.2f', A_cm2);
      else
        scbbody{irow, 1} = 'Ae';
        scbbody{irow, 2} = ...
          sprintf('%.2f', Ae_cm2);
      end

      if ij_ > npair_
        continue
      end
      ib_ = ibij_(ij_);
      im_ = brace.idme(ib_);

      % 左下り/右下り
      scbbody{irow, 7} = ...
        get_pos_label(ib_);

      % 部材長
      scbbody{irow, 8} = ...
        sprintf('%.0f', lm(im_));

      % LNat・sNat（LNac・sNacはTBでは空白）
      scbbody{irow, 10} = ...
        sprintf('%.0f', Ta_kN / 1.5);
      scbbody{irow, 12} = ...
        sprintf('%.0f', Ta_kN);

      % NL（G+P成分）
      scbbody{irow, 13} = sprintf( ...
        '%.0f', rs0_all(im_, 1, 1) * 1e-3);

      % 最大検定比のケースを特定
      [c_ilc_, ratio_] = ...
        find_critical(im_);

      % NK値（地震成分）
      [nkp_, nkn_] = ...
        get_nk(im_, idir_);
      scbbody{irow, 17} = ...
        sprintf('%.0f', nkp_);
      scbbody{irow, 18} = ...
        sprintf('%.0f', nkn_);

      % ケース名・検定比
      scbbody{irow, 19} = ...
        PRM.load_case_name(c_ilc_);
      if Ta_kN > 0
        scbbody{irow, 20} = ...
          sprintf('%.2f', ratio_);
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

  function [c_ilc, ratio] = find_critical(im_)
  %find_critical - 最大検定比の荷重ケースを特定
    max_N_ = 0;
    c_ilc = 1;
    for ilc_ = 2:nlc
      N_abs_ = abs(rs_all(im_, 1, ilc_));
      if N_abs_ > max_N_
        max_N_ = N_abs_;
        c_ilc = ilc_;
      end
    end
    if Ta_kN > 0
      ratio = max_N_ * 1e-3 / Ta_kN;
    else
      ratio = 0;
    end
  end

  function [nkp, nkn] = get_nk(im_, idir_)
  %get_nk - 地震成分の取得（主方向のみ）
    if idir_ == PRM.X
      nkp = rs0_all(im_, 1, 2) * 1e-3;
      nkn = rs0_all(im_, 1, 3) * 1e-3;
    else
      nkp = rs0_all(im_, 1, 4) * 1e-3;
      nkn = rs0_all(im_, 1, 5) * 1e-3;
    end
  end

end
