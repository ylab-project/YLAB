function xvar = findNearestXvarofWfs(obj, repwfs, xvar0, options)
%findNearestXvarofWfs WFS断面の最近傍変数値を検索
%   xvar = findNearestXvarofWfs(obj, repwfs, xvar0, options) は、
%   WFS断面の代表断面から最近傍の変数値を検索します。
%
%   入力引数:
%     repwfs  - WFS代表断面の寸法データ
%     xvar0   - 初期変数値（空の場合はゼロ初期化）
%     options - オプション構造体
%
%   出力引数:
%     xvar    - 最近傍の変数値ベクトル [1×nxvar]

% オブジェクト参照を保存（アクセス回数削減）
idMapper = obj.idMapper_;
standardAccessor = obj.standardAccessor_;

% 共通配列
idH2var = idMapper.idH2var(:)';
idB2var = idMapper.idB2var(:)';
idtw2var = idMapper.idtw2var(:)';
idtf2var = idMapper.idtf2var(:)';
idvar2srep = idMapper.idvar2srep;
idsrep2stype = idMapper.idsrep2stype;

% 共通定数
nsrep = idMapper.nsrep;
nrepwfs = idMapper.nrepwfs;
nxvar = idMapper.nxvar;

% 計算の準備
if isempty(xvar0)
  xvar = zeros(1, nxvar);
else
  xvar = xvar0(:)';  % 行ベクトル化を保証
end
idsrep2repwfs = zeros(nsrep, 1);
idsrep2repwfs(idsrep2stype == PRM.WFS) = 1:nrepwfs;
isVarofSlist = idMapper.isVarofSlist;

% 各断面リストについて処理
nlist = idMapper.nlist;
for idlist = 1:nlist
  % 断面タイプの確認
  % standardAccessorから断面タイプを取得
  section_type = standardAccessor.getSectionType(idlist);
  
  if section_type ~= PRM.WFS
    % 対象リストでなければスキップ
    continue
  end  

  % 断面リストの読み出し
  secdimlist = standardAccessor.getSectionDimension(idlist);
  Hnom = standardAccessor.getNominalH(idlist)';
  Bnom = standardAccessor.getNominalB(idlist)';
  twlist = unique(secdimlist(:, 3));
  tflist = unique(secdimlist(:, 4));

  for ivH = idH2var
    % 変数と断面リストが対応しないときはスキップ
    if ~isVarofSlist(ivH, idlist)
      continue
    end
    % Hの検索
    rep_indices = idsrep2repwfs(idvar2srep{ivH});
    Hset = repwfs(rep_indices, 1);
    % pdist2の代わりに単純な差の絶対値を使用（1次元データの場合）
    % より効率的で、同じ結果を得られる
    ddd = abs(Hnom(:) - Hset(:)');  % [length(Hnom) × length(Hset)]
    mean_ddd = mean(ddd, 2);
    [~, id] = min(mean_ddd);
    Hi = Hnom(id);
    xvar(ivH) = Hi;
  end

  for ivB = idB2var
    % 変数と断面リストが対応しないときはスキップ
    if ~isVarofSlist(ivB, idlist)
      continue
    end
    % Bの検索
    rep_indices = idsrep2repwfs(idvar2srep{ivB});
    Bset = repwfs(rep_indices, 2);
    % 1次元データのため、単純な差の絶対値を使用
    ddd = abs(Bnom(:) - Bset(:)');
    mean_ddd = mean(ddd, 2);
    [~, id] = min(mean_ddd);
    Bi = Bnom(id);
    xvar(ivB) = Bi;
  end

  for ivtw = idtw2var
    % 変数と断面リストが対応しないときはスキップ
    if ~isVarofSlist(ivtw, idlist)
      continue
    end
    % twの検索
    rep_indices = idsrep2repwfs(idvar2srep{ivtw});
    if size(repwfs, 2) >= 3
      twset = repwfs(rep_indices, 3);
      % 1次元データのため、単純な差の絶対値を使用
      ddd = abs(twlist(:) - twset(:)');
      mean_ddd = mean(ddd, 2);
      [~, id] = min(mean_ddd);
      twi = twlist(id);
      xvar(ivtw) = twi;
    end
  end

  for ivtf = idtf2var
    % 変数と断面リストが対応しないときはスキップ
    if ~isVarofSlist(ivtf, idlist)
      continue
    end
    % tfの検索
    rep_indices = idsrep2repwfs(idvar2srep{ivtf});
    if size(repwfs, 2) >= 4
      tfset = repwfs(rep_indices, 4);
      % 1次元データのため、単純な差の絶対値を使用
      ddd = abs(tflist(:) - tfset(:)');
      mean_ddd = mean(ddd, 2);
      [~, id] = min(mean_ddd);
      tfi = tflist(id);
      xvar(ivtf) = tfi;
    end
  end
end

return
end