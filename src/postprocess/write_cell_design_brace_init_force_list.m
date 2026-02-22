function [head, body] = ...
  write_cell_design_brace_init_force_list(com, result)
%write_cell_design_brace_init_force_list - 鉛直ブレース設計応力表(組合せ前)
%
%   [head, body] = ...
%     write_cell_design_brace_init_force_list(com, result) は、
%   荷重組合せ前の各ケース個別軸力をセル配列で返す。
%
%   入力引数:
%     com - 共通オブジェクト
%     result - 結果構造体（rs0 を使用）
%
%   出力引数:
%     head - ヘッダセル配列 [3×9]
%     body - データセル配列 [nrow×9]

nominal_brace = com.nominal.brace;
brace = com.member.brace;
secb = com.section.brace;
rs0_all = result.rs0;
nlc = size(rs0_all, 3);

% ヘッダ
head = cell(3, 9);
head(1, 1:8) = { ...
  '階', 'ﾌﾚｰﾑ', '軸－軸', '', ...
  '符号', 'ケース', 'タイプ', '軸力'};
head(2, 8:9) = {'左下り', '右下り'};
head(3, 8:9) = {'kN', 'kN'};

nnb = com.num.nominal_brace;
body = cell(0, 9);
if nnb == 0 || isempty(rs0_all)
  return
end

nstory = com.nstory;
nblx = com.nblx;
nbly = com.nbly;
rows = cell(nnb * nlc, 9);
irow = 0;

ids_story = nominal_brace.idstory;
idx_nom = nominal_brace.idx;
idy_nom = nominal_brace.idy;
idir_nom = nominal_brace.idir;

for ist = nstory:-1:1
  % X通りブレース
  for iy = 1:nbly
    for ix = 1:nblx
      inb_list = find( ...
        ids_story == ist & idx_nom(:,1) == ix ...
        & idy_nom(:,1) == iy ...
        & idir_nom == PRM.X);
      for inb = inb_list'
        add_row(inb);
      end
    end
  end
  % Y通りブレース
  for ix = 1:nblx
    for iy = 1:nbly
      inb_list = find( ...
        ids_story == ist & idx_nom(:,1) == ix ...
        & idy_nom(:,1) == iy ...
        & idir_nom == PRM.Y);
      for inb = inb_list'
        add_row(inb);
      end
    end
  end
end

if irow == 0
  body = cell(0, 9);
else
  body = rows(1:irow, :);
end

return

  function add_row(inb)
    ibij = nominal_brace.idmeb(inb, :);
    % 左右の部材番号とiposを先に決定
    im_pair = zeros(1, 2);
    ipos_pair = zeros(1, 2);
    npair = nnz(ibij);
    for ij_ = 1:npair
      ib_ = ibij(ij_);
      im_pair(ij_) = brace.idme(ib_);
      switch brace.type(ib_)
        case PRM.BRACE_MEMBER_TYPE_X
          if ismember(brace.pair(ib_), ...
              [PRM.BRACE_MEMBER_PAIR_L, ...
               PRM.BRACE_MEMBER_PAIR_BOTH_L])
            ipos_pair(ij_) = 1;
          else
            ipos_pair(ij_) = 2;
          end
          if ismember(brace.pair(ib_), ...
              [PRM.BRACE_MEMBER_PAIR_BOTH_L, ...
               PRM.BRACE_MEMBER_PAIR_BOTH_R])
            type_label_ = 'Ｘ';
          elseif ipos_pair(ij_) == 1
            type_label_ = '／';
          else
            type_label_ = '＼';
          end
        case PRM.BRACE_MEMBER_TYPE_K_UPPER
          type_label_ = 'K上';
          ipos_pair(ij_) = ij_;
        case PRM.BRACE_MEMBER_TYPE_K_LOWER
          type_label_ = 'K下';
          ipos_pair(ij_) = ij_;
      end
    end

    % 各荷重ケースの軸力を出力
    for ilc = 1:nlc
      irow = irow + 1;
      if ilc == 1
        rows{irow, 1} = ...
          nominal_brace.floor_name{inb};
        rows{irow, 2} = ...
          nominal_brace.frame_name{inb, 1};
        rows{irow, 3} = ...
          nominal_brace.coord_name{inb, 1};
        rows{irow, 4} = ...
          nominal_brace.coord_name{inb, 2};
        isb = brace.idsecb(ibij(1));
        rows{irow, 5} = secb.name{isb};
        rows{irow, 7} = type_label_;
      end
      rows{irow, 6} = PRM.load_case_short_name(ilc);
      for ij_ = 1:npair
        icol = 7 + ipos_pair(ij_);
        rows{irow, icol} = sprintf( ...
          '%.1f', ...
          rs0_all(im_pair(ij_), 1, ilc) ...
          * 1.d-3);
      end
    end
  end
end
