function f = calc_cantilever_nodal_force(r, c_base, c_tip, q_base, q_tip)
%calc_cantilever_nodal_force - 片持梁C・Qoを取付節点の6成分へ縮約する
%
%   f = calc_cantilever_nodal_force(r, c_base, c_tip, q_base, q_tip)
%   は、SS7の梁CMoQoと同じ規則（C=固定端モーメント、Qo=単純支持の
%   せん断力、下向きの荷重による値を正）で入力された片持梁の4荷重
%   項を、元端（取付節点）へ作用する全体座標系の力・モーメント
%   6成分へ縮約する（内部設計3章）。
%
%   固定端せん断は Qo へモーメント線せん断 (元端C+先端C)/L を加えて
%   構成する（SS7計算編6.3.9と同形）。補正分母 L は元端－先端
%   ベクトル r の実長とし、先端移動が0の場合は跳ね出し長さに一致
%   する（SS7入力編7.9）。曲げ軸 e2' は部材軸の水平成分から定め、
%   先端移動左右が非零のとき r×Fj が e1 回りのモーメント成分を
%   生む。先端移動0では F=-(元端Qo+先端Qo)・ez、元端まわり
%   M=先端Qo・L・e2 へ退化する（KG01の片持梁CMoQo表と照合済み）。
%
%   入力引数:
%     r      - 元端から先端への全体座標系ベクトル [1×3]（mm）
%     c_base - 元端C（N.mm）
%     c_tip  - 先端C（N.mm）
%     q_base - 元端Qo（N）
%     q_tip  - 先端Qo（N）
%
%   出力引数:
%     f - 取付節点へ作用する全体座標系の6成分 [Fx Fy Fz Mx My Mz]
%         （N・N.mm）
ez = [0, 0, 1];
length_actual = norm(r);
t = r / length_actual;
t_h = [t(1), t(2), 0];
e2p = cross(ez, t_h) / norm(t_h);

% 固定端せん断（下向き荷重正のQoは全体Z負方向の力になる）
shear_corr = (c_base + c_tip) / length_actual;
force_base = -(q_base + shear_corr) * ez;
force_tip = -(q_tip - shear_corr) * ez;
moment_base = c_base * e2p;
moment_tip = c_tip * e2p;

f = [force_base + force_tip, moment_base + moment_tip ...
  + cross(r, force_tip)];

return
end
