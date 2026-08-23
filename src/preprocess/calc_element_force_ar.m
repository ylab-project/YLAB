function [ar, M0] = calc_element_force_ar(element_force, nme, nlc)
%calc_element_force_ar - 線材荷重テーブルを部材端応力配列へ加算する
%
%   [ar, M0] = calc_element_force_ar(element_force, nme, nlc) は、
%   入力アダプターが生成した線材荷重テーブルを同一要素・同一解析
%   荷重ケースで線形加算し、要素座標系の等価節点力 ar と単純梁中央
%   モーメント M0 を返す。解析非計上行は除外する（内部設計6章）。
%
%   入力引数:
%     element_force - 線材荷重テーブル（idme・ilc・ar・M0列を参照）
%     nme           - 全体部材数
%     nlc           - 荷重ケース数
%
%   出力引数:
%     ar - 要素座標系の等価節点力 [nme×12×nlc]
%     M0 - 単純梁中央モーメント [nme×nlc]
ar = zeros(nme, 12, nlc);
M0 = zeros(nme, nlc);
idme = element_force.idme;
ilc = element_force.ilc;
row_ar = element_force.ar;
row_M0 = element_force.M0;
for k = 1:length(idme)
  if ilc(k) == 0
    continue
  end
  ar(idme(k), :, ilc(k)) = ar(idme(k), :, ilc(k)) + row_ar(k, :);
  M0(idme(k), ilc(k)) = M0(idme(k), ilc(k)) + row_M0(k);
end

return
end
