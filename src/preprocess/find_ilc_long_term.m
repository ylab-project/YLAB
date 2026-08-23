function ilc = find_ilc_long_term(loadcase)
%find_ilc_long_term - 長期解析ケース（G+P）の番号を返す
%
%   ilc = find_ilc_long_term(loadcase) は、方向が長期の荷重ケース番号
%   を返す。重量ブロックの共通・ラーメン用の行はこのケースへ加算する。
%   長期ケースがない入力では0を返し、呼び出し側は解析非計上として
%   扱う。
%
%   入力引数:
%     loadcase - 荷重ケーステーブル（dir列を参照）
%
%   出力引数:
%     ilc - 長期解析ケース番号。長期ケースがない場合は0
ilc = find(loadcase.dir == PRM.LT, 1);
if isempty(ilc)
  ilc = 0;
end

return
end
