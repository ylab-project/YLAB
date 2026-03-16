function [head, body] = write_cell_steel_cost_summary( ...
  com, options, cost, secdim)
%write_cell_steel_cost_summary - 部位別集計表(鉄骨)セル配列を生成
%
%   [head, body] = write_cell_steel_cost_summary(
%     com, options, cost, secdim) は、
%   SS7積算「部位別集計表(鉄骨)」と同様式の
%   セル配列を生成する。
%
%   入力引数:
%     com     - 共通オブジェクト
%     options - オプション構造体
%     cost    - 積算データ構造体
%     secdim  - 断面寸法配列 [nsec×ncol]
%
%   出力引数:
%     head - ヘッダ部セル配列
%     body - データ部セル配列

NFIX = 5;

% com からデータ取り出し
stype = com.section.property.type;
secmgr = com.secmgr;
material = com.material;

% options からデータ取り出し
ef_col = options.steel_cost_weight_extra_factor_column;
ef_gir = options.steel_cost_weight_extra_factor_girder;

% 部位列の構成（水平ブレース列は常に出力）
IPCOL = 1;  IPGIR = 2;  IPBRC = 5;
IPHBR = 6;  npart = 8;  IPTOT = npart;
NCOL = NFIX + npart;

% 部位名リスト
pnames = {'柱', '大梁', '片持梁', '小梁', '鉛直ﾌﾞﾚｰｽ', ...
  '水平ﾌﾞﾚｰｽ', 'その他', '合計'};

% 部位別の割増率
pfac = ones(1, npart - 1);
pfac(IPCOL) = ef_col;
pfac(IPGIR) = ef_gir;

% ヘッダ
head = cell(1, NCOL);
head{2} = '種類';
head{3} = '鉄骨断面[mm]';
head{5} = '材料';
for ip = 1:npart
  head{NFIX + ip} = pnames{ip};
end

% 有効要素の抽出（BRBは鉄骨重量から除外）
mc = cost.column.idsec > 0;
mg = cost.girder.idsec > 0;
mb = cost.brace.idsec > 0;
for ib = 1:numel(mb)
  if mb(ib) && stype(cost.brace.idsec(ib)) == PRM.BRB
    mb(ib) = false;
  end
end
mh = cost.hbrace.idsec > 0;

% グループ化用の全要素リスト
all_is = [cost.column.idsec(mc); cost.girder.idsec(mg); ...
  cost.brace.idsec(mb); cost.hbrace.idsec(mh)];
all_im = [cost.column.idmat(mc); cost.girder.idmat(mg); ...
  cost.brace.idmat(mb); cost.hbrace.idmat(mh)];

% ブロック1-3の構築
if isempty(all_is)
  blk1 = cell(0, NCOL);
  blk2 = cell(0, NCOL);
  blk3 = cell(0, NCOL);
else
  % (idslist, idsection, idmat)でグループ化
  all_sl = secdim(all_is, 6);
  all_sn = secdim(all_is, 7);
  [grp, ia, ~] = unique([all_sl, all_sn, all_im], 'rows');
  nrows = size(grp, 1);
  rep_is = all_is(ia);

  % 部位別重量の集計
  wt = zeros(nrows, npart);
  wt = accum_grp(wt, grp, secdim, cost.column, mc, IPCOL);
  wt = accum_grp(wt, grp, secdim, cost.girder, mg, IPGIR);
  wt = accum_grp(wt, grp, secdim, cost.brace, mb, IPBRC);
  if IPHBR > 0
    wt = accum_grp(wt, grp, secdim, cost.hbrace, mh, IPHBR);
  end
  wt(:, IPTOT) = sum(wt(:, 1:IPTOT-1), 2);

  % 種類名順でソート
  [wt, grp, rep_is] = sort_by_type(wt, grp, rep_is, nrows, secmgr);

  % ブロック1: 鉄骨重量
  blk1 = build_steel_weight_block(grp, rep_is, wt, nrows, ...
    npart, NFIX, NCOL, stype, secdim, secmgr, material);
  sub1 = sum(wt, 1);

  % ブロック2: 割増重量
  [blk2, sub2] = build_extra_weight_block(grp, wt, nrows, ...
    npart, IPTOT, NFIX, NCOL, pfac, material);

  % ブロック3: 合計
  blk3 = build_total_block(sub1, sub2, npart, NFIX, NCOL);
end

% ブロック4: BRBブレース長さ・本数
blk4 = build_brb_length_block(cost, secdim, stype, secmgr, NFIX, NCOL);

body = [blk1; blk2; blk3; blk4];

return
end

