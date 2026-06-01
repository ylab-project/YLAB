function [bshead, bsbody] = ...
  write_cell_brace_manufacturer_section_list_ss7( ...
    secb, stype, secdim, secmgr)
%write_cell_brace_manufacturer_section_list_ss7 - メーカー製品断面リスト
%
%   [bshead, bsbody] = ...
%     write_cell_brace_manufacturer_section_list_ss7( ...
%     secb, stype, secdim, secmgr) は、
%   鉛直ブレース断面リスト（メーカー製品）を返す。
%   対象種別は座屈拘束ブレース（BRB）およびその他（OTS）。
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

mfg_types = [PRM.BRB, PRM.OTS];
is_mfg = ismember(stype, mfg_types);
idx_mfg = find(ismember(secb.type, mfg_types));
nmfg_ = numel(idx_mfg);

bshead = cell(2, 4);
bshead(1, 1:4) = {'符号', '種類', '品番', '断面積'};
bshead(2, 4) = {'cm2'};

if nmfg_ > 0
  secblist = getListRecord(secmgr, secdim(is_mfg, :));
  bsbody = cell(nmfg_, 4);
  for i = 1:nmfg_
    ib = idx_mfg(i);
    bsbody{i, 1} = secb.name{ib};
    bsbody{i, 2} = secb.type_name{ib};
    bsbody{i, 3} = secblist.symbol{i};
    bsbody{i, 4} = sprintf('%.2f', secblist.A(i));
  end
else
  bsbody = cell(0, 4);
end

return
end
