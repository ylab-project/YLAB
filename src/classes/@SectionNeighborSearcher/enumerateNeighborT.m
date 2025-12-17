function [xlist, xup, xdw, idvartarget, idvlist] = ...
  enumerateNeighborT(obj, xvar, idvar, options)
%enumerateNeighborT 厚さtの近傍断面を列挙
%   [xlist, xup, xdw, idvartarget, idvlist] = enumerateNeighborT(obj,
%     xvar, idvar, options) は、指定変数の厚さtについて近傍断面を列挙します。
%
%   注：D, tは単一変数のみを変更するため、idhss計算は不要です。
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

% HSS断面の変数IDを取得
idsec2var = obj.idMapper_.idsec2var;
idsec2stype = obj.idMapper_.idsec2stype;
idhss2x = idsec2var(idsec2stype == PRM.HSS, 1:2);

if isempty(idvar)
  idvartarget = [];
  return
end

if all(idhss2x(:,PRM.SECDIM_HSS_T) ~= idvar)
  idvartarget = [];
  return
end

idslist = obj.idMapper_.getIdSlistofVar(idvar);
if isempty(idslist)
  idvartarget = [];
  return
end

% 計算準備
idhss2rephss = obj.idMapper_.idhss2rephss;
idrephss2hss = obj.idMapper_.idrephss2hss;

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
t0 = xvar(idvar);
idhss = unique(idrephss2hss(idhss2rephss(idhss2x(:,2) == idvar)));
sechss = xvar(idhss2x(idhss, :));
nsec = size(sechss, 1);
idvartarget = idsec2var(idhss, :);

% サイズアップ・ダウン断面の検索
upsec = zeros(nsec, 2);
dwsec = zeros(nsec, 2);
for id = 1:nsec
  [upsec_, dwsec_] = SectionNeighborSearcher.findUpDownHssThick(...
    sechss(id, :), secdimlist, options);
  if isempty(upsec_)
    upsec_ = sechss(id, 1:2);
  end
  upsec(id, :) = upsec_(1:2);
  if isempty(dwsec_)
    dwsec_ = sechss(id, 1:2);
  end
  dwsec(id, :) = dwsec_(1:2);
end

% 近傍解集合
tup = max(upsec(:,2));
if (tup ~= t0)
  xup = xvar;
  xup(idvar) = tup;
end

tdw = min(dwsec(:,2));
if (tdw ~= t0)
  xdw = xvar;
  xdw(idvar) = tdw;
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