function [A, is_unique] = remove_dupicating_row(A)
%REMOVE_DUPICATED_ROW この関数の概要をここに記述
%   詳細説明をここに記述

n = size(A,1);
is_unique = true(n,1);
for i=1:(n-1)
  for j=i+1:n
    if(all(A(i,:)-A(j,:)==0))
      is_unique(i) = false;
      break
    end
  end
end
A = A(is_unique,:);

return
end

