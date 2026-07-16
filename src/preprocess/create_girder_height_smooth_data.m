function data = create_girder_height_smooth_data(idstory2varH)
%create_girder_height_smooth_data - 梁せい平滑化の固定データを作成
%
%   data = create_girder_height_smooth_data(idstory2varH) は、層・通りと
%   梁せい変数の対応から、解析中に不変な局所ID対応とAXIS方式の
%   差分行列を作成する。
%
%   入力引数:
%     idstory2varH - 層・通りごとの梁せい変数ID
%
%   出力引数:
%     data - 梁せい平滑化の固定データ

data.idstory2varH = idstory2varH;
data.idvarH = reshape(idstory2varH(idstory2varH > 0), 1, []);
data.idvarH = unique(data.idvarH);
if isempty(data.idvarH)
  data.idstory2varH_target = zeros(0, size(idstory2varH, 2));
  data.idtstory2H = data.idstory2varH_target;
  data.Dmat_axis = zeros(0, 0);
  return
end

istarget = ~all(idstory2varH == 0, 2);
data.idstory2varH_target = idstory2varH(istarget, :);
data.idtstory2H = data.idstory2varH_target;
id_lookup = zeros(1, max(data.idvarH));
id_lookup(data.idvarH) = 1:numel(data.idvarH);
is_section = data.idtstory2H > 0;
data.idtstory2H(is_section) = id_lookup(data.idtstory2H(is_section));
data.Dmat_axis = create_difference_matrix(data.idtstory2H, ...
  numel(data.idvarH));
return
end
