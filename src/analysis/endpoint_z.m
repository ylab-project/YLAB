function [z, ig] = endpoint_z(z_std, idg, glv)
%endpoint_z - z_standard に glv を加えた端点Z座標
%
%   [z, ig] = endpoint_z(z_std, idg, glv) は、
%   z_standard に梁レベル調整を加えた値と接続梁IDを
%   返す。接続梁がなければ glv=0, ig=0。
%
%   入力引数:
%     z_std - 節点の z_standard 値
%     idg   - 接続梁の部材番号 [1×n]
%     glv   - 梁レベル調整配列
%
%   出力引数:
%     z  - glv 加算後のZ座標
%     ig - 接続梁の部材番号（0=梁なし）

z = z_std;
ig = 0;
if isempty(idg)
  return
end
ig = idg(1);
z = z + glv(ig);

return
end
