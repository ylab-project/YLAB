function layout = element_force_layout(name)
%element_force_layout - 新形式線材荷重ブロックの列位置を返す
%
%   layout = element_force_layout(name) は、`要素荷重(梁)`・
%   `要素荷重(柱)`・`応力計算用特殊荷重(梁)`・`応力計算用特殊荷重(柱)`
%   の列位置を返す。列構成は行頭、対象指定、部材端応力12成分、任意の
%   位置値、継続の順で決まり、読込時の継続整形と入力アダプターの列
%   参照はこの定義を共有する。対象外の名前には空を返す。
%
%   入力引数:
%     name - ブロック名。括弧は半角・全角どちらでもよい
%
%   出力引数:
%     layout - 列位置の構造体。対象外の名前では []
%              .name        - ブロック名
%              .kind        - 対象指定の種別。'girder'は層・フレーム・
%                             左端軸・右端軸、'column'は階・X軸・Y軸
%              .is_weight   - 行頭が区分3列なら true、荷重ケース1列は
%                             false
%              .target_col  - 対象指定の先頭列
%              .comp_col    - 部材端応力12成分の先頭列
%              .m0_col      - 中央モーメント列。ない場合は0
%              .quarter_col - 1/4・3/4位置4列の先頭列。ない場合は0
%              .m0y_col     - M0y・M0zの先頭列。ない場合は0
%              .option_col  - 省略可能列の先頭列。省略可能列がない
%                             ブロックでは継続列に一致する
%              .cont_col    - 継続列（最終列）
%              .ncol        - 全列数

% 種別と任意列の構成だけを定義し、列位置は下で導出する
definitions = {'要素荷重(梁)', 'girder', true, 'position'; ...
  '要素荷重(柱)', 'column', true, 'none'; '応力計算用特殊荷重(梁)', ...
  'girder', false, 'position'; '応力計算用特殊荷重(柱)', 'column', ...
  false, 'moment'};
layout = [];
idx = find(strcmp(definitions(:, 1), normalize_block_label(name)), 1);
if isempty(idx)
  return
end

layout.name = definitions{idx, 1};
layout.kind = definitions{idx, 2};
layout.is_weight = definitions{idx, 3};

% 行頭は区分3列（DL/LL・用途・タイプ）または荷重ケース1列
nhead = 1;
if layout.is_weight
  nhead = 3;
end
ntarget = 3;
if strcmp(layout.kind, 'girder')
  ntarget = 4;
end
layout.target_col = nhead + 1;
layout.comp_col = layout.target_col + ntarget;
layout.option_col = layout.comp_col + 12;

layout.m0_col = 0;
layout.quarter_col = 0;
layout.m0y_col = 0;
switch definitions{idx, 4}
  case 'position'
    % 中央モーメントと1/4・3/4位置4列
    layout.m0_col = layout.option_col;
    layout.quarter_col = layout.option_col + 1;
    noption = 5;
  case 'moment'
    % 応力計算用特殊荷重(柱)のM0y・M0z
    layout.m0y_col = layout.option_col;
    noption = 2;
  otherwise
    noption = 0;
end
layout.ncol = layout.option_col + noption;
layout.cont_col = layout.ncol;

return
end
