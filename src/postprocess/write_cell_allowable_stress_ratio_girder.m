function [head, body] = write_cell_allowable_stress_ratio_girder(com, ...
  result)
%write_cell_allowable_stress_ratio_girder - S梁検定比一覧セル配列を生成
%
%   [head, body] = write_cell_allowable_stress_ratio_girder(com, result)
%   は、S梁の許容応力度検定比（M, Q, 保有耐力接合）を符号ごとに
%   集計したセル配列を生成する。
%
%   入力引数:
%     com    - 共通オブジェクト
%     result - 解析結果構造体 (gri/grj/grc/gsi/gsj, jbsratio 等)
%
%   出力引数:
%     head - ヘッダ部セル配列 [3×15]
%     body - データ部セル配列 [nrow×15]

% 定数
nsg = com.nsecg;
nlc = com.nlc;
nstory = com.nstory;
nng = com.num.nominal_girder;
ncol = 15;

% 共通配列
girder = com.member.girder;
nominal_girder = com.nominal.girder;
secg = com.section.girder;
gstype = com.section.girder.type;

% 梁許容応力度比（部材単位の各ケース最大値）
gri_all = result.gri;
grj_all = result.grj;
grc_all = result.grc;
gsi_all = result.gsi;
gsj_all = result.gsj;

% 保有耐力接合（仕口）比率 [nng×2]
jbsratio = result.jbsratio;

% --- ヘッダ ---
head = cell(3, ncol);
head(1, :) = {'層', '符号', 'M', '', '', '', '', 'Q', ...
  '', '', '', '保有耐力接合(仕口)', '', '', ''};
head(2, :) = {'', '', '仕口左', '左端', '中央', '右端', ...
  '仕口右', '仕口左', '左端', '右端', '仕口右', '左端', '', '右端', ''};
head(3, :) = {'', '', '', '', '', '', '', '', '', '', ...
  '', 'M', 'Q', 'M', 'Q'};

% --- データ ---
body = cell(0, ncol);
if nsg == 0 || isempty(gri_all) ...
    || isempty(grj_all) || isempty(grc_all) ...
    || isempty(gsi_all) || isempty(gsj_all)
  return
end
gri = reshape(gri_all, [], nlc) + 1;
grj = reshape(grj_all, [], nlc) + 1;
grc = reshape(grc_all, [], nlc) + 1;
gsi = reshape(gsi_all, [], nlc) + 1;
gsj = reshape(gsj_all, [], nlc) + 1;
grimax = max(gri, [], [2 3]);
grjmax = max(grj, [], [2 3]);
grcmax = max(grc, [], 2);
gsimax = max(gsi, [], [2 3]);
gsjmax = max(gsj, [], [2 3]);
body = cell(nsg, ncol);
iggg = 1:nng;
idnm2sg = girder.idsecg(nominal_girder.idmeg(:, 1));
irow = 0;
for i = 1:nstory
  ist = nstory - i + 1;
  for isg = 1:nsg
    if secg.idstory(isg) ~= ist
      continue
    end
    if gstype(isg) ~= PRM.WFS
      continue
    end
    ing = iggg(idnm2sg == isg);

    % 除外
    if ~nominal_girder.is_allowable_stress(ing)
      continue
    end

    % 検定値
    irow = irow + 1;
    gri_ = ceil(max(grimax(ing)) * 100) / 100;
    grj_ = ceil(max(grjmax(ing)) * 100) / 100;
    grc_ = ceil(max(grcmax(ing)) * 100) / 100;
    gsi_ = ceil(max(gsimax(ing)) * 100) / 100;
    gsj_ = ceil(max(gsjmax(ing)) * 100) / 100;

    % 書き出し
    body{irow, 1} = secg.story_name{isg};
    body{irow, 2} = make_section_symbol(secg, isg);
    % M: 仕口左(3)=空, 左端(4), 中央(5), 右端(6), 仕口右(7)=空
    body{irow, 4} = sprintf('%.2f', gri_);
    body{irow, 5} = sprintf('%.2f', grc_);
    body{irow, 6} = sprintf('%.2f', grj_);
    % Q: 仕口左(8)=空, 左端(9), 右端(10), 仕口右(11)=空
    body{irow, 9} = sprintf('%.2f', gsi_);
    body{irow, 10} = sprintf('%.2f', gsj_);
    % 保有耐力接合(仕口): 左端M(12), 左端Q(13)=空, 右端M(14), 右端Q(15)=空
    if ~isempty(jbsratio)
      jbs_i = ceil(max(jbsratio(ing, 1)) * 100) / 100;
      jbs_j = ceil(max(jbsratio(ing, 2)) * 100) / 100;
      if jbs_i > 0
        body{irow, 12} = sprintf('%.2f', jbs_i);
      end
      if jbs_j > 0
        body{irow, 14} = sprintf('%.2f', jbs_j);
      end
    end
  end
end
body = body(1:irow, :);

return
end
