function [cyl, cxl] = ystar(xs, ys, zs, xe, ye, ze, angle, iscolumn)
%  Direction cosines of local y* axis.  The subroutine is used only
%  when the direction cosines are not given. In which case, the y*
%  axis is assumed horizontal and directed such that Lmdaz*z is positive
%  or zero.

if nargin<8
  iscolumn = false;
end
n = size(xs,1);

l = sqrt((xe-xs).^2+(ye-ys).^2+(ze-zs).^2);
cx = (xe-xs)./l;
cy = (ye-ys)./l;
cz = (ze-zs)./l;
cxl = [cx cy cz];

albar = sqrt(cx.^2+cy.^2);
if ~iscolumn
  c1 = -cy./albar.*cos(angle)-cz.*cx./albar.*sin(angle);
  c2 = cx./albar.*cos(angle)-cy.*cz./albar.*sin(angle);
  c3 = albar.*sin(angle);
  cyl = [c1 c2 c3];
  % cyl = [-c1 -c2 -c3];
  iccc = (abs(cz)==1);
  ccc = [-sin(angle) cos(angle) zeros(length(angle),1)];
  % ccc = [cos(angle) sin(angle) zeros(length(angle),1)];
  cyl(iccc,:) = ccc(iccc,:);
else
  cyl = [-sin(angle) cos(angle) zeros(length(angle),1)];
  % cyl = [cos(angle) sin(angle) zeros(length(angle),1)];
end
return
end