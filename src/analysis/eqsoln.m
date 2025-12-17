function [d, ss] = eqsoln(s, f, nbw, ndf)
%% EQSOLN
%EQSOLN 帯対称方程式 [S][D]=[F] を解く（Cholesky＋例外時フォールバック）
%
% 概要:
%   帯行列表現 s と帯幅 nbw から疎対称行列 S を生成し、
%   Cholesky 分解で高速に解を求めます。分解に失敗した場合のみ、
%   ランク判定のうえで解の分類（不整合/一意/無限）を行い、安定な解を返します。
%
% 構文:
%   [d, ss] = eqsoln(s, f, nbw, ndf)
%
% 入力:
%   s   - 上三角ストリップ（サイズ: ndf×nbw）
%   f   - 荷重ベクトル（サイズ: ndf×NLC）
%   nbw - 帯幅（対角を含む）
%   ndf - 自由度数（Sの次数）
%
% 出力:
%   d   - 変位解（サイズ: ndf×NLC）
%   ss  - 疎対称行列 S（spdiags により生成）
%
% 例:
%   [d, S] = eqsoln(s, f, nbw, ndf);
%
% 備考:
%   正常系は Cholesky を使用。例外時のみフォールバックでランク判定と解の選択を行います。
%

% % TODO nbw, ndfは不要では
% nbw = com.nbw;
% ndf = com.ndf;

%
for i = 2:nbw
  s(i:ndf,i) = s(1:ndf-i+1,i);
end
% 帯行列 → 疎対称行列の生成
ss = spdiags(s,0:nbw-1,ndf,ndf);
% Cholesky による高速経路（失敗時のみフォールバック）
warning('off','MATLAB:nearlySingularMatrix')
try
  ds = decomposition(ss,'chol','upper');
  d = ds\f;
catch %#ok<CTCH>
  d = eqsoln_fallback_local(ss, f, ndf);
end

return
end

function d = eqsoln_fallback_local(ss, f, ndf)
%% EQSOLN_FALLBACK_LOCAL
%EQSOLN_FALLBACK_LOCAL 例外時のランク判定と解の選択（ローカル関数）
%
% 入力:
%   ss  - 疎対称行列 S（ndf×ndf）
%   f   - 荷重ベクトル（ndf×NLC）
%   ndf - 自由度数
%
% 出力:
%   d   - 変位解（不整合時は零ベクトル、無限解時は最小ノルム解）
%
% 備考:
%   rS = rank(S), rSb = rank([S f]) を用いた分類で処理します。
%
% See also: lsqminnorm, ldl, qr, rank

% 許容誤差の設定
try
  nn = normest(ss);
catch
  nn = norm(full(ss));
end
tol = max(size(ss)) * eps(max(nn,1));

% ランク推定（疎QR優先）
try
  [~, R] = qr(ss, 0);
  rS = sum(abs(diag(R)) > tol);
catch
  rS = rank(full(ss), tol);
end
rSb = rank([full(ss) full(f)], tol);

% 分岐: 不整合 / 一意 / 無限
% 不整合（解なし）
if rS < rSb
  d = zeros(ndf, size(f, 2));
  return
end

% 一意解（full rank）
if rS == size(ss, 1)
  % 一意解の解法順序: \ → LDL → 最小ノルム
  wstate = warning; c = onCleanup(@() warning(wstate));
  warning('error', 'MATLAB:singularMatrix');
  warning('error', 'MATLAB:nearlySingularMatrix');
  warning('error', 'MATLAB:rankDeficientMatrix');
  try
    d = ss \ f;
  catch
    try
      [L, D, P] = ldl(ss, 'vector');
      d = P' * (L' \ (D \ (L \ (P * f))));
    catch
      d = lsqminnorm(ss, f);
    end
  end
  return
end

% 無限解（rank-deficient だが整合）
d = lsqminnorm(ss, f);
end
