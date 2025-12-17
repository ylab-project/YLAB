function write_csv_constraint_problem(result, options, cvec, fout)

% 準備
% nvar = com.nvar;
% nnode = com.nnode;
% nme = com.nme;

% 制約条件の分類
clabel = result.conlabel;
ncon = result.ncon;
tau = options.tau;
% [maxvio, idmaxvio, idmaxvioc, ccategory] = ...
%   extract_convio(ncon, ccon, tau, cvec);

% 制約条件番号
ncvec = length(cvec);
mcon = length(clabel);
n2con = cumsum(ncon);
n1con = [1 n2con(1:mcon-1)+1];

% 制約条件情報
mcell = 8;
head = cell(1,mcell);
head(1,1:8) = {'制約種類','開始番号','終了番号','条件数', ...
  'アクティブ条件数','違反条件数','最大違反番号','最大違反量'};
body = cell(mcon,mcell);
body(1:mcon,1) = clabel;
for ic = 1:mcon
  if ncon(ic)==0
    continue
  end
  body{ic,2} = n1con(ic);
  body{ic,3} = n2con(ic);
  body{ic,4} = ncon(ic);
  % body{ic,5} = sum(cvec(n1con(ic):n2con(ic))>=-0.1);
  body{ic,5} = sum(cvec(n1con(ic):n2con(ic))>=options.tolActive);
  body{ic,6} = sum(cvec(n1con(ic):n2con(ic))>tau);
  [viocon, id] = max(cvec(n1con(ic):n2con(ic)));
  if viocon>tau
    body{ic,7} = id+n1con(ic)-1;
    body{ic,8} = viocon;
  end
end

% 制約違反量
fprintf(fout, 'name=制約違反量\n');
write_csv_from_cell(fout, head, body);
fprintf(fout, ',\n,\n');

% 制約関数値
mcell = 20;
ncell = ceil(ncvec/mcell);
body = cell(ncell,mcell);
for i=1:ncell
  for j=1:mcell
    id = (i-1)*mcell+j;
    if id>ncvec
      continue
    end
    body{i,j} = cvec(id);
  end
end
  
fprintf(fout, 'name=制約関数値\n');
write_csv_from_cell(fout, [], body);
fprintf(fout, ',\n,\n');

end