function [head, body] = ...
  write_cell_brace_steel_section_list( ...
  secb, stype, secdim, secmgr)
%write_cell_brace_steel_section_list - 鋼材ブレース仮定断面リスト
%
%   [head, body] = ...
%     write_cell_brace_steel_section_list( ...
%     secb, stype, secdim, secmgr) は、
%   鋼材ブレース（BWFS/BHSS/BHSR）の仮定断面リストを
%   入力CSV形式（8列）で生成する。
%
%   入力引数:
%     secb   - ブレース断面情報構造体
%     stype  - 断面タイプ配列 [nsec×1]
%     secdim - 断面寸法配列 [nsec×7]
%     secmgr - SectionManagerオブジェクト
%
%   出力引数:
%     head - ヘッダーセル配列 [2×8]
%     body - 本体セル配列 [n×8]

is_steel = (stype == PRM.BWFS) ...
  | (stype == PRM.BHSS) | (stype == PRM.BHSR);
nsl = sum(is_steel);

if nsl == 0 || isempty(secdim)
  head = cell(0, 0);
  body = cell(0, 0);
  return
end

%% 鋼材ブレース断面インデックスと断面寸法
idx_sl = find(secb.type == PRM.BWFS ...
  | secb.type == PRM.BHSS ...
  | secb.type == PRM.BHSR);
secdim_sl = secdim(is_steel, :);

%% 断面リストレコード取得（リストIDごとに分割）
% 異なる列構造の断面リストを一括取得すると
% table代入エラーとなるため個別に取得する
listIds = secdim_sl(:, end-1);
uids = unique(listIds);
secblist_type = cell(nsl, 1);
for k = 1:length(uids)
  mask = listIds == uids(k);
  rec = getListRecord( ...
    secmgr, secdim_sl(mask, :));
  secblist_type(mask) = rec.type;
end

%% ヘッダ生成（2行×8列）
head = cell(2, 8);
head(1, :) = {'ブレース符号', 'タイプ', ...
  '登録形状', '形状タイプ', ...
  'Ae', 'i', 'λe', '材料'};
head(2, :) = { ...
  '', '', '', '', 'cm2', 'cm', '', ''};

%% ボディ生成
body = cell(nsl, 8);
for i = 1:nsl
  isb = idx_sl(i);
  dim = secdim_sl(i, :);
  idsl = secb.id_section_list(isb);
  body{i, 1} = secb.name{isb};
  body{i, 2} = type_str(secb.type(isb));
  body{i, 3} = ...
    format_shape_name(secb.type(isb), dim);
  body{i, 4} = secblist_type{i};
  body{i, 5} = '0';
  body{i, 6} = '0';
  body{i, 7} = '0';
  body{i, 8} = ...
    secmgr.secList.material_name{idsl, 1};
end

return
end

function str = type_str(stype)
%type_str - 断面タイプ定数を入力CSV文字列に変換
%
%   str = type_str(stype) は、
%   PRM定数を入力CSV用のタイプ文字列に変換する。
%
%   入力引数:
%     stype - 断面タイプ (PRM.BWFS/BHSS/BHSR)
%
%   出力引数:
%     str - タイプ文字列 ('H', '□', '○')

switch stype
  case PRM.BWFS
    str = 'H';
  case PRM.BHSS
    str = '□';
  case PRM.BHSR
    str = '○';
  otherwise
    str = '';
end

return
end

function name = format_shape_name(stype, dim)
%format_shape_name - 断面タイプと寸法から形状名を生成
%
%   name = format_shape_name(stype, dim) は、
%   断面タイプに応じた形状名文字列を生成する。
%   入力CSV形式のため区切り文字は 'x' を使用。
%
%   入力引数:
%     stype - 断面タイプ (PRM.BWFS/BHSS/BHSR)
%     dim   - 断面寸法配列 [1×ncol]
%
%   出力引数:
%     name - 形状名文字列
%              （例: 'H-200x100x5.5x8x8'）

v = @(x) sprintf('%g', x);
switch stype
  case PRM.BWFS
    % H-HxBxtwxtfxr
    name = sprintf('H-%sx%sx%sx%sx%s', ...
      v(dim(1)), v(dim(2)), v(dim(3)), ...
      v(dim(4)), v(dim(5)));
  case PRM.BHSS
    % □-DxDxtxr
    name = sprintf('□-%sx%sx%sx%s', ...
      v(dim(1)), v(dim(1)), ...
      v(dim(2)), v(dim(3)));
  case PRM.BHSR
    % ○-Dxt
    name = sprintf('○-%sx%s', ...
      v(dim(1)), v(dim(2)));
  otherwise
    name = '';
end

return
end
