function xvar = findNearestXvarofHss(obj, rephss, xvar0, options)
%findNearestXvarofHss HSS断面の最近傍変数値を検索
%   xvar = findNearestXvarofHss(obj, rephss, xvar0, options) は、
%   HSS断面の代表断面から最近傍の変数値を検索します。
%
%   入力引数:
%     rephss  - HSS代表断面の寸法データ
%     xvar0   - 初期変数値（空の場合はゼロ初期化）
%     options - オプション構造体
%
%   出力引数:
%     xvar    - 最近傍の変数値ベクトル [1×nxvar]

% オブジェクト参照を保存（アクセス回数削減）
idMapper = obj.idMapper_;
standardAccessor = obj.standardAccessor_;

% 共通配列
idD2var = idMapper.idD2var(:)';
idt2var = idMapper.idt2var(:)';
idvar2srep = idMapper.idvar2srep;
idsrep2stype = idMapper.idsrep2stype;

% 共通定数
nsrep = idMapper.nsrep;
nrephss = idMapper.nrephss;
nxvar = idMapper.nxvar;

% 計算の準備
if isempty(xvar0)
  xvar = zeros(1, nxvar);
else
  xvar = xvar0(:)';  % 行ベクトル化を保証
end
idsrep2rephss = zeros(nsrep, 1);
idsrep2rephss(idsrep2stype == PRM.HSS) = 1:nrephss;
isVarofSlist = idMapper.isVarofSlist;

% 各断面リストについて処理
nlist = idMapper.nlist;
for idlist = 1:nlist
  % 断面タイプの確認
  section_type = standardAccessor.getSectionType(idlist);
  
  if section_type ~= PRM.HSS
    % 対象リストでなければスキップ
    continue
  end

  % 断面リストの読み出し
  secdimlist = standardAccessor.getSectionDimension(idlist);
  Dlist = unique(secdimlist(:, 1));
  tlist = unique(secdimlist(:, 2));

  for ivD = idD2var
    % 変数と断面リストが対応しないときはスキップ
    if ~isVarofSlist(ivD, idlist)
      continue
    end
    % Dの検索
    rep_indices = idsrep2rephss(idvar2srep{ivD});
    rep_indices = rep_indices(rep_indices > 0);
    Dset = rephss(rep_indices, 1);
    % pdist2の代わりに単純な差の絶対値を使用（1次元データの場合）
    ddd = abs(Dlist(:) - Dset(:)');  % [length(Dlist) × length(Dset)]
    mean_ddd = mean(ddd, 2);
    [~, id] = min(mean_ddd);
    Di = Dlist(id);
    xvar(ivD) = Di;
  end

  for ivt = idt2var
    % 変数と断面リストが対応しないときはスキップ
    if ~isVarofSlist(ivt, idlist)
      continue
    end
    % tの検索
    rep_indices = idsrep2rephss(idvar2srep{ivt});
    rep_indices = rep_indices(rep_indices > 0);
    tset = rephss(rep_indices, 2);
    % pdist2の代わりに単純な差の絶対値を使用（1次元データの場合）
    ddd = abs(tlist(:) - tset(:)');  % [length(tlist) × length(tset)]
    mean_ddd = mean(ddd, 2);
    [~, id] = min(mean_ddd);
    ti = tlist(id);
    xvar(ivt) = ti;
  end
end

return
end