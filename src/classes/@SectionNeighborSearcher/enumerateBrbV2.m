function [xlist, xup, xdw, idvlist] = enumerateBrbV2(obj, xvar, idvar, ~)
%enumerateBrbV2 BRB V2（サブ番号）の近傍断面を列挙
%   [xlist, xup, xdw, idvlist] = enumerateBrbV2(obj, xvar, idvar,
%     options) は、指定変数のV2について近傍断面を列挙します。
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

% BRB断面の変数IDを取得
idsec2var = obj.idMapper_.idsec2var;
idsec2stype = obj.idMapper_.idsec2stype;
idbrb2x = idsec2var(idsec2stype == PRM.BRB, 1:2);

if isempty(idvar)
  return
end

if all(idbrb2x(:, PRM.SECDIM_BRB_V2) ~= idvar)
  return
end

idslist = obj.idMapper_.getIdSlistofVar(idvar);
if isempty(idslist)
  return
end

% V2規格値を取得（配列対応）
nslist = length(idslist);
if nslist == 1
  % 単一リストはそのまま処理（最も効率的）
  V2st = obj.standardAccessor_.getStandardV2(idslist);
else
  % 複数リストはcell配列で結合
  values = cell(nslist, 1);
  for i = 1:nslist
    values{i} = obj.standardAccessor_.getStandardV2(idslist(i));
  end
  V2st = unique(vertcat(values{:}));
end

% 現在値
V2cur = xvar(idvar);
iddd = 1:length(V2st);
idst_cur = iddd(V2st == V2cur);

% 1サイズアップ
idst_up = idst_cur + 1;
if idst_up > length(V2st)
  idst_up = [];
end

% 1サイズダウン
idst_dw = idst_cur - 1;
if idst_dw < 1
  idst_dw = [];
end

% 近傍解集合
idst_ud = [idst_up idst_dw];
n = length(idst_ud);
nup = length(idst_up);
ndw = length(idst_dw);
xlist = repmat(xvar, n, 1);
for i = 1:n
  xlist(i, idvar) = V2st(idst_ud(i));
end
xup = xlist(1:nup, :);
xdw = xlist(nup+1:end, :);
idvlist.up = 1:nup;
idvlist.dw = nup+1:nup+ndw;

return
end
