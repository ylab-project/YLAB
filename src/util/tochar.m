function c = tochar(a)
%UNTITLED この関数の概要をここに記述
%   詳細説明をここに記述

c = a;
if ischar(a)
  return
end

if isnumeric(a)
  c = num2str(a);
end

if iscell(a)
  [m,n] = size(a);
  for i=1:m
    for j=1:n
      if isnumeric(a{i,j})
        c{i,j} = num2str(a{i,j});
      end
    end
  end
end

end

