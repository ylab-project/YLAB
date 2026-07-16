function [Dmat, H, idtstory2H, Hmax, idtstory2Hmax] = ...
  Hdiff_matrix(xvar, height_smooth, options)
%Hdiff_matrix - 梁せい変数の差分行列を取得
%
%   [Dmat, H, idtstory2H, Hmax, idtstory2Hmax] = Hdiff_matrix(...
%     xvar, height_smooth, options) は、梁せい平滑化用の差分行列と
%   梁せいを取得する。MAX方式では現在の梁せいに応じた層代表値を
%   更新し、AXIS方式では初期化時に作成した固定行列を使用する。
%
%   入力引数:
%     xvar          - 断面変数
%     height_smooth - 梁せい平滑化の固定データ
%     options       - 解析オプション
%
%   出力引数:
%     Dmat          - 層方向の一次差分行列
%     H             - 梁せい変数
%     idtstory2H    - 層・通りごとの局所梁せいID
%     Hmax          - 各層の最大梁せい
%     idtstory2Hmax - 各層の最大梁せいに対応する局所ID

idvarH = height_smooth.idvarH;
idstory2varH = height_smooth.idstory2varH_target;
idtstory2H = height_smooth.idtstory2H;
H = xvar(idvarH);
nH = numel(idvarH);
ntstory = size(idstory2varH, 1);

Hmax = zeros(ntstory, 1);
idtstory2Hmax = zeros(ntstory, 1);
switch options.coptions.alfa_girder_height_smooth_var
  case PRM.GIRDER_HEIGHT_SMOOTH_MAX
    for i = 1:ntstory
      ids2vH = idstory2varH(i, :);
      ids2vH = ids2vH(ids2vH > 0);
      [Hmax(i), id] = max(xvar(ids2vH));
      idtstory2Hmax(i) = find(idvarH == ids2vH(id), 1);
    end
    Dmat = create_difference_matrix(idtstory2Hmax, nH);

  case PRM.GIRDER_HEIGHT_SMOOTH_AXIS
    Dmat = height_smooth.Dmat_axis;
end
return
end

