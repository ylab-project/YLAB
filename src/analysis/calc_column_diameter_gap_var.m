function [condgap, Dgapval] = calc_column_diameter_gap_var(...
  xvar, idDgap2var, options)

% 計算の準備
tolMaxDgap = options.tolMaxDgap;

% 柱外径差の計算
Dgapval = (xvar(idDgap2var(:,1))-xvar(idDgap2var(:,2)))';
Dgapval = Dgapval(:);

% 制約違反量の計算
% TODO: 許容差のオプション指定
condgap = [Dgapval/100; (-Dgapval-tolMaxDgap)/100];
return
end

