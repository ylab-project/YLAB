function [head, body] = write_cell_seismic_weight(com, result)
%write_cell_seismic_weight - 計算済み層別地震用重量を配置する
%
%   [head, body] = write_cell_seismic_weight(com, result) は、分析層で
%   確定した層別分類重量とwiを地震用重量表の上下2行へ配置する。
%
%   入力引数:
%     com    - 層情報
%     result - .nodal_weight.storyに計算済み層別物理量を持つ結果
%
%   出力引数:
%     head - 3行の帳票ヘッダー
%     body - 層別上下2行（最終列は空のmarker列）
head = {'層(階)', '床面積', '床自重(D.L)', '梁自重', '壁自重', ...
  'ﾌﾚｰﾑ外雑壁', '特殊荷重', 'wi'; '', '', '床自重(L.L)', ...
  '柱自重', '基礎自重', '積雪荷重', '補正重量', '(wi/A)'; ...
  '', 'm2', 'kN', 'kN', 'kN', 'kN', 'kN', 'kN'};
rows = cell(com.nstory * 2, 9);
weight = result.nodal_weight.story;
irow = 0;
for offset = 1:com.nstory
  istory = com.nstory - offset + 1;
  irow = irow + 1;
  rows{irow, 1} = make_story_label(com.story, istory);
  rows{irow, 2} = fmt_weight_kn(0, 0);
  rows{irow, 3} = fmt_weight_kn(weight.floor_dl(istory), 0);
  rows{irow, 4} = fmt_weight_kn(weight.girder(istory), 0);
  rows{irow, 5} = fmt_weight_kn(weight.wall(istory), 0);
  rows{irow, 6} = fmt_weight_kn(weight.frame_out(istory), 0);
  rows{irow, 7} = fmt_weight_kn(weight.special(istory), 0);
  rows{irow, 8} = fmt_weight_kn(weight.total(istory), 0);

  irow = irow + 1;
  rows{irow, 3} = fmt_weight_kn(weight.floor_ll(istory), 0);
  rows{irow, 4} = fmt_weight_kn(weight.column(istory), 0);
  rows{irow, 5} = fmt_weight_kn(weight.foundation(istory), 0);
  rows{irow, 6} = fmt_weight_kn(0, 0);
  rows{irow, 7} = fmt_weight_kn(weight.correction(istory), 0);
  rows{irow, 8} = fmt_weight_kn(0, 0);
end
body = rows(1:irow, :);

return
end


function label = make_story_label(story, istory)
%make_story_label - 層名と対応階名をSS7帳票向けに組み合わせる
%
%   label = make_story_label(story, istory) は、層名へ対応階名を括弧付きで
%   追加する。対応階名がない場合は層名だけを返す。
%
%   入力引数:
%     story  - 層情報
%     istory - 層番号
%
%   出力引数:
%     label - 帳票に出力する層名
label = story.name{istory};
if ~isempty(story.floor_name{istory})
  label = sprintf('%s(%s)', label, story.floor_name{istory});
end

return
end