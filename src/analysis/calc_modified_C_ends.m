function C = calc_modified_C_ends(Ma, Mb)
%calc_modified_C_ends - 座屈区間の端部モーメントから修正係数Cを算定
%
%   C = calc_modified_C_ends(Ma, Mb) は、座屈区間の両端の曲げモーメント
%   Ma・Mb から許容曲げ応力度の修正係数（SS7計算編 式2.16）
%   C = 1.75 − 1.05·(M2/M1) + 0.3·(M2/M1)^2 を要素ごとに算定し、
%   上限2.3で打ち切る。M1は絶対値の大きい方、M2は小さい方とする。
%   Ma・Mb は曲げモーメント図の符号（単曲率で同符号、複曲率で
%   異符号）で与える。両端とも0の区間は曲げがなく C=1 とする。
%
%   入力引数:
%     Ma - 区間の一端の曲げモーメント [n×1]
%     Mb - 区間の他端の曲げモーメント [n×1]
%
%   出力引数:
%     C  - 修正係数 [n×1]（1以上2.3以下）

Ma = Ma(:);
Mb = Mb(:);

% 絶対値の大きい方をM1にする。同じ大きさのときはMaをM1にする
M1 = Ma;
M2 = Mb;
swap = abs(Mb) > abs(Ma);
M1(swap) = Mb(swap);
M2(swap) = Ma(swap);

% 端部モーメント比。両端とも0の区間は C=1
ratio = zeros(size(M1));
nz = M1 ~= 0;
ratio(nz) = M2(nz)./M1(nz);
C = 1.75 - 1.05*ratio + 0.3*ratio.^2;
C(~nz) = 1;
C = min(C, 2.3);

return
end
