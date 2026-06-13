function [dbflhead, dbflbody] = write_cell_design_brace_force_list( ...
  com, result, icase)
%write_cell_design_brace_force_list - 鉛直ブレース設計応力表(長期/地震時)
%
%   [dbflhead, dbflbody] = ...
%     write_cell_design_brace_force_list(com, result, icase)
%   は、設計応力表(長期 or 地震時)をセル配列で返す。
%
%   入力引数:
%     com    - 共通オブジェクト
%     result - 結果構造体（dfn を使用）
%     icase  - 1=長期, 2=地震時
%
%   出力引数:
%     dbflhead - ヘッダセル配列 [3×10]
%     dbflbody - データセル配列 [nrow×11]（最終列は CONT_MARKER）

nominal_brace = com.nominal.brace;
brace = com.member.brace;
secb = com.section.brace;
dfn_all = result.dfn;

% 場合分け
if icase == 1
  ilcset = 1;
  label = {'L'};
else
  ilcset = [PRM.EXP PRM.EXN PRM.EYP PRM.EYN];
  label = {'L+Ex', 'L-Ex', 'L+Ey', 'L-Ey'};
end
nlc = length(ilcset);
maxlc = max(ilcset);

% ヘッダ
dbflhead = cell(3, 10);
dbflhead(1, 1:10) = {'階', 'ﾌﾚｰﾑ', '軸－軸', '', '符号', ...
  'ケース', 'タイプ', '軸力', '', '多層'};
dbflhead(2, 8:9) = {'左下り', '右下り'};
dbflhead(3, 8:9) = {'kN', 'kN'};

nnb = com.num.nominal_brace;
dbflbody = cell(0, 10);
if nnb == 0 || isempty(dfn_all) || size(dfn_all, 3) < maxlc
  return
end
dfn = dfn_all(:, :, ilcset);

nstory = com.nstory;
nblx = com.nblx;
nbly = com.nbly;
rows = cell(nnb * nlc, 10 + 1);
irow = 0;

ids_story = nominal_brace.idstory;
idx_nom = nominal_brace.idx;
idy_nom = nominal_brace.idy;
idir_nom = nominal_brace.idir;

for ist = nstory:-1:1
  % X通りブレース
  for iy = 1:nbly
    for ix = 1:nblx
      inb_list = find(ids_story == ist & idx_nom(:, 1) == ix ...
        & idy_nom(:, 1) == iy & idir_nom == PRM.X);
      for inb = inb_list'
        add_row(inb);
      end
    end
  end
  % Y通りブレース
  for ix = 1:nblx
    for iy = 1:nbly
      inb_list = find(ids_story == ist & idx_nom(:, 1) == ix ...
        & idy_nom(:, 1) == iy & idir_nom == PRM.Y);
      for inb = inb_list'
        add_row(inb);
      end
    end
  end
end

if irow == 0
  dbflbody = cell(0, 10 + 1);
else
  dbflbody = rows(1:irow, :);
end

return

  function add_row(inb)
    ibij = nominal_brace.idmeb(inb, :);
    nz_cols = find(ibij > 0);
    npair = length(nz_cols);
    % 左右の表示位置と dfn 軸力列を先に決定
    ipos_pair = zeros(1, 2);
    icomp_pair = zeros(1, 2);
    inm = nominal_brace.idnominal(inb);
    for ij_ = nz_cols
      ib_ = ibij(ij_);
      [ipos_pair(ij_), type_label_] = ...
        resolve_brace_position_label(brace, ib_, ij_, npair);
      icomp_pair(ij_) = get_axial_component(nz_cols, ij_);
    end

    % 各荷重ケースの軸力を出力
    for ilc = 1:nlc
      irow = irow + 1;
      if ilc == 1
        rows{irow, 1} = nominal_brace.floor_name{inb};
        rows{irow, 2} = nominal_brace.frame_name{inb, 1};
        rows{irow, 3} = nominal_brace.coord_name{inb, 1};
        rows{irow, 4} = nominal_brace.coord_name{inb, 2};
        isb_ = brace.idsecb(ibij(nz_cols(1)));
        rows{irow, 5} = secb.name{isb_};
        rows{irow, 7} = type_label_;
      end
      rows{irow, 6} = label{ilc};
      for ij_ = nz_cols
        icol = 7 + ipos_pair(ij_);
        icomp = icomp_pair(ij_);
        rows{irow, icol} = sprintf('%.1f', -dfn(inm, icomp, ilc) * 1.d-3);
      end
      if ilc < nlc
        rows{irow, end} = PRM.CONT_MARKER;
      end
    end
  end

  function icomp = get_axial_component(nz_cols_, ij_)
  %get_axial_component - 名目ブレース内の左右片に対応する軸力列
  %
  %   icomp = get_axial_component(nz_cols_, ij_) は、名目ブレースの
  %   1片目を dfn の i端軸力列、2片目を j端軸力列へ対応させる。
    if isscalar(nz_cols_) || ij_ == nz_cols_(1)
      icomp = 1;
    else
      icomp = 7;
    end
  end
end
