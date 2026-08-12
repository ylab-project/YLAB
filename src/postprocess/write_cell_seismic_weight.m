function [head, body] = write_cell_seismic_weight(com, result)
%write_cell_seismic_weight - case=EX/EYの地震用重量表を生成する
%
%   [head, body] = write_cell_seismic_weight(com, result) は、完成済みの
%   地震用重量を層・type別に集計し、SS7の地震用重量に対応する
%   上下2行形式のセル配列を返す。
%
%   入力引数:
%     com    - 節点および層情報
%     result - 分類済み要素重量を含む解析結果
%
%   出力引数:
%     head - 3行の帳票ヘッダー
%     body - 層別上下2行（最終列はmarker列）

head = {'層(階)', '床面積', '床自重(D.L)', '梁自重', '壁自重', ...
  'ﾌﾚｰﾑ外雑壁', '特殊荷重', 'wi'; '', '', '床自重(L.L)', ...
  '柱自重', '基礎自重', '積雪荷重', '補正重量', '(wi/A)'; ...
  '', 'm2', 'kN', 'kN', 'kN', 'kN', 'kN', 'kN'};
body = cell(0, 9);
if ~result.element_weight.has_seismic
  return
end

% KBRACE-MID節点の地震用重量をグリッド節点に再配分する
nodal = result.element_weight.nodal;
seismic = reshape(nodal(:, :, PRM.ELOAD_CASE_EXEY, :), com.nnode, 6, []);
seismic = redistribute_kbrace_mid(com, seismic);
rows = cell(com.nstory * 2, 9);
irow = 0;
for offset = 1:com.nstory
  istory = com.nstory - offset + 1;
  target = com.node.idstory == istory & com.node.idrep == 0 ...
    & com.node.type ~= PRM.NODE_BRACE_FOR_COLUMN;
  values = reshape(sum(seismic(target, 3, :), 1), 1, []) * 1e-3;
  total = sum(values);
  irow = irow + 1;
  rows{irow, 1} = story_label(com.story, istory);
  rows{irow, 2} = fmt_ceil_abs(0, 1);
  rows{irow, 3} = fmt_ceil_abs(values(PRM.ELOAD_TYPE_FLOOR), 1);
  rows{irow, 4} = fmt_ceil_abs(0, 1);
  rows{irow, 5} = fmt_ceil_abs(values(PRM.ELOAD_TYPE_WALL), 1);
  rows{irow, 6} = fmt_ceil_abs(values(PRM.ELOAD_TYPE_FRAME_OUT), 1);
  rows{irow, 7} = fmt_ceil_abs(values(PRM.ELOAD_TYPE_SPECIAL), 1);
  rows{irow, 8} = fmt_ceil_abs(total, 1);
  irow = irow + 1;
  rows{irow, 3} = fmt_ceil_abs(0, 1);
  rows{irow, 4} = fmt_ceil_abs(0, 1);
  rows{irow, 5} = fmt_ceil_abs(values(PRM.ELOAD_TYPE_FOUNDATION), 1);
  rows{irow, 6} = fmt_ceil_abs(0, 1);
  rows{irow, 7} = fmt_ceil_abs(values(PRM.ELOAD_TYPE_CORRECTION), 1);
  rows{irow, 8} = fmt_ceil_abs(0, 1);
end
body = rows(1:irow, :);

return
end

function label = story_label(story, istory)
%story_label - 層名と対応階名をSS7帳票向けに組み合わせる
label = story.name{istory};
if isfield(story, 'floor_name') && ~isempty(story.floor_name{istory})
  label = sprintf('%s(%s)', label, story.floor_name{istory});
end

return
end
