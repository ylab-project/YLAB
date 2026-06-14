function [n, lb_report, has_report] = ...
  get_stiffening_lb_report(nominal_girder, ing, n)
%get_stiffening_lb_report - 帳票用の補剛数とLb配列を取得
%
%   [n, lb_report, has_report] = get_stiffening_lb_report( ...
%     nominal_girder, ing, n) は、名目梁 ing の帳票用 Lb1-Lb4 を
%   返す。保持値がない場合は has_report=false とする。

lb_report = nan(1, 4);
has_report = false;

if ~has_table_field(nominal_girder, 'stiffening_lb_report')
  return
end

if has_table_field(nominal_girder, 'stiffening_n')
  n_ = nominal_girder.stiffening_n(ing);
  if ~ismissing(n_)
    n = n_;
  end
end

if ismissing(n)
  return
end

n = round(n);
if n < 1 || n > 4
  return
end

lb_report = nominal_girder.stiffening_lb_report(ing, :);
has_report = all(~ismissing(lb_report(1:n)));

return
end
