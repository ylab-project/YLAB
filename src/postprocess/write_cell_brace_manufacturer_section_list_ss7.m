function [bshead, bsbody] = ...
  write_cell_brace_manufacturer_section_list_ss7( ...
  secb, stype, secdim, secmgr)
%write_cell_brace_manufacturer_section_list_ss7 - メーカー製ブレース断面リスト
%
%   [bshead, bsbody] = ...
%     write_cell_brace_manufacturer_section_list_ss7( ...
%     secb, stype, secdim, secmgr) は、
%   鉛直ブレース断面リスト（メーカー製品）を返す。
%   BRBおよび引張ブレース（TB）に対応。
%
%   入力引数:
%     secb - ブレース断面情報
%     stype - 断面タイプ配列
%     secdim - 断面寸法配列
%     secmgr - SectionManagerオブジェクト
%
%   出力引数:
%     bshead - ヘッダセル配列
%     bsbody - データセル配列

isBRB = (stype == PRM.BRB);
isTB = (stype == PRM.TB);
ntb = sum(isTB);

if any(isTB)
  % TB断面リスト出力
  bshead = cell(2, 8);
  bshead(1,:) = { ...
    '符号', '形状', '断面積', ...
    '有効断面積', '許容耐力', '終局耐力', ...
    '高力ボルト', 'ガセットプレート'};
  bshead(2, 3:6) = { ...
    'cm2', 'cm2', 'kN', 'kN'};

  % ブレース断面インデックス（secb用）
  idsb_tb = find( ...
    secb.tctype == PRM.BRACE_TENSION);
  tblist = getListRecord( ...
    secmgr, secdim(isTB, end-1:end));
  bsbody = cell(ntb, 8);
  for i = 1:ntb
    isb = idsb_tb(i);
    bsbody{i,1} = secb.name{isb};
    bsbody{i,2} = tblist.type{i};
    bsbody{i,3} = sprintf('%.2f', ...
      tblist.A(i));
    bsbody{i,4} = sprintf('%.2f', ...
      tblist.Ae(i));
    bsbody{i,5} = sprintf('%.1f', ...
      tblist.Ta(i));
    bsbody{i,6} = sprintf('%.1f', ...
      tblist.Tu(i));
    bsbody{i,7} = tblist.HTB{i};
    bsbody{i,8} = tblist.GP{i};
  end
elseif any(isBRB)
  % BRB断面リスト出力
  bshead = cell(2, 4);
  bshead(1, 1:4) = { ...
    '符号', '種類', '品番', '断面積'};
  bshead(2, 4) = {'cm2'};

  nbrb_ = sum(isBRB);
  secblist = getListRecord( ...
    secmgr, secdim(isBRB, end-1:end));
  bsbody = cell(nbrb_, 4);
  for i = 1:nbrb_
    bsbody{i, 1} = secb.name{i};
    bsbody{i, 2} = secb.type_name{i};
    bsbody{i, 3} = secblist.symbol{i};
    bsbody{i, 4} = ...
      sprintf('%.1f', secblist.A(i));
  end
else
  bshead = cell(2, 4);
  bshead(1, 1:4) = { ...
    '符号', '種類', '品番', '断面積'};
  bshead(2, 4) = {'cm2'};
  bsbody = cell(0, 4);
end

return
end