function wt = accum_grp(wt, grp, secdim, part, mask, ip)
%accum_grp - 部位別重量を(idslist,idsection,idmat)行に加算
%
%   wt = accum_grp(wt, grp, secdim, part, mask, ip)
%
%   入力引数:
%     wt     - 重量テーブル [nrows×npart]
%     grp    - グループキー [nrows×3]
%     secdim - 断面寸法配列
%     part   - 部位構造体 (.idsec, .idmat, .weight)
%     mask   - 有効要素の論理マスク
%     ip     - 部位インデックス
  is = part.idsec(mask);
  im = part.idmat(mask);
  w = part.weight(mask);
  if isempty(is)
    return
  end
  sl = secdim(is, 6);
  sn = secdim(is, 7);
  [~, loc] = ismember([sl, sn, im], grp, 'rows');
  for k = 1:numel(loc)
    if loc(k) > 0
      wt(loc(k), ip) = wt(loc(k), ip) + w(k);
    end
  end

  return
end

function [wt, grp, rep_is] = sort_by_type(wt, grp, rep_is, nrows, secmgr)
%sort_by_type - 種類名順でソート
%
%   [wt, grp, rep_is] = sort_by_type(
%     wt, grp, rep_is, nrows, secmgr)
%
%   SS7の部位別集計表と同じ並び順にする。
%   種類名（sl.type）の優先度順でソートする。
  order = zeros(nrows, 1);
  map = containers.Map({'細幅', '中幅', '広幅', 'BCR', ...
    'STKR', 'BCP', '山形鋼', '溝形鋼', '平鋼', 'ﾀｰﾝﾊﾞｯｸﾙ'}, ...
    {1, 2, 3, 4, 5, 6, 7, 8, 9, 10});
  for r = 1:nrows
    idsl = grp(r, 1);
    idsn = grp(r, 2);
    sl = secmgr.secList.list{idsl};
    tname = sl.type{idsn};
    if isKey(map, tname)
      order(r) = map(tname);
    else
      order(r) = 99;
    end
  end
  [~, ord] = sortrows([order, grp(:, 3), grp(:, 1:2)]);
  grp = grp(ord, :);
  rep_is = rep_is(ord);
  wt = wt(ord, :);

  return
end

function blk = build_steel_weight_block(grp, rep_is, ...
  wt, nrows, npart, NFIX, NCOL, stype, secdim, secmgr, ...
  material)
%build_steel_weight_block - 鉄骨重量ブロック(ブロック1)を構築
%
%   blk = build_steel_weight_block(
%     grp, rep_is, wt, nrows, npart,
%     NFIX, NCOL, stype, secdim, secmgr, material)
  blk = cell(nrows + 1, NCOL);
  for r = 1:nrows
    is = rep_is(r);
    im = grp(r, 3);
    idsl = grp(r, 1);
    idsn = grp(r, 2);
    stype_ = stype(is);
    sl = secmgr.secList.list{idsl};
    tname = sl.type{idsn};
    if stype_ == PRM.TB
      sym = sl.label{idsn};
    else
      sym = sl.symbol{idsn};
    end
    mname = material.name{im};
    if r == 1
      blk{r, 1} = '　　 鉄骨重量　[t]';
    end
    blk{r, 2} = tname;
    blk{r, 3} = format_steel_cost_dim(stype_, secdim(is, :), sym);
    blk{r, 5} = mname;
    for ip = 1:npart
      if wt(r, ip) > 0
        blk{r, NFIX + ip} = sprintf('%.2f', wt(r, ip));
      end
    end
  end

  % 小計行
  sub1 = sum(wt, 1);
  blk{nrows + 1, 2} = '小計';
  for ip = 1:npart
    if sub1(ip) > 0
      blk{nrows + 1, NFIX + ip} = sprintf('%.2f', sub1(ip));
    end
  end

  return
end

function [blk, sub2] = build_extra_weight_block(grp, ...
  wt, nrows, npart, IPTOT, NFIX, NCOL, pfac, material)
