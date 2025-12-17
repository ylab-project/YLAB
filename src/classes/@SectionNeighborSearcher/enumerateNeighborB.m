function [xlist, xup, xdw, idvlist] = ...
  enumerateNeighborB(obj, xvar, idvar, options)
%enumerateNeighborB フランジ幅Bの近傍断面を列挙
%   [xlist, xup, xdw, idvlist] = enumerateNeighborB(obj, xvar, idvar,
%     options) は、指定変数のフランジ幅Bについて近傍断面を列挙します。
%
%   注：H, Bは単一変数のみを変更するため、idwfs計算は不要です。
%
%   入力引数:
%     xvar    - 現在の変数値 [nvar×1]
%     idvar   - 対象変数ID (スカラー)
%     options - オプション構造体
%
%   出力引数:
%     xlist   - 近傍解の変数値リスト [n×nvar]
%     xup     - 上位方向の近傍解 [nup×nvar]
%     xdw     - 下位方向の近傍解 [ndw×nvar]
%     idvlist - インデックス構造体

% 対象かチェック
nx = length(xvar);
xlist = zeros(0, nx);
xup = zeros(0, nx);
xdw = zeros(0, nx);

% WFS断面の変数IDを取得
idsec2var = obj.idMapper_.idsec2var;
idsec2stype = obj.idMapper_.idsec2stype;
idwfs2x = idsec2var(idsec2stype == PRM.WFS, 1:4);

if isempty(idvar)
  return
end

if all(idwfs2x(:,PRM.SECDIM_WFS_B) ~= idvar)
  return
end

% 計算準備
idslist = obj.idMapper_.getIdSlistofVar(idvar);
if isempty(idslist)
  return
end

% B公称値を取得（配列対応）
nslist = length(idslist);
if nslist == 1
  % 単一リストはそのまま処理（最も効率的）
  Bnset = obj.standardAccessor_.getNominalB(idslist);
else
  % 複数リストはcell配列で結合
  values = cell(nslist, 1);
  for i = 1:nslist
    values{i} = obj.standardAccessor_.getNominalB(idslist(i));
  end
  Bnset = unique(vertcat(values{:}));
end

% 現在値
B0 = xvar(idvar);
iddd = 1:length(Bnset);
idst0 = iddd(Bnset == B0);

% 1サイズアップ
idstup = idst0 + 1;
if idstup > length(Bnset)
  idstup = [];
end

% 1サイズダウン
idstdw = idst0 - 1;
if idstdw < 1
  idstdw = [];
end

% 近傍解集合
idstud = [idstup idstdw];
n = length(idstud);
nup = length(idstup);
ndw = length(idstdw);
xlist = repmat(xvar, n, 1);
for i = 1:n
  xlist(i, idvar) = Bnset(idstud(i));
end
xup = xlist(1:nup, :);
xdw = xlist(nup+1:end, :);
idvlist.up = 1:nup;
idvlist.dw = nup+1:nup+ndw;

return
end