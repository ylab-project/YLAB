function xvar = findNearestXvarStatic(secdim, options, idMapper)
%findNearestXvarStatic 断面寸法から変数値を抽出（静的版）
%   xvar = findNearestXvarStatic(secdim, options, idMapper) は、
%   断面寸法データから対応する変数値を抽出する静的メソッドです。
%
%   入力引数:
%     secdim   - 断面寸法データ [nsec×7]
%     options  - オプション構造体
%     idMapper - IdMapperオブジェクト
%
%   出力引数:
%     xvar - 変数値ベクトル [1×nxvar]

% 共通配列
idsec2stype = idMapper.idsec2stype;

% H形鋼
idrepwfs2wfs = idMapper.idrepwfs2wfs;
secwfs = secdim(idsec2stype == PRM.WFS, :);
repwfs = secwfs(idrepwfs2wfs, :);
xvar = findNearestXvarofWfsStatic(repwfs, [], idMapper);

% 角形鋼管
idrephss2hss = idMapper.idrephss2hss;
sechss = secdim(idsec2stype == PRM.HSS, :);
rephss = sechss(idrephss2hss, :);
xvar = findNearestXvarofHssStatic(rephss, xvar, idMapper);

% BRB
idrepbrbs2brbs = idMapper.idrepbrbs2brbs;
secbrbs = secdim(idsec2stype == PRM.BRB, :);
repbrbs = secbrbs(idrepbrbs2brbs, :);
xvar = findNearestXvarofBrbStatic(repbrbs, xvar, idMapper);

return
end

%% findNearestXvarofWfsStatic
function xvar = findNearestXvarofWfsStatic(repwfs, xvar, idMapper)
%findNearestXvarofWfsStatic WFS変数値抽出（静的版）

idrepwfs2var = idMapper.idrepwfs2var;
nrepwfs = size(idrepwfs2var, 1);

if isempty(xvar)
  xvar = zeros(1, idMapper.nxvar);
end

for id_ = 1:nrepwfs
  if idrepwfs2var(id_, 1) == 0
    continue;
  end
  
  xvar(idrepwfs2var(id_, 1)) = repwfs(id_, 1);  % H
  xvar(idrepwfs2var(id_, 2)) = repwfs(id_, 2);  % B
  xvar(idrepwfs2var(id_, 3)) = repwfs(id_, 3);  % tw
  xvar(idrepwfs2var(id_, 4)) = repwfs(id_, 4);  % tf
end

return
end

%% findNearestXvarofHssStatic
function xvar = findNearestXvarofHssStatic(rephss, xvar, idMapper)
%findNearestXvarofHssStatic HSS変数値抽出（静的版）

idrephss2var = idMapper.idrephss2var;
nrephss = size(idrephss2var, 1);

if isempty(xvar)
  xvar = zeros(1, idMapper.nxvar);
end

for id_ = 1:nrephss
  if idrephss2var(id_, 1) == 0
    continue;
  end
  
  xvar(idrephss2var(id_, 1)) = rephss(id_, 1);  % D
  xvar(idrephss2var(id_, 2)) = rephss(id_, 2);  % t
end

return
end

%% findNearestXvarofBrbStatic
function xvar = findNearestXvarofBrbStatic(repbrbs, xvar, idMapper)
%findNearestXvarofBrbStatic BRB変数値抽出（静的版）

idrepbrbs2var = idMapper.idrepbrbs2var;
nrepbrbs = size(idrepbrbs2var, 1);

if isempty(xvar)
  xvar = zeros(1, idMapper.nxvar);
end

for id_ = 1:nrepbrbs
  if idrepbrbs2var(id_, 1) == 0
    continue;
  end
  
  xvar(idrepbrbs2var(id_, 1)) = repbrbs(id_, 1);  % V1
  xvar(idrepbrbs2var(id_, 2)) = repbrbs(id_, 2);  % V2
end

return
end