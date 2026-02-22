function [bshead, bsbody] = ...
  write_cell_brace_section_list_ss7(...
  secb, stype, secdim, secmgr)
%write_cell_brace_section_list_ss7 - 鉛直ブレース断面リスト（SS7形式）
%
%   [bshead, bsbody] = ...
%     write_cell_brace_section_list_ss7(...
%     secb, stype, secdim, secmgr) は、
%   BRBを除く鉛直ブレース断面リストを生成します。
%   現在はTB（引張ブレース）に対応しています。
%
%   入力引数:
%     secb   - ブレース断面情報構造体
%     stype  - 断面タイプ配列 [nsec×1]
%     secdim - 断面寸法配列 [nsec×ncol]
%     secmgr - SectionManagerオブジェクト
%
%   出力引数:
%     bshead - 断面リストのヘッダー [2×8]
%     bsbody - 断面リストの本体 [n×8]

% TB断面の判定
ntb = sum(stype == PRM.TB);

% TBなしの場合は空を返す
if ntb == 0 || isempty(secdim)
  bshead = cell(0, 8);
  bsbody = cell(0, 8);
  return
end

% ヘッダー設定
bshead = cell(2, 8);
bshead(1, 1:8) = {'符号', '形状', '断面積', ...
  '有効断面積', '許容耐力', '終局耐力', ...
  '高力ボルト', 'ガセットプレート'};
bshead(2, 3:6) = {'cm2', 'cm2', 'kN', 'kN'};

% 本体の初期化
bsbody = cell(ntb, 8);

if true
  % secbインデックスとの対応
  tb_secb = find(...
    secb.tctype == PRM.BRACE_TENSION);
  secblist = getListRecord(secmgr, ...
    secdim(stype == PRM.TB, :));
  for i = 1:ntb
    isb = tb_secb(i);
    bsbody{i, 1} = secb.name{isb};
    bsbody{i, 2} = secblist.type{i};
    bsbody{i, 3} = ...
      sprintf('%.3f', secblist.A(i));
    bsbody{i, 4} = ...
      sprintf('%.3f', secblist.Ae(i));
    bsbody{i, 5} = ...
      sprintf('%.1f', secblist.Ta(i));
    bsbody{i, 6} = ...
      sprintf('%.1f', secblist.Tu(i));
    bsbody{i, 7} = secblist.HTB{i};
    bsbody{i, 8} = secblist.GP{i};
  end
end

return
end