%build_extra_weight_block - 割増重量ブロック(ブロック2)を構築
%
%   [blk, sub2] = build_extra_weight_block(
%     grp, wt, nrows, npart, IPTOT,
%     NFIX, NCOL, pfac, material)

  % 材料別の重量を集計
  umat = unique(grp(:, 3));
  nmat = numel(umat);
  wt_m = zeros(nmat, npart);
  for r = 1:nrows
    mi = find(umat == grp(r, 3), 1);
    wt_m(mi, :) = wt_m(mi, :) + wt(r, :);
  end

  % 割増重量の計算
  extra = zeros(nmat, npart);
  for mi = 1:nmat
    for ip = 1:npart - 1
      extra(mi, ip) = wt_m(mi, ip) * (pfac(ip) - 1);
    end
    extra(mi, IPTOT) = sum(extra(mi, 1:IPTOT-1));
  end

  % ゼロ行を除去
  hasm = any(abs(extra) > 1e-12, 2);
  extra2 = extra(hasm, :);
  umat2 = umat(hasm);
  nmat2 = sum(hasm);

  if nmat2 > 0
    sub2 = sum(extra2, 1);
    blk = cell(nmat2 + 1, NCOL);
    for mi = 1:nmat2
      if mi == 1
        blk{mi, 1} = '　　 割増重量　[t]';
      end
      blk{mi, 5} = material.name{umat2(mi)};
      for ip = 1:npart
        if abs(extra2(mi, ip)) > 1e-12
          blk{mi, NFIX + ip} = sprintf('%.2f', extra2(mi, ip));
        end
      end
    end
    % 小計行
    blk{nmat2 + 1, 5} = '小計';
    for ip = 1:npart
      if abs(sub2(ip)) > 1e-12
        blk{nmat2 + 1, NFIX + ip} = sprintf('%.2f', sub2(ip));
      end
    end
  else
    sub2 = zeros(1, npart);
    blk = cell(0, NCOL);
  end

  return
end

function blk = build_total_block(sub1, sub2, npart, NFIX, NCOL)
%build_total_block - 合計ブロック(ブロック3)を構築
%
%   blk = build_total_block(
%     sub1, sub2, npart, NFIX, NCOL)
  blk = cell(1, NCOL);
  blk{1, 1} = '　　　 合計　　[t]';
  total = sub1 + sub2;
  for ip = 1:npart
    if total(ip) > 0
      blk{1, NFIX + ip} = sprintf('%.2f', total(ip));
    end
  end

  return
end

function blk = build_brb_length_block(cost, secdim, ...
  stype, secmgr, NFIX, NCOL)
%build_brb_length_block - BRBブレース長さ・本数ブロックを構築
%
%   blk = build_brb_length_block(
%     cost, secdim, stype, secmgr,
%     NFIX, NCOL)
%
%   部位別集計表(鉄骨)のブロック4。
%   BRB（メーカー製品）の品番・長さ・本数を出力する。
%   (品番, 丸め長さ)でグループ化し本数を合計する。

  nb = numel(cost.brace.idsec);

  % BRBマスクの構築
  mbrb = false(nb, 1);
  for ib = 1:nb
    is = cost.brace.idsec(ib);
    if is > 0 && stype(is) == PRM.BRB
      mbrb(ib) = true;
    end
  end

  if ~any(mbrb)
    blk = cell(0, NCOL);
    return
  end

  % BRB要素ごとのデータ収集
  idx_brb = find(mbrb);
  nbrb = numel(idx_brb);
  labels = cell(nbrb, 1);
  type_names = cell(nbrb, 1);
  lengths = zeros(nbrb, 1);

  for k = 1:nbrb
    ib = idx_brb(k);
    is = cost.brace.idsec(ib);
    idslist = secdim(is, 6);
    idsection = secdim(is, 7);
    sl = secmgr.secList.list{idslist};

    % 種類名: メーカー名 + ラベル
    maker = get_brb_maker(sl.type{idsection});
    type_names{k} = [maker sl.label{idsection}];

    % 品番
    labels{k} = sl.symbol{idsection};

    % 長さ [m]（小数2桁丸め）
    lengths(k) = round(cost.brace.lm(ib) * 1e-3, 2);
  end

  % (品番, 丸め長さ)でグループ化
  len_str = arrayfun(@(x) sprintf('%.2f', x), lengths, ...
    'UniformOutput', false);
  keys = strcat(labels, '|', len_str);
  [~, ia, ic] = unique(keys, 'sorted');
  ngrp = numel(ia);

  blk = cell(ngrp, NCOL);
  blk{1, 1} = 'ブレース長さ・本数';
  for g = 1:ngrp
    blk{g, 2} = type_names{ia(g)};
    blk{g, NFIX} = labels{ia(g)};
    blk{g, NFIX + 2} = sprintf('%.2f', lengths(ia(g)));
    blk{g, NFIX + 3} = 'm';
    blk{g, NFIX + 4} = sprintf('%d', sum(ic == g));
    blk{g, NFIX + 5} = '本';
  end

  return
end

function maker = get_brb_maker(type_code)
%get_brb_maker - 製品コードからメーカー短縮名を取得
%
%   maker = get_brb_maker(type_code)
%
%   製品コードプレフィックスからBRBメーカーの
%   短縮名を返す。未知のコードは空文字を返す。
  if startsWith(type_code, 'UB')
    maker = '日鉄エンジニアリング';
  else
    maker = '';
  end

  return
end

