function write_csv_from_cell(fid, head, body, modeSS7)

if nargin==3
  modeSS7 = true;
end

write_csv_from_cell_(fid, head)
if modeSS7
  fprintf(fid, '<data>\n');
end
write_csv_from_cell_(fid, body)
end

function write_csv_from_cell_(fid, tab)
[n,m] = size(tab);
isempty_row = true(1,n);
for i=1:n
  for j=1:m
    if ~isempty(tab{i,j})
      isempty_row(i) = false;
    end
  end
end

for i=1:n
  if isempty_row(i)
    continue
  end
  for j=1:m
    if j==m
      delimeter = '';
    else
      delimeter = ',';
    end
    if isnumeric(tab{i,j})
      fprintf(fid, ['%g' delimeter], tab{i,j});
    else
      fprintf(fid, ['%s' delimeter], tab{i,j});
    end
  end
  fprintf(fid, '\n');
end
end

