function write_csv_optimization_problem(com, result, ...
  options, fval, cvec, fout)
%write_csv_optimization_problem - 最適化問題の概要をCSV出力
%
%   write_csv_optimization_problem(com, result, options, fval, cvec, fout)
%   は、設計変数数・制約条件数・目的関数値・最大違反量等の概要を
%   2 ブロック（最適化問題その１/その２）として fout に書き出す。
%
%   入力引数:
%     com     - 共通オブジェクト (nvar, nnode, nme, design 等を含む)
%     result  - 解析結果構造体 (conlabel, ncon を含む)
%     options - オプション構造体 (tau, tolActive を含む)
%     fval    - 目的関数値 (スカラ)
%     cvec    - 制約関数値ベクトル
%     fout    - 出力先ファイル識別子

% 準備
nvar = com.nvar;
nnode = com.nnode;
nme = com.nme;
nvar_free = nnz(com.design.variable.isvar);

% 制約条件の分類
clabel = result.conlabel;
ncon = result.ncon;
tau = options.tau;
[maxvio, idmaxvio, idmaxvioc, ccategory] = extract_convio( ...
  ncon, clabel, tau, cvec);

% 最適化問題その１
fprintf(fout, '\n\nname=最適化問題\n');
mcell = 5;
head = cell(1,mcell);
head(1,1:mcell) = {'設計変数数','固定変数数','制約条件数', ...
  '節点数','部材数'};
body = cell(1,mcell);
body{1} = nvar_free;
body{2} = nvar-nvar_free;
body{3} = sum(ncon);
body{4} = nnode;
body{5} = nme;
write_csv_from_cell(fout, head, body, false, true);

% 最適化問題その２
mcell = 6;
head = cell(1,mcell);
head(1,1:mcell) = {'目的関数値','最大違反量','制約条件番号', ...
  '制約種類','種類内番号','アクティブ閾値'};
body = cell(1,mcell);
body{1} = fval;
body{2} = maxvio;
body{3} = idmaxvio;
body{4} = ccategory;
body{5} = idmaxvioc;
body{6} = options.tolActive;
write_csv_from_cell(fout, head, body, false, true);

return
end