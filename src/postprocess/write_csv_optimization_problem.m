function write_csv_optimization_problem(com, result, options, fval, cvec, fout)

% 準備
nvar = com.nvar;
nnode = com.nnode;
nme = com.nme;
nvar_free = nnz(com.design.variable.isvar);

% 制約条件の分類
clabel = result.conlabel;
ncon = result.ncon;
tau = options.tau;
[maxvio, idmaxvio, idmaxvioc, ccategory] = ...
  extract_convio(ncon, clabel, tau, cvec);

% 制約条件番号
% mcon = length(ccon);
% n2con = cumsum(ncon);
% n1con = [1 n2con(1:mcon-1)+1];

% 最適化問題その１
fprintf(fout, 'name=最適化問題\n');
mcell = 5;
head = cell(1,mcell);
head(1,1:mcell) = {...
  '設計変数数','固定変数数','制約条件数','節点数','部材数'};
body = cell(1,mcell);
body{1} = nvar_free;
body{2} = nvar-nvar_free;
body{3} = sum(ncon);
body{4} = nnode;
body{5} = nme;
write_csv_from_cell(fout, head, body, false);

% 最適化問題その２
mcell = 6;
head = cell(1,mcell);
head(1,1:mcell) = {...
  '目的関数値', '最大違反量', '制約条件番号', '制約種類', '種類内番号', ...
  'アクティブ閾値'};
body = cell(1,mcell);
body{1} = fval;
body{2} = maxvio;
body{3} = idmaxvio;
body{4} = ccategory;
body{5} = idmaxvioc;
body{6} = options.tolActive;
write_csv_from_cell(fout, head, body, false);
fprintf(fout, ',\n,\n');
end