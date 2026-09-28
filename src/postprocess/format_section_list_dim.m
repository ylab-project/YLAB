function str = format_section_list_dim(stype, dim, symbol)
%format_section_list_dim - 断面リスト用の鉄骨断面名を生成する
%
%   str = format_section_list_dim(stype, dim, symbol) は、断面リスト、
%   S柱断面、S梁断面のブロックに書く鉄骨断面名を、断面種別が候補を
%   取る断面リストの鉄骨形状に応じた寸法の並びで生成する。寸法の
%   区切りは仮定断面の入力と同じ 'x' で、H形鋼はフィレット半径を含む
%   5寸法（r=0 のときは4寸法）、角形鋼管は D×D×t×r、円形鋼管は D×t
%   とする。
%
%   入力引数:
%     stype  - 断面種別 (PRM.WFS, PRM.CWFS, PRM.HSS, PRM.HSR 等)
%     dim    - 断面寸法ベクトル [1×ncol]
%     symbol - 断面記号文字列 ('H', '□', '○' 等)
%
%   出力引数:
%     str - 断面名文字列 (例: 'H-400x200x8x13x13', '□-250x250x9x22.5')

switch PRM.list_type_of_section_type(stype)
  case PRM.WFS
    if dim(5) == 0
      str = sprintf('%s-%gx%gx%gx%g', symbol, dim(1:4));
    else
      str = sprintf('%s-%gx%gx%gx%gx%g', symbol, dim(1:5));
    end
  case PRM.HSS
    str = sprintf('%s-%gx%gx%gx%g', symbol, dim([1 1 2 3]));
  case PRM.HSR
    str = sprintf('%s-%gx%g', symbol, dim(1:2));
  otherwise
    str = '';
end

return
end
