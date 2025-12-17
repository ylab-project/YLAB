function sec = datasfsec(Hsec, Bsec, c_g, compEffect, scallop)
if nargin==4
  scallop = 0;
end
[A, Asy, Asz, Iy, Iz, Zy, Zz, Zyf, Zpy, Zpz, JJ, Iyo, Aw] = ...
  datasf(Hsec(:,1), Hsec(:,2), Hsec(:,3), Hsec(:,4), ...
  Bsec(:,1), Bsec(:,2), c_g, compEffect, Hsec(:,5), Bsec(:,3), scallop);
sec = table(A, Asy, Asz, Iy, Iz, Zy, Zz, Zyf, Zpy, Zpz, JJ, Iyo, Aw);
end

% [A, Asy, Asz, Iy, Iz, Zy, Zz, Zyf, Zpy, Zpz, JJ, Iyo, Aw]  = ...
