function [dgiflhead, dgiflbody] = ...
  write_cell_design_girder_init_force_list(com, result)
%write_cell_design_girder_init_force_list - 梁設計応力表(組合せ前)生成
%
%   [dgiflhead, dgiflbody] =
%     write_cell_design_girder_init_force_list(com, result) は、
%   荷重組合せ前の名目梁設計応力（曲げM・せん断Q）一覧を生成する。
%
%   入力引数:
%     com    - 共通オブジェクト
%     result - 解析結果構造体 (lm_nominal, dfn0, nomgc.Mcn0 等)
%
%   出力引数:
%     dgiflhead - ヘッダ部セル配列 [3×24]
%     dgiflbody - データ部セル配列 [nrow×25]（最終列は CONT_MARKER）

% 定数
nng = com.num.nominal_girder;
nblx = com.nblx;
nbly = com.nbly;
nstory = com.nstory;
ncol = 24;

% 共通配列
nominal_girder = com.nominal.girder;
girder = com.member.girder;
secg = com.section.girder;
lm_nominal = result.lm_nominal;
dfn0_all = result.dfn0;
Mcn0_all = result.nomgc.Mcn0;
nlc = size(dfn0_all, 3);

% ID変換
nmeg1_ = nominal_girder.idmeg(:, 1);
idnmg2x = girder.idx(nmeg1_, 1);
idnmg2y = girder.idy(nmeg1_, 1);
idnmg2story = girder.idstory(nmeg1_, 1);
idnmg2mg = nominal_girder.idmeg;
idnmg2nm = nominal_girder.idnominal;
idnmg2dir = nominal_girder.idir;
idmg2m = girder.idme;

% --- ヘッダ（3行 x 24列）---
dgiflhead = cell(3, ncol);
dgiflhead(1, 1:7) = {'層', 'ﾌﾚｰﾑ', '軸－軸', '', '符号', ...
  'ケース', '部材長'};
dgiflhead{1, 8} = '曲げ';
dgiflhead{1, 17} = 'せん断';
dgiflhead(2, 8:16) = {'左端', 'ﾊﾝﾁ端', 'JOINT', '1/4', '中央', ...
  '1/4', 'JOINT', 'ﾊﾝﾁ端', '右端'};
dgiflhead(2, 17:24) = {'左端', 'ﾊﾝﾁ端', 'JOINT', '左1/4', '右1/4', ...
  'JOINT', 'ﾊﾝﾁ端', '右端'};
dgiflhead{3, 7} = 'mm';
dgiflhead(3, 8:16) = repmat({'kNm'}, 1, 9);
dgiflhead(3, 17:24) = repmat({'kN'}, 1, 8);

dgiflbody = cell(0, ncol);
if nng == 0 || isempty(lm_nominal)
  return
end
if isempty(dfn0_all) || nlc == 0
  return
end

% --- 表書き出し ---
% rows は head=24 列 + marker 列で 25 列
rows = cell(nng * nlc, ncol + 1);
iggg = 1:nng;
irow = 0;
for i = 1:nstory
  ist = nstory - i + 1;
  idir = 1;
  for iy = 1:nbly
    for ix = 1:nblx
      print_body;
    end
  end
  idir = 2;
  for ix = 1:nblx
    for iy = 1:nbly
      print_body;
    end
  end
end
if irow == 0
  dgiflbody = cell(0, ncol);
else
  dgiflbody = rows(1:irow, :);
end

return
  function print_body
  %print_body - 1 名目梁分の初期応力行を rows に書き出す
  %
  %   print_body は、外側スコープの (ist, ix, iy, idir) に対応する
  %   名目梁を検索し、各荷重ケース (1..nlc) について 1 物理行ずつ
  %   rows に書き込む。最終ケース以外には CONT_MARKER を付与する。
  %
  %   入力引数:
  %     なし（外側スコープの ist, ix, iy, idir, nlc, dfn0_all,
  %     Mcn0_all, idnmg2*, idmg2m, girder, secg, lm_nominal を参照）
  %
  %   出力引数:
  %     なし（外側の rows と irow を更新）
    ing = iggg(idnmg2story == ist & idnmg2x(:, 1) == ix ...
      & idnmg2y(:, 1) == iy & idnmg2dir(:) == idir);
    if isempty(ing)
      return
    end

    inm = idnmg2nm(ing);
    idsub = nominal_girder.idsub(ing, :);
    ig1 = idnmg2mg(ing, idsub(1));
    im1 = idmg2m(ig1);
    ig2 = idnmg2mg(ing, idsub(2));

    for ilc = 1:nlc
      irow = irow + 1;
      if ilc == 1
        rows{irow, 1} = girder.story_name{ig1};
        rows{irow, 2} = girder.frame_name{ig1};
        rows{irow, 3} = girder.coord_name{ig1, 1};
        rows{irow, 4} = girder.coord_name{ig2, 2};
        isg = girder.idsecg(ig1);
        rows{irow, 5} = make_section_symbol(secg, isg);
        rows{irow, 7} = sprintf('%.0f', lm_nominal(im1));
      end
      rows{irow, 6} = PRM.load_case_name(ilc);
      % 曲げ: 左端(8), 中央(12), 右端(16)
      rows{irow, 8} = sprintf('%.2f', -dfn0_all(inm, 5, ilc) * 1e-6);
      rows{irow, 12} = sprintf('%.2f', -Mcn0_all(inm, ilc) * 1e-6);
      rows{irow, 16} = sprintf('%.2f', dfn0_all(inm, 11, ilc) * 1e-6);
      % せん断: 左端(17), 右端(24)
      rows{irow, 17} = sprintf('%.2f', dfn0_all(inm, 3, ilc) * 1e-3);
      rows{irow, 24} = sprintf('%.2f', dfn0_all(inm, 9, ilc) * 1e-3);
      % 1 名目梁 = nlc 物理行/論理ブロック。最終ケース以外は CONT_MARKER
      if ilc < nlc
        rows{irow, end} = PRM.CONT_MARKER;
      end
    end
  end
end
