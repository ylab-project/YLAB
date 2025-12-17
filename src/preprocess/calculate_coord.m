function coord = calculate_coord(span)
n = size(span,1);
coord = zeros(n+1,1);

% TODO: 要見直し
sum = 0;
for i=1:n
  sum = sum+span(i);
  coord(i+1) = sum;
end
return
end