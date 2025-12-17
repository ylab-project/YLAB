function [xlist, xup, xdw, idvlist] = ...
  enumerateNeighborH(obj, xvar, idvar, options, delta)
%enumerateNeighborH 梁せいHの近傍断面を列挙
%   [xlist, xup, xdw, idvlist] = enumerateNeighborH(obj, xvar, idvar,
%     options, delta) は、指定変数の梁せいHについて近傍断面を列挙します。
%
%   注：H, Bは単一変数のみを変更するため、idwfs計算は不要です。
%
%   入力引数:
%     xvar    - 現在の変数値 [nvar×1]
%     idvar   - 対象変数ID (スカラー)
%     options - オプション構造体
%     delta   - 探索範囲 (mm、省略可能、既定値: 150)
%
%   出力引数:
%     xlist   - 近傍解の変数値リスト [n×nvar]
%     xup     - 上位方向の近傍解 [nup×nvar]
%     xdw     - 下位方向の近傍解 [ndw×nvar]
%     idvlist - インデックス構造体
%               .up: 上位解のインデックス
%               .dw: 下位解のインデックス

if nargin == 4
  delta = 150;
end

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

if all(idwfs2x(:,PRM.SECDIM_WFS_H) ~= idvar)
  return
end

% 変数に対応する断面リストIDを取得
idslist = obj.idMapper_.getIdSlistofVar(idvar);
if isempty(idslist)
  return
end

% H公称値を取得（配列対応）
nslist = length(idslist);
if nslist == 1
  % 単一リストはそのまま処理（最も効率的）
  Hnset = obj.standardAccessor_.getNominalH(idslist);
else
  % 複数リストはcell配列で結合
  values = cell(nslist, 1);
  for i = 1:nslist
    values{i} = obj.standardAccessor_.getNominalH(idslist(i));
  end
  Hnset = unique([values{:}]);
  Hnset = Hnset(:);
end

% 現在値とその位置を特定
H_current = xvar(idvar);
idx_current = find(Hnset == H_current);

% 上位方向の探索（delta範囲内）
H_upper_limit = min(H_current + delta, max(Hnset));

% H_upper_limit以上で最小の値のインデックスを探す
idx_candidates = find(Hnset >= H_upper_limit);
if ~isempty(idx_candidates)
  idx_upper = idx_candidates(1);  % 最小のものを選択
else
  idx_upper = length(Hnset);      % なければ最大値のインデックス
end
idx_up_range = setdiff(idx_current:idx_upper, idx_current);

% 下位方向の探索（delta範囲内）
H_lower_limit = max(H_current - delta, min(Hnset));

% H_lower_limit以下で最大の値のインデックスを探す
idx_candidates = find(Hnset <= H_lower_limit);
if ~isempty(idx_candidates)
  idx_lower = idx_candidates(end);  % 最大のものを選択
else
  idx_lower = 1;                    % なければ最小値のインデックス
end
idx_down_range = fliplr(setdiff(idx_lower:idx_current, idx_current));

% 近傍解集合の構築
idx_neighbors = [idx_up_range idx_down_range];
n_total = length(idx_neighbors);
n_up = length(idx_up_range);
n_down = length(idx_down_range);

% 変数値リストの作成
xlist = repmat(xvar, n_total, 1);
for i = 1:n_total
  xlist(i, idvar) = Hnset(idx_neighbors(i));
end

% 上位・下位の分離
xup = xlist(1:n_up, :);
xdw = xlist(n_up+1:end, :);
idvlist.up = 1:n_up;
idvlist.dw = n_up+1:n_up+n_down;

return
end