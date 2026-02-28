function [head, body] = ...
  write_cell_brace_manufacturer_section_list( ...
  secb, stype, secdim, secmgr)
%write_cell_brace_manufacturer_section_list - メーカー製品仮定断面リスト
%
%   [head, body] = ...
%     write_cell_brace_manufacturer_section_list( ...
%     secb, stype, secdim, secmgr) は、
%   メーカー製品ブレース（BRB等）の仮定断面リストを
%   入力CSV形式（3列）で生成する。
%
%   入力引数:
%     secb   - ブレース断面情報構造体
%     stype  - 断面タイプ配列 [nsec×1]
%     secdim - 断面寸法配列 [nsec×7]
%     secmgr - SectionManagerオブジェクト
%
%   出力引数:
%     head - ヘッダーセル配列 [1×3]
%     body - 本体セル配列 [n×3]

is_brb = (stype == PRM.BRB);
nbrb = sum(is_brb);

if nbrb == 0 || isempty(secdim)
  head = cell(0, 0);
  body = cell(0, 0);
  return
end

%% 断面リストレコード取得
secblist = getListRecord( ...
  secmgr, secdim(is_brb, :));

%% BRB断面インデックス（secb内）
is_steel_secb = (secb.type == PRM.BWFS) ...
  | (secb.type == PRM.BHSS) ...
  | (secb.type == PRM.BHSR);
is_tb_secb = ...
  (secb.tctype == PRM.BRACE_TENSION);
idx_brb = find( ...
  ~is_steel_secb & ~is_tb_secb);

%% ヘッダ生成（1行×3列）
head = {'ブレース符号', 'タイプ', '登録形状'};

%% ボディ生成
body = cell(nbrb, 3);
for i = 1:nbrb
  isb = idx_brb(i);
  body{i, 1} = secb.name{isb};
  body{i, 2} = secb.type_name{isb};
  body{i, 3} = secblist.symbol{i};
end

return
end
