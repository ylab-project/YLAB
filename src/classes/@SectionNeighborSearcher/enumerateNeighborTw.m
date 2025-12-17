function [xlist, xup, xdw, idvartarget, idvlist] = ...
  enumerateNeighborTw(obj, xvar, idvar, options)
%enumerateNeighborTw ウェブ厚twの近傍断面を列挙
%   [xlist, xup, xdw, idvartarget, idvlist] = enumerateNeighborTw(obj,
%     xvar, idvar, options) は、指定変数のウェブ厚twについて近傍断面を
%     列挙します。
%
%   注：Tw, Tfは複数変数（tw, tf）を連動して変更するため、
%   　　idwfs計算が必要です（影響を受ける断面を特定）。
%
%   入力引数:
%     xvar    - 現在の変数値 [nvar×1]
%     idvar   - 対象変数ID (スカラー)
%     options - オプション構造体
%
%   出力引数:
%     xlist       - 近傍解の変数値リスト [n×nvar]
%     xup         - 上位方向の近傍解 [nup×nvar]
%     xdw         - 下位方向の近傍解 [ndw×nvar]
%     idvartarget - 対象変数IDリスト
%     idvlist     - インデックス構造体

% 対象かチェック
nx = length(xvar);
xlist = zeros(0, nx);
xup = zeros(0, nx);
xdw = zeros(0, nx);
xvar = xvar(:)';

% WFS断面の厚さインデックス配列（tw, tf連動更新用）
THICK_IDX = [PRM.SECDIM_WFS_TW PRM.SECDIM_WFS_TF];

% WFS断面の変数IDを取得
idsec2var = obj.idMapper_.idsec2var;
idsec2stype = obj.idMapper_.idsec2stype;
idwfs2x = idsec2var(idsec2stype == PRM.WFS, 1:4);

if isempty(idvar)
  idvartarget = [];
  return
end

if all(idwfs2x(:,PRM.SECDIM_WFS_TW) ~= idvar)
  idvartarget = [];
  return
end

idslist = obj.idMapper_.getIdSlistofVar(idvar);
if isempty(idslist)
  idvartarget = [];
  return
end

% 計算準備
% 断面寸法を取得（配列対応、uniqueなし）
nslist = length(idslist);
if nslist == 1
  % 単一リストはそのまま処理（最も効率的）
  secdimlist = obj.standardAccessor_.getSectionDimension(idslist);
else
  % 複数リストはcell配列で結合（uniqueなし）
  dims = cell(nslist, 1);
  for i = 1:nslist
    dims{i} = obj.standardAccessor_.getSectionDimension(idslist(i));
  end
  secdimlist = vertcat(dims{:});  % 全断面情報を保持
end

% 現在値
tw0 = xvar(idvar);
% 事前計算されたマッピングを使用
idwfs = obj.idvar2wfsCell_{idvar};
secwfs = xvar(idwfs2x(idwfs, :));
nsec = size(secwfs, 1);
idvartarget = idsec2var(idwfs, :);

% サイズアップ・ダウン断面の検索
upsec = zeros(nsec, 4);
dwsec = zeros(nsec, 4);
for id = 1:nsec
  [upsec_, dwsec_] = SectionNeighborSearcher.findUpDownWfsThick(...
    secwfs(id, :), 'tw', secdimlist, options);
  if isempty(upsec_)
    upsec_ = secwfs(id, 1:4);
  end
  upsec(id, :) = upsec_(1:4);
  if isempty(dwsec_)
    dwsec_ = secwfs(id, 1:4);
  end
  dwsec(id, :) = dwsec_(1:4);
end

% 近傍解集合
[twup, id] = max(upsec(:,PRM.SECDIM_WFS_TW));
if (twup ~= tw0)
  xup = xvar;
  if (size(idvartarget, 1) == 1)
    xup(idvartarget(THICK_IDX)) = upsec(id, THICK_IDX);
  else
    xup(idvar) = twup;
  end
end

[twdw, id] = min(dwsec(:,PRM.SECDIM_WFS_TW));
if (twdw ~= tw0)
  xdw = xvar;
  if (size(idvartarget, 1) == 1)
    xdw(idvartarget(THICK_IDX)) = dwsec(id, THICK_IDX);
  else
    xdw(idvar) = twdw;
  end
end

% 近傍解集合の整理
nup = size(xup, 1);
ndw = size(xdw, 1);
nnn = [ones(1, nup) -ones(1, ndw)];
[xlist, ia] = unique([xup; xdw], 'rows', 'stable');
nnn = nnn(ia);
iddd = 1:size(xlist, 1);
idvlist.up = iddd(nnn > 0);
idvlist.dw = iddd(nnn < 0);

return
end