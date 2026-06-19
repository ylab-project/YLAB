function depth = calc_girder_section_depth(secdim, girder_type, idsec)
%calc_girder_section_depth - 梁断面タイプに応じた梁せいを取得
%
%   depth = calc_girder_section_depth(secdim, girder_type, idsec) は、
%   梁断面タイプと統一断面IDから、柱側幾何で使う梁せいを返す。
%   RC梁は secdim の2列目、S梁は1列目を参照する。
%
%   入力引数:
%     secdim      - 断面寸法配列 [nsec×ncol]
%     girder_type - 梁断面タイプ [n×1]
%     idsec       - 統一断面ID [n×1]
%
%   出力引数:
%     depth - 梁せい [n×1]

girder_type = girder_type(:);
idsec = idsec(:);
depth = zeros(size(idsec));

is_rc = girder_type == PRM.RCRS;
depth(is_rc) = secdim(idsec(is_rc), 2);
depth(~is_rc) = secdim(idsec(~is_rc), 1);

return
end
