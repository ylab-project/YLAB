function Cc = calc_modified_Cc(rs, idnm2mc, idmc2m)
%calc_modified_Cc - 名目柱の修正係数Ccを算定
%
%   Cc = calc_modified_Cc(rs, idnm2mc, idmc2m) は、名目柱ごとに柱脚と
%   柱頭の曲げモーメントから、許容曲げ応力度の修正係数C（SS7計算編
%   式2.16）を局所y軸・z軸まわりについて荷重ケース別に算定する。
%   横座屈区間の端部は名目柱の柱脚と柱頭とし、曲げモーメントは最下
%   部材のi端と最上部材のj端の値を用いる。柱横補剛の入力で区間が
%   分かれる場合もこの両端の値を用いる（区間端の曲げモーメントの
%   評価は柱横補剛の対応時に扱う）。符号は名目梁の calc_modified_Cn
%   と同じくi端の値を反転して曲げモーメント図の符号に揃える。
%   H形鋼柱の強軸まわりの fb にだけ使うが、柱の向きによらず局所y軸・
%   z軸の両方の値を返す。
%
%   入力引数:
%     rs      - 部材応力 [nme×12×nlc]
%     idnm2mc - 名目柱→柱部材（柱脚側から順）[nnc×nsub]、空きは0
%     idmc2m  - 柱部材→部材番号 [nmc×1]
%
%   出力引数:
%     Cc - 名目柱の修正係数 [nnc×2×nlc]
%          （1列:局所y軸まわり、2列:局所z軸まわり）

% 計算の準備
nnc = size(idnm2mc, 1);
nlc = size(rs, 3);
nsub = sum(idnm2mc > 0, 2);
im_bot = idmc2m(idnm2mc(:, 1));
im_top = idmc2m(idnm2mc(sub2ind(size(idnm2mc), (1:nnc)', nsub)));

% 柱脚（最下部材のi端）と柱頭（最上部材のj端）の曲げモーメントから
% 局所y軸・z軸まわりのCを算定する。要素ごとの計算なので両軸・全ケース
% をまとめて渡す
Cc = reshape(calc_modified_C_ends(-rs(im_bot, [5 6], :), ...
  rs(im_top, [11 12], :)), nnc, 2, nlc);

return
end
