function ke = stif_truss_matrix(L0, A, E, J, G)
%stif_truss_matrix - 3次元トラス要素の剛性行列
%
%   ke = stif_truss_matrix(L0, A, E, J, G) は、
%   3次元トラス要素の局所座標系における12x12
%   剛性行列を返す。軸剛性とねじり剛性を持ち、
%   せん断・曲げ項はゼロ。
%
%   入力引数:
%     L0 - 部材長 [mm]
%     A  - 断面積 [mm2]
%     E  - ヤング係数 [N/mm2]
%     J  - ねじり定数 [mm4]
%     G  - せん断弾性係数 [N/mm2]
%
%   出力引数:
%     ke - 要素剛性行列（局所座標系）[12x12]
%

ke = zeros(12, 12);
kn = E * A / L0;
ke(1,1) = kn;
ke(1,7) = -kn;
ke(7,1) = -kn;
ke(7,7) = kn;

% ねじり剛性（factor_J による微小化は呼び出し元で適用済み）
kt = G * J / L0;
ke(4,4) = kt;
ke(4,10) = -kt;
ke(10,4) = -kt;
ke(10,10) = kt;

return
end
