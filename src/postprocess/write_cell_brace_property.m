function [bphead, bpbody] = write_cell_brace_property(com, result)
%write_cell_brace_property - ブレース断面セル配列を生成
%
%   [bphead, bpbody] = write_cell_brace_property(com, result)
%   は、ブレース断面の諸元をセル配列として生成する。
%
%   入力引数:
%     com    - 共通オブジェクト (struct)
%     result - 結果構造体 (struct)
%
%   出力引数:
%     bphead - ヘッダー行セル配列 [3x20 cell]
%     bpbody - 本体セル配列 [nnb x 20 cell]

% 定数・共通配列
nb = com.nmeb;
nstory = com.nstory;
nblx = com.nblx;
nbly = com.nbly;
brace = com.member.brace;
secb = com.section.brace;
msprop = result.msprop;
Em = msprop.E;
lm = result.lm;
lkx = result.lkx;
is_tension = result.state.tb.is_tension;

% 鋼材ブレースの λe 事前計算（座屈長ベース）
lam_e = nan(size(lm));
for ib_ = 1:nb
  idm_ = brace.idme(ib_);
  idsb_ = brace.idsecb(ib_);
  stype_ = secb.type(idsb_);
  if stype_ == PRM.BWFS || stype_ == PRM.BHSS || stype_ == PRM.BHSR
    iy_ = sqrt(msprop.Iy(idm_) / msprop.A(idm_));
    iz_ = sqrt(msprop.Iz(idm_) / msprop.A(idm_));
    lam_e(idm_) = lkx(idm_,1) / min(iy_, iz_);
  end
end

% ヘッダー行
bphead = cell(3,20);
bphead(1,1:5) = {'階', 'ﾌﾚｰﾑ', '軸－軸', '', '符号'};
bphead(1,6:10) = {'タイプ','E', 'Ao', '左下り',''};
bphead(1,15) = {'右下り'};
bphead(2,9:10) = {'φA','A'};
bphead(2,11:15) = {'引圧','λe','座屈長','部材長','φA'};
bphead(2,16:20) = {'A','引圧','λe','座屈長','部材長'};
bphead(3,6:10) = {'','kN/mm2','cm2','','cm2'};
bphead(3,11:15) = {'','','mm','mm',''};
bphead(3,16) = {'cm2'};

% 本体作成（nominal_braceベースでループ）
nominal_brace = com.nominal.brace;
nnb = com.num.nominal_brace;
ids_story = nominal_brace.idstory;
idx_nom = nominal_brace.idx;
idy_nom = nominal_brace.idy;
idir_nom = nominal_brace.idir;

bpbody = cell(nnb, 20);
irow = 0;

for ist = nstory:-1:1
  % X通りブレース（Y方向→X方向の順で走査）
  for iy = 1:nbly
    for ix = 1:nblx
      inb_list = find(ids_story == ist & idx_nom(:,1) == ix ...
        & idy_nom(:,1) == iy & idir_nom == PRM.X);
      for inb = inb_list'
        add_row(inb);
      end
    end
  end
  % Y通りブレース（X方向→Y方向の順で走査）
  for ix = 1:nblx
    for iy = 1:nbly
      inb_list = find(ids_story == ist & idx_nom(:,1) == ix ...
        & idy_nom(:,1) == iy & idir_nom == PRM.Y);
      for inb = inb_list'
        add_row(inb);
      end
    end
  end
end

bpbody = bpbody(1:irow,:);

return

  function add_row(inb)
    ibij = nominal_brace.idmeb(inb,:);
    nz_cols = find(ibij > 0);
    npair = length(nz_cols);

    for iter = 1:npair
      ij = nz_cols(iter);
      ib = ibij(ij);
      idm = brace.idme(ib);
      idsb = brace.idsecb(ib);

      if iter == 1
        irow = irow + 1;
        bpbody{irow,1} = nominal_brace.floor_name{inb};
        bpbody{irow,2} = nominal_brace.frame_name{inb,1};
        bpbody(irow,3:4) = nominal_brace.coord_name(inb,1:2);
        bpbody{irow,5} = secb.name{idsb};

        % タイプ名
        switch brace.type(ib)
          case PRM.BRACE_MEMBER_TYPE_X
            if npair == 2
              bpbody{irow,6} = 'Ｘ';
            elseif brace.pair(ib) == PRM.BRACE_MEMBER_PAIR_L
              bpbody{irow,6} = '／';
            else
              bpbody{irow,6} = '＼';
            end
          case PRM.BRACE_MEMBER_TYPE_K_UPPER
            bpbody{irow,6} = 'K上';
          case PRM.BRACE_MEMBER_TYPE_K_LOWER
            bpbody{irow,6} = 'K下';
        end

        % E, Ao
        bpbody{irow,7} = Em(idm) * 1.d-3;
        bpbody{irow,8} = sprintf('%.2f', msprop.A(idm) * 1.d-2);
      end

      % 左下り/右下り列の振り分け
      switch brace.type(ib)
        case PRM.BRACE_MEMBER_TYPE_X
          if ismember(brace.pair(ib), [PRM.BRACE_MEMBER_PAIR_L, ...
              PRM.BRACE_MEMBER_PAIR_BOTH_L])
            ipos = 1;
          else
            ipos = 2;
          end
        case {PRM.BRACE_MEMBER_TYPE_K_UPPER, PRM.BRACE_MEMBER_TYPE_K_LOWER}
          ipos = ij;
      end

      if ipos == 1
        write_left_columns(ib, idm, idsb);
      else
        write_right_columns(ib, idm, idsb);
      end
    end
  end

  function write_left_columns(ib_, idm_, idsb_)
    stype_ = secb.type(idsb_);
    bpbody{irow,9} = sprintf('%.3f', 1);
    bpbody{irow,10} = sprintf('%.2f', msprop.A(idm_)*1.d-2);
    if stype_ == PRM.TB
      bpbody{irow,11} = '引張';
      bpbody{irow,12} = '-1.0';
    elseif stype_ == PRM.BRB
      bpbody{irow,11} = '引圧';
      % λe 空白（座屈を考慮しない）
    elseif is_tension(ib_)
      bpbody{irow,11} = '引張';
      bpbody{irow,12} = sprintf('%.1f', lam_e(idm_));
    else
      bpbody{irow,11} = '引圧';
      bpbody{irow,12} = sprintf('%.1f', lam_e(idm_));
    end
    bpbody{irow,13} = sprintf('%.0f', lkx(idm_,1));
    bpbody{irow,14} = sprintf('%.0f', lm(idm_));
  end

  function write_right_columns(ib_, idm_, idsb_)
    stype_ = secb.type(idsb_);
    bpbody{irow,15} = sprintf('%.3f', 1);
    bpbody{irow,16} = sprintf('%.2f', msprop.A(idm_)*1.d-2);
    if stype_ == PRM.TB
      bpbody{irow,17} = '引張';
      bpbody{irow,18} = '-1.0';
    elseif stype_ == PRM.BRB
      bpbody{irow,17} = '引圧';
      % λe 空白（座屈を考慮しない）
    elseif is_tension(ib_)
      bpbody{irow,17} = '引張';
      bpbody{irow,18} = sprintf('%.1f', lam_e(idm_));
    else
      bpbody{irow,17} = '引圧';
      bpbody{irow,18} = sprintf('%.1f', lam_e(idm_));
    end
    bpbody{irow,19} = sprintf('%.0f', lkx(idm_,1));
    bpbody{irow,20} = sprintf('%.0f', lm(idm_));
  end
end
