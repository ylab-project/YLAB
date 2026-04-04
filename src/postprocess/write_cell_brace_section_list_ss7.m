function [head, body] = ...
  write_cell_brace_section_list_ss7(...
  secb, ~, secdim, secmgr)
%write_cell_brace_section_list_ss7 - 鉛直ブレース断面リスト（SS7形式）
%
%   [head, body] = ...
%     write_cell_brace_section_list_ss7(...
%     secb, stype, secdim, secmgr) は、
%   BRBを除く鉛直ブレース断面リストを生成する。
%   TB（引張ブレース）と鋼材ブレース（BWFS/BHSS/BHSR）を
%   1つのテーブルにまとめ、存在するタイプに応じて
%   列構成を動的に決定する（SS7仕様 2.6.19準拠）。
%
%   入力引数:
%     secb   - ブレース断面情報構造体
%     stype  - 断面タイプ配列 [nsec×1]
%     secdim - 断面寸法配列 [nsec×7]
%     secmgr - SectionManagerオブジェクト
%
%   出力引数:
%     head - ヘッダーセル配列 [2×ncol]
%     body - 本体セル配列 [n×ncol]

%% ブレースタイプの判定（secbベース）
btype = secb.type;
is_tb = (btype == PRM.TB);
is_steel = (btype == PRM.BWFS) ...
  | (btype == PRM.BHSS) | (btype == PRM.BHSR);
has_tb = any(is_tb);
has_steel = any(is_steel);
ntb = sum(is_tb);
nsl = sum(is_steel);
nbrace = ntb + nsl;

if nbrace == 0 || isempty(secdim)
  head = cell(0, 0);
  body = cell(0, 0);
  return
end

%% 列構成の決定（SS7仕様 2.6.19）
% 全列ID定数
CNAME = 1; CSHAPE = 2; CMAT = 3;
CAREA = 4; CEAREA = 5; CIR = 6;
CTA = 7; CTU = 8; CHTB = 9; CGP = 10;

[cmap, ncol, colnames, colunits] = ...
  build_column_map(has_steel, has_tb);

%% ヘッダー生成
head = cell(2, ncol);
head(1, :) = colnames;
head(2, :) = colunits;

%% 本体生成
body = repmat({''}, nbrace, ncol);
irow = 0;

% 鋼材ブレースの行
if has_steel
  idx_sl = find(secb.type == PRM.BWFS ...
    | secb.type == PRM.BHSS ...
    | secb.type == PRM.BHSR);
  for i = 1:nsl
    irow = irow + 1;
    isb = idx_sl(i);
    idsec = secb.idsec(isb);
    dim = secdim(idsec, :);
    idsl = secb.id_section_list(isb);
    body{irow, cmap(CNAME)} = secb.name{isb};
    body{irow, cmap(CSHAPE)} = ...
      format_shape_name(secb.type(isb), dim);
    body{irow, cmap(CMAT)} = ...
      secmgr.secList.material_name{idsl, 1};
    body{irow, cmap(CAREA)} = '自動計算';
    body{irow, cmap(CIR)} = '自動計算';
  end
end

% TB（引張ブレース）の行
if has_tb
  idx_tb = find(...
    secb.tctype == PRM.BRACE_TENSION);
  idsec_tb = secb.idsec(idx_tb);
  secblist = getListRecord(...
    secmgr, secdim(idsec_tb, :));
  for i = 1:ntb
    irow = irow + 1;
    isb = idx_tb(i);
    body{irow, cmap(CNAME)} = secb.name{isb};
    body{irow, cmap(CSHAPE)} = secblist.label{i};
    body{irow, cmap(CAREA)} = ...
      sprintf('%.3f', secblist.A(i));
    body{irow, cmap(CEAREA)} = ...
      sprintf('%.3f', secblist.Ae(i));
    body{irow, cmap(CTA)} = ...
      sprintf('%.1f', secblist.Ta(i));
    body{irow, cmap(CTU)} = ...
      sprintf('%.1f', secblist.Tu(i));
    body{irow, cmap(CHTB)} = secblist.HTB{i};
    body{irow, cmap(CGP)} = secblist.GP{i};
  end
end

return
end

function [cmap, ncol, names, units] = ...
  build_column_map(has_steel, has_tb)
%build_column_map - 列構成マップを生成
%
%   [cmap, ncol, names, units] = ...
%     build_column_map(has_steel, has_tb) は、
%   鋼材ブレースとTBの有無に応じて列構成マップを
%   生成する。
%
%   入力引数:
%     has_steel - 鋼材ブレースの有無 (logical)
%     has_tb    - TBの有無 (logical)
%
%   出力引数:
%     cmap  - 全列ID→実列番号マッピング [1×10]
%     ncol  - 有効列数
%     names - 列名セル配列 [1×ncol]
%     units - 単位セル配列 [1×ncol]

ALL_NAMES = {'符号', '形状', '材料', ...
  '断面積', '有効断面積', '断面2次半径', ...
  '許容耐力', '終局耐力', ...
  '高力ボルト', 'ガセットプレート'};
ALL_UNITS = {'', '', '', 'cm2', ...
  'cm2', 'cm', 'kN', 'kN', '', ''};

% 列選択マスク（SS7仕様 2.6.19）
use = [true, true, has_steel, true, ...
  has_tb, has_steel, ...
  has_tb, has_tb, has_tb, has_tb];

active = find(use);
ncol = numel(active);
cmap = zeros(1, 10);
cmap(active) = 1:ncol;
names = ALL_NAMES(active);
units = ALL_UNITS(active);

return
end

function name = format_shape_name(stype, dim)
%format_shape_name - 断面タイプと寸法から形状名を生成
%
%   name = format_shape_name(stype, dim) は、
%   断面タイプに応じた形状名文字列を生成する。
%
%   入力引数:
%     stype - 断面タイプ (PRM.BWFS/BHSS/BHSR)
%     dim   - 断面寸法配列 [1×ncol]
%
%   出力引数:
%     name  - 形状名文字列
%              （例: 'H-200*100*5.5*8*8'）

v = @(x) sprintf('%g', x);
switch stype
  case PRM.BWFS
    % H-H*B*tw*tf*r
    name = sprintf('H-%s*%s*%s*%s*%s', ...
      v(dim(1)), v(dim(2)), v(dim(3)), ...
      v(dim(4)), v(dim(5)));
  case PRM.BHSS
    % □-D*D*t*r
    name = sprintf('□-%s*%s*%s*%s', ...
      v(dim(1)), v(dim(1)), ...
      v(dim(2)), v(dim(3)));
  case PRM.BHSR
    % ○-D*t
    name = sprintf('○-%s*%s', ...
      v(dim(1)), v(dim(2)));
  otherwise
    name = '';
end

return
end
