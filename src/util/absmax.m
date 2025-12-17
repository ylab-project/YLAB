function Mmax = absmax(M1, M2)
if nargin == 1
    Mmax = M1;
    return
end

if abs(M1)>=abs(M2)
    Mmax = M1;
else
    Mmax = M2;
end
% if nargin == 1
%   Mlist = M1;
% else
%   Mlist = [M1, M2];
% end
% Mmax = Mlist(abs(Mlist) == max(abs(Mlist)));
% Mmax = Mmax(1);
end

