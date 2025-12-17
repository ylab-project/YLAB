function Hstdid = find_idHst(Hset, Hnominal)
%FIND_HSTDID この関数の概要をここに記述
%   詳細説明をここに記述

n = length(Hset);
Hstdid = zeros(1,n);
for i=1:n
  id = find(Hnominal == Hset(i));
  Hstdid(i) = id;
end

return
end

