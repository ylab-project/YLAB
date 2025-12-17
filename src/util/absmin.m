function Mmin = absmin(M1, M2)
% Mlist = [M1, M2];
% Mmin = Mlist(abs(Mlist) == min(abs(Mlist)));
% Mmin = Mmin(1);
if nargin == 1
    Mmin = M1;
    return
end

if abs(M1)<=abs(M2)
    Mmin = M1;
else
    Mmin = M2;
end

end

