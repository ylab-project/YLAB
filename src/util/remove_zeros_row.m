function A = remove_zeros_row(A)
%REMOVE_DUPICATED_ROW この関数の概要をここに記述
%   詳細説明をここに記述

n = size(A,1);
is_nonzero = true(n,1);
for i=1:n
  if(all(A(i,:)==0))
    is_nonzero() = false;
  end
end
A = A(is_nonzero,:);

return
end

