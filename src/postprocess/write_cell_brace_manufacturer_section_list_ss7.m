function [bshead, bsbody] = write_cell_brace_manufacturer_section_list_ss7(secb, stype, secdim, secmgr)
%WRITE_CELL_BRACE_MANUFACTURER_SECTION_LIST_SS7 メーカー製ブレース断面リストの書き出し処理（SS7形式）
%   [bshead, bsbody] = write_cell_brace_manufacturer_section_list_ss7(secb, stype, secdim, secmgr)
%   鉛直ブレース断面リスト（メーカー製品：BRB）のSS7形式での書き出しを行います。
%
%   入力引数:
%     secb   - ブレース断面情報構造体
%     stype  - 断面タイプ配列
%     secdim - 断面寸法配列
%     secmgr - SectionManagerオブジェクト
%
%   出力引数:
%     bshead - ブレース断面リストのヘッダー
%     bsbody - ブレース断面リストの本体
%
%   例:
%     [bshead, bsbody] = write_cell_brace_manufacturer_section_list_ss7(secb, stype, secdim, secmgr);

% BRBとHSRの判定
isBRB = (stype == PRM.BRB);
isHSR = (stype == PRM.HSR);
nbrb = sum(isBRB);
nhsr = sum(isHSR);

% ヘッダー設定
bshead = cell(2, 4);
bshead(1, 1:4) = {'符号', '種類', '品番', '断面積'};
bshead(2, 4) = {'cm2'};

% 本体の初期化
bsbody = cell(nbrb, 4);
irow = 0;

% BRB断面の処理（メーカー製品）
if any(isBRB)
  % BRB断面のリスト取得
  secblist = getListRecord(secmgr, secdim(isBRB, end-1:end));

  % BRB断面の出力
  for i = 1:nbrb
    irow = irow + 1;
    bsbody{irow, 1} = secb.name{i};
    type_name = secb.type_name{i};
    bsbody{irow, 2} = type_name;
    bsbody{irow, 3} = secblist.symbol{i};
    bsbody{irow, 4} = sprintf('%.1f', secblist.A(i));
  end
end

% HSR断面の処理は現在コメントアウトされているため含まない
% 将来的にHSR断面の処理が必要になった場合はここに追加

end