function rho = calc_rc_density(Fc)
%calc_rc_density - Fcに応じたRC部材の密度を返す
%
%   rho = calc_rc_density(Fc) は、SS7マニュアル表2.1に
%   基づき、Fcに応じた鉄筋コンクリートの密度を返す。
%
%   入力引数:
%     Fc - 設計基準強度 [N/mm2]（スカラーまたは配列）
%
%   出力引数:
%     rho - RC密度 [t/m3]（Fcと同サイズ）
%
%   備考:
%     - SS7計算編 2.1.1 表2.1 に準拠
%     - 軽量コンクリートには未対応（将来課題）
%     - SRC造は呼び出し側で +1 kN/m3 を加算すること

% 単位容積重量 [kN/m3]（SS7マニュアル表2.1）
gamma = 24.0 * ones(size(Fc));
gamma(Fc > 36) = 24.5;
gamma(Fc > 48) = 25.0;
gamma(Fc > 60) = 25.5;
gamma(Fc > 80) = 26.0;

% kN/m3 → t/m3 に変換: gamma / g
rho = gamma / PRM.GRAVITY;

return
end
