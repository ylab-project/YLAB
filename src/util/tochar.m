function c = tochar(a)
%tochar - 各種型を文字列に変換するユーティリティ

% missing値は空文字に変換
if ismissing(a)
  c = '';
  return
end

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

