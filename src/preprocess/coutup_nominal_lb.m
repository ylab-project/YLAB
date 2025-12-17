function lbn = coutup_nominal_lb(com)
%COUTUP_NOMINAL_LB この関数の概要をここに記述
%   詳細説明をここに記述

% 定数
% nnm = length(com.nominal.property.mtype);

% 計算の準備
lm = com.member.property.lm;
nominal_girder = com.nominal.girder;
nominal_column = com.nominal.column;
mtype = com.member.property.type;
nmtype = com.nominal.property.mtype;

% 梁
lbg = com.member.girder.stiffening_lb;
lbgn = calc_nominal_lb_girder(lbg, nominal_girder);

% 柱
lcm = lm(mtype==PRM.COLUMN);
lbcn = calc_nominal_lb_column(lcm, nominal_column);

% 表の結合
tmp = NaN(numel(nmtype), size(lbcn,2), 'like', lbcn{1,1});
tmp(nmtype==PRM.COLUMN , :) = lbcn{:,:};
tmp(nmtype==PRM.GIRDER , :) = lbgn{:,:};
lbn = array2table(tmp, 'VariableNames', lbcn.Properties.VariableNames);

return
end

