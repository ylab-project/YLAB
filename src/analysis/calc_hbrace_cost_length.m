function lm = calc_hbrace_cost_length(hbrace, node)
%calc_hbrace_cost_length - 水平ブレース積算用部材長を算出
%
%   lm = calc_hbrace_cost_length(hbrace, node) は、
%   SS7積算マニュアル(4.4.7)に基づき、水平ブレースの
%   積算用部材長を算出する。節点間3D距離を返す。
%
%   入力引数:
%     hbrace - 水平ブレース部材構造体
%     node   - 節点構造体
%
%   出力引数:
%     lm - 積算用部材長 [nhb×1] (mm)

nhb = numel(hbrace.idme);
lm = zeros(nhb, 1);

for ib = 1:nhb
  in1 = hbrace.idnode1(ib);
  in2 = hbrace.idnode2(ib);
  dx = node.x(in2) - node.x(in1);
  dy = node.y(in2) - node.y(in1);
  dz = node.z(in2) - node.z(in1);
  lm(ib) = sqrt(dx^2 + dy^2 + dz^2);
end

return
end
