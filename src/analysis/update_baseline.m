function [baseline_xcoord, baseline_ycoord, xspan, yspan] = ...
  update_baseline(baseline, span, member_column)

% 軸ブレの平均値
% dx = (baseline.xalignment.column ...
%   +baseline.xalignment.girder)*0.5;
% dy = (baseline.yalignment.column ...
%   +baseline.yalignment.girder)*0.5;

% 部材の寄り
dx = baseline.xalignment.column;
dy = baseline.yalignment.column;

% 柱の寄りの考慮
if size(baseline.alignment_column,1)>0
  [dx, dy] = count_alignment_column(baseline, member_column);
end

% 軸座標値の更新
baseline_xcoord = calculate_coord(span.x.standard_span)+dx;
baseline_ycoord = calculate_coord(span.y.standard_span)+dy;

% 構造スパンの更新
xspan = diff(baseline_xcoord);
yspan = diff(baseline_ycoord);
end

function [acdx, acdy] = count_alignment_column(baseline, member_column)
% 定数
nx = size(baseline.x,1);
ny = size(baseline.y,1);
% nz = size(baseline.z,1);
nc = size(member_column,1);

% 共通配列
mcidx = member_column.idx(:,2);
mcidy = member_column.idy(:,2);
mcidz = member_column.idz(:,2);

% 柱の寄り
mcdxy = zeros(nc,2);
ac = baseline.alignment_column;
iddd = 1:nc;
for i=1:size(ac,1)
  im = iddd(mcidx==ac.idx(i) ...
    & mcidy==ac.idy(i) ...
    & mcidz==ac.idz(i));
  if (im>0)
    mcdxy(im,:) = [ac.dx(i) ac.dy(i)];
  end
end

% X通りの集計
acdx = zeros(nx,1);
for i=1:nx
  acdx(i) = mean(mcdxy(mcidx==i,1));
end
acdx(isnan(acdx)) = 0;

% Y通りの集計
acdy = zeros(ny,1);
for i=1:ny
  acdy(i) = mean(mcdxy(mcidy==i,2));
end
acdy(isnan(acdy)) = 0;

return
end