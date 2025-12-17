function [A, TF] = unique_vertcat(A, B)
if isempty(A)
  A = B;
  return
end
TF = true(size(B,1),1);
% for i=1:size(A,1)
%   for j=1:size(B,1)
%     if(all(A(i,:)-B(j,:)==0))
%       TF(i) = false;
%       break
%     end
%   end
% end
A = [A; B(TF,:)];
return
end

