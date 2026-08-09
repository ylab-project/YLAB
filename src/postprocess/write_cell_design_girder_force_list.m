function [dgflhead, dgflbody] = ...
  write_cell_design_girder_force_list(com, result, icase)
%write_cell_design_girder_force_list - 梁設計応力表セル配列を生成
%
%   [dgflhead, dgflbody] =
%     write_cell_design_girder_force_list(com, result, icase) は、
%   名目梁ごとの設計応力（曲げM・せん断Q・軸力N）一覧を生成する。
%
%   入力引数:
%     com    - 共通オブジェクト
%     result - 解析結果構造体 (lm_nominal, dfn, nomgc.Mcn 等)
%     icase  - ケース指定 (1: 長期L のみ、2以上: 地震L±E)
%
%   出力引数:
%     dgflhead - ヘッダ部セル配列 [3×27]
%     dgflbody - データ部セル配列 [nrow×28]（最終列は CONT_MARKER）

% 定数
nng = com.num.nominal_girder;
nstory = com.nstory;
ncol = 27;

% 共通配列
nominal_girder = com.nominal.girder;
girder = com.member.girder;
secg = com.section.girder;
lm_nominal = result.lm_nominal;
dfn_all = result.dfn;
Mcn_all = result.nomgc.Mcn;

% ID変換
nmeg1_ = nominal_girder.idmeg(:, 1);
idnmg2story = girder.idstory(nmeg1_, 1);
idnmg2mg = nominal_girder.idmeg;
idnmg2nm = nominal_girder.idnominal;
idmg2m = girder.idme;

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

% --- ヘッダ ---
dgflhead = cell(3, ncol);
dgflhead(1, 1:7) = {'層', 'ﾌﾚｰﾑ', '軸－軸', '', '符号', ...
  'ケース', '部材長'};
dgflhead{1, 8} = '曲げ';
dgflhead{1, 17} = 'せん断';
dgflhead{1, 24} = '軸力';
dgflhead(2, 8:16) = {'左端', 'ﾊﾝﾁ端', 'JOINT', '1/4', ...
  '中央', '1/4', 'JOINT', 'ﾊﾝﾁ端', '右端'};
dgflhead(2, 17:23) = {'左端', 'ﾊﾝﾁ端', 'JOINT', '中央', ...
  'JOINT', 'ﾊﾝﾁ端', '右端'};
dgflhead(2, 24:26) = {'左端', '中央', '右端'};
dgflhead{3, 7} = 'mm';
dgflhead(3, 8:16) = repmat({'kNm'}, 1, 9);
dgflhead(3, 17:23) = repmat({'kN'}, 1, 7);
dgflhead(3, 24:26) = repmat({'kN'}, 1, 3);

dgflbody = cell(0, ncol);
if nng == 0 || isempty(lm_nominal)
  return
end
if isempty(dfn_all) || size(dfn_all, 3) < maxlc
  return
end
if isempty(Mcn_all) || size(Mcn_all, 2) < maxlc
  return
end
dfn = dfn_all(:, :, ilcset);
Mcn = Mcn_all(:, ilcset);

% --- 表書き出し ---
% rows は head=27 列 + marker 列で 28 列
rows = cell(nng * nlc, ncol + 1);
iggg = 1:nng;
irow = 0;
for i = 1:nstory
  ist = nstory - i + 1;
  ing_list = iggg(idnmg2story == ist);
  for idxIng = 1:numel(ing_list)
    print_body(ing_list(idxIng));
  end
end
if irow == 0
  dgflbody = cell(0, ncol);
else
  dgflbody = rows(1:irow, :);
end

return
  function print_body(ing)
  %print_body - 1 名目梁分の応力行を rows に書き出す（外側 irow を更新）
  %
  %   print_body は、指定された名目梁について各荷重ケース (1..nlc)
  %   の 1 物理行ずつを rows に書き込む。最終ケース以外には
  %   CONT_MARKER を付与する。
  %
  %   入力引数:
  %     ing - 名目梁番号
  %
  %   出力引数:
  %     なし（外側の rows と irow を更新）
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
        rows{irow, 5} = secg.full_name{isg};
        rows{irow, 7} = sprintf('%.0f', lm_nominal(im1));
      end
      rows{irow, 6} = label{ilc};
      % 曲げ: 左端(8), 中央(12), 右端(16)
      Mi_ = -dfn(inm, 5, ilc) * 1e-6;
      rows{irow, 8} = sprintf('%.1f', Mi_);
      Mc_ = -Mcn(inm, ilc) * 1e-6;
      rows{irow, 12} = sprintf('%.1f', Mc_);
      Mj_ = dfn(inm, 11, ilc) * 1e-6;
      rows{irow, 16} = sprintf('%.1f', Mj_);
      % せん断: 左端(17), 右端(23)
      Qi_ = dfn(inm, 3, ilc) * 1e-3;
      rows{irow, 17} = sprintf('%.1f', Qi_);
      Qj_ = dfn(inm, 9, ilc) * 1e-3;
      rows{irow, 23} = sprintf('%.1f', Qj_);
      % 軸力: 左端(24), 右端(26)
      Ni_ = -dfn(inm, 1, ilc) * 1e-3;
      Nj_ = -dfn(inm, 7, ilc) * 1e-3;
      rows{irow, 24} = sprintf('%.1f', Ni_);
      rows{irow, 26} = sprintf('%.1f', Nj_);
      % 1 名目梁 = nlc 物理行/論理ブロック。最終ケース以外は CONT_MARKER
      if ilc < nlc
        rows{irow, end} = PRM.CONT_MARKER;
      end
    end
  end
end
