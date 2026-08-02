function write_csv_constraint_problem(result, options, cvec, fout)
%write_csv_constraint_problem - 制約条件の違反量・関数値をCSV出力
%
%   write_csv_constraint_problem(result, options, cvec, fout) は、
%   制約種類ごとの違反量集計（制約違反量）と全制約関数値（制約関数値）の
%   2 ブロックを fout に書き出す。
%
%   入力引数:
%     result  - 解析結果構造体 (conlabel, ncon を含む)
%     options - オプション構造体 (tau, tolActive を含む)
%     cvec    - 制約関数値ベクトル
%     fout    - 出力先ファイル識別子

% 制約条件の分類
clabel = result.conlabel;
ncon = result.ncon;
tau = options.tau;

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
  body{ic,5} = sum(cvec(n1con(ic):n2con(ic))>=options.tolActive);
  body{ic,6} = sum(cvec(n1con(ic):n2con(ic))>tau);
  convec = cvec(n1con(ic):n2con(ic));
  [viocon, ~] = max(convec);
  if viocon > tau
    % CSV表示が同値の最大違反は最小番号に統一
    viocon_text = sprintf('%g', viocon);
    is_display_max = strcmp(compose('%g', convec), viocon_text);
    id = find(is_display_max, 1);
    body{ic,7} = id+n1con(ic)-1;
    body{ic,8} = viocon;
  end
end

% 制約違反量
fprintf(fout, '\n\nname=制約違反量\n');
write_csv_from_cell(fout, head, body, true, true);

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

fprintf(fout, '\n\nname=制約関数値\n');
write_csv_from_cell(fout, [], body, true, true);

return
end