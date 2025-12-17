function idmeb = find_idbrace_from_idxyz(idx, idy, idz, member_brace)
n = size(idx,1);
idmeb = zeros(n,1);

% 通り番号から梁部材番号の検索
idxlist = member_brace.idx;
idylist = member_brace.idy;
idzlist = member_brace.idz;
iddd = (1:size(member_brace,1))';
for i=1:n
  id = iddd(...
    (idxlist(:,1) == idx(i,1)) & (idxlist(:,2) == idx(i,2)) & ...
    (idylist(:,1) == idy(i,1)) & (idylist(:,2) == idy(i,2)) & ...
    (idzlist(:,1) == idz(i,1)) & (idzlist(:,2) == idz(i,2)));
  if ~isempty(id)
    idmeb(i) = id;
  end
end

return
end

