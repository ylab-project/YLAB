function outer_size = calc_column_outer_size(secdim, stype, rc_size_column)
%calc_column_outer_size - 柱のX・Y方向の外形寸法を取得
%
%   outer_size = calc_column_outer_size(secdim, stype, rc_size_column)
%   は、断面寸法と断面タイプから、フェイス位置・柱面控除に使う柱の
%   X方向・Y方向の外形寸法を返す。X方向強軸のH形鋼柱はせいHが
%   X方向、フランジ幅BがY方向、Y方向強軸のH形鋼柱はその逆、
%   角形鋼管・円形鋼管はD×Dとする。RC柱は用途で読む列が異なる
%   （フェイス位置と座屈長の柱面控除は第1列の断面寸法、自重・積算用の
%   柱面控除は第3列の荷重剛性用寸法）ため、指定された列の寸法を両方向に
%   用いる。
%   柱以外（梁、ブレース）は0を返す。
%
%   入力引数:
%     secdim         - 断面寸法配列 [n×ncol]
%     stype          - 断面タイプ [n×1]
%     rc_size_column - RC柱の外形として読むsecdimの列番号 (scalar)
%
%   出力引数:
%     outer_size - 外形寸法 [n×2]（列1: X方向、列2: Y方向）

stype = stype(:);
outer_size = zeros(numel(stype), 2);

is_h = stype == PRM.CWFS;
outer_size(is_h, :) = secdim(is_h, [1 2]);
is_i = stype == PRM.CWFSI;
outer_size(is_i, :) = secdim(is_i, [2 1]);
is_tube = stype == PRM.HSS | stype == PRM.HSR;
outer_size(is_tube, :) = secdim(is_tube, [1 1]);
is_rc = stype == PRM.RCRS;
outer_size(is_rc, :) = secdim(is_rc, [rc_size_column rc_size_column]);

return
end
