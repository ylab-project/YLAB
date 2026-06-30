function z = girder_center_z_standard(z_standard, level, Hg)
%girder_center_z_standard - 標準階高基準の梁部材心Zを返す
%
%   z = girder_center_z_standard(z_standard, level, Hg) は、
%   標準階高基準の節点Z、梁レベル調整、梁せいから梁部材心の
%   Z座標を返す。
%
%   入力引数:
%     z_standard - 標準階高基準の節点Z
%     level      - 梁レベル調整
%     Hg         - 梁せい
%
%   出力引数:
%     z - 梁部材心Z

z = z_standard + level - Hg / 2;

return
end
