function xvar = findNearestXvarofBrb(obj, repbrbs, xvar0, options)
%findNearestXvarofBrb BRB断面の最近傍変数値を検索
%   xvar = findNearestXvarofBrb(obj, repbrbs, xvar0, options) は、
%   BRB断面の代表断面から最近傍の変数値を検索します。
%
%   入力引数:
%     repbrbs - BRB代表断面の寸法データ
%     xvar0   - 初期変数値（空の場合はゼロ初期化）
%     options - オプション構造体
%
%   出力引数:
%     xvar    - 最近傍の変数値ベクトル [1×nxvar]

% オブジェクト参照を保存（アクセス回数削減）
idMapper = obj.idMapper_;
standardAccessor = obj.standardAccessor_;

% 共通配列
idv1_var = idMapper.idBrb1_var(:)';
idv2_var = idMapper.idBrb2_var(:)';
idvar2srep = idMapper.idvar2srep;
idsrep2stype = idMapper.idsrep2stype;

% 共通定数
nsrep = idMapper.nsrep;
nrepbrbs = idMapper.nrepbrbs;
nxvar = idMapper.nxvar;

% 計算の準備
if isempty(xvar0)
  xvar = zeros(1, nxvar);
else
  xvar = xvar0(:)';  % 行ベクトル化を保証
end
idsrep2repbrbs = zeros(nsrep, 1);
idsrep2repbrbs(idsrep2stype == PRM.BRB) = 1:nrepbrbs;
isVarofSlist = idMapper.isVarofSlist;

% 各断面リストについて処理
nlist = idMapper.nlist;
for idlist = 1:nlist
  % 断面タイプの確認
  section_type = standardAccessor.getSectionType(idlist);
  
  if section_type ~= PRM.BRB
    % 対象リストでなければスキップ
    continue
  end

  % 断面リストの読み出し
  secdimlist = standardAccessor.getSectionDimension(idlist);
  % v0list = unique(secdimlist(:, 1));
  v1list = unique(secdimlist(:, 2));
  v2list = unique(secdimlist(:, 3));

  % TODO: v0でBRBの種別を分類するが現在はUBBのみで場合分けしていない
  for iv1 = idv1_var
    % 変数と断面リストが対応しないときはスキップ
    if ~isVarofSlist(iv1, idlist)
      continue
    end
    % v1(Ny)の検索
    rep_indices = idsrep2repbrbs(idvar2srep{iv1});
    rep_indices = rep_indices(rep_indices > 0);
    rep_indices = rep_indices(1); % とりあえず
    v1set = repbrbs(rep_indices, 2);
    % pdist2の代わりに単純な差の絶対値を使用（1次元データの場合）
    ddd = abs(v1list(:) - v1set(:)');  % [length(v1list) × length(v1set)]
    mean_ddd = mean(ddd, 2);
    [~, id] = min(mean_ddd);
    v1i = v1list(id);
    xvar(iv1) = v1i;
  end

  for iv2 = idv2_var
    % 変数と断面リストが対応しないときはスキップ
    if ~isVarofSlist(iv2, idlist)
      continue
    end
    % v2(SubID)の検索
    rep_indices = idsrep2repbrbs(idvar2srep{iv2});
    rep_indices = rep_indices(rep_indices > 0);
    rep_indices = rep_indices(1); % とりあえず
    v2set = repbrbs(rep_indices, 3);
    % pdist2の代わりに単純な差の絶対値を使用（1次元データの場合）
    ddd = abs(v2list(:) - v2set(:)');  % [length(v2list) × length(v2set)]
    mean_ddd = mean(ddd, 2);
    [~, id] = min(mean_ddd);
    v2i = v2list(id);
    xvar(iv2) = v2i;
  end
end

return
end