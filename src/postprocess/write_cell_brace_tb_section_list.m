function [head, body] = ...
  write_cell_brace_tb_section_list( ...
  secb, stype, secdim, secmgr)
%write_cell_brace_tb_section_list - 引張ブレース仮定断面リスト
%
%   [head, body] = ...
%     write_cell_brace_tb_section_list( ...
%     secb, stype, secdim, secmgr) は、
%   引張ブレース（TB）の仮定断面リストを
%   入力CSV形式（2列）で生成する。
%
%   入力引数:
%     secb   - ブレース断面情報構造体
%     stype  - 断面タイプ配列 [nsec×1]
%     secdim - 断面寸法配列 [nsec×7]
%     secmgr - SectionManagerオブジェクト
%
%   出力引数:
%     head - ヘッダーセル配列 [1×2]
%     body - 本体セル配列 [n×2]

is_tb = (stype == PRM.TB);
ntb = sum(is_tb);

if ntb == 0 || isempty(secdim)
  head = cell(0, 0);
  body = cell(0, 0);
  return
end

%% 断面リストレコード取得
secblist = getListRecord( ...
  secmgr, secdim(is_tb, :));

%% TB断面インデックス（secb内）
idx_tb = find( ...
  secb.tctype == PRM.BRACE_TENSION);

%% ヘッダ生成（1行×2列）
head = {'ブレース符号', '登録形状'};

%% ボディ生成
body = cell(ntb, 2);
for i = 1:ntb
  isb = idx_tb(i);
  body{i, 1} = secb.name{isb};
  body{i, 2} = secblist.type{i};
end

return
end
