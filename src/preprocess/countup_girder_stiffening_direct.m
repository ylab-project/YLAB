function [member_girder, nominal_girder] = ...
  countup_girder_stiffening_direct(com, lm)
%countup_girder_stiffening_direct - 横補剛間隔の算定
%
%   名目部材単位で補剛間隔(lb)を算定。
%   lb は2列 [左, 右] で出力する。中央検定位置の
%   lb/xcは解析時にcalc_nominal_girder_check_intervalで算出。
%
%   入力引数:
%     com - 共通オブジェクト
%     lm  [nme×1] - 部材長（post-geometry）
%
%   出力引数:
%     member_girder  - slr_lb, slr_is_target,
%                      slr_lbmax を追加
%     nominal_girder - stiffening_lb を追加

% 共通配列
member_column = com.member.column;
member_girder = com.member.girder;
nominal_girder = com.nominal.girder;
girder_stiffening = com.girder_stiffening;
ignominal = nominal_girder.idmeg;
if has_table_field(nominal_girder, 'idmeg0')
  igoriginal = nominal_girder.idmeg0;
else
  igoriginal = ignominal;
end
gjoint = com.member.girder.joint;

% 定数
idme = member_girder.idme;
nmg = com.nmeg;
nnode = com.nnode;
nng = size(ignominal, 1);

% 補剛間隔
lb0 = member_girder.Lb;
lmg = lm(idme);
lgmn = calc_nominal_girder_length(ignominal, lmg);

% 計算の準備（lb を2列 [左, 右] で管理）
lb = [lb0 lb0];
lbmax = lb0;
ngs = size(girder_stiffening,1);
idmeg = girder_stiffening.idmeg;
lbgs = girder_stiffening.Lb;
if has_table_field(girder_stiffening, 'Lb_end')
  lbend_gs = girder_stiffening.Lb_end;
else
  lbend_gs = nan(ngs, 4);
end
if has_table_field(girder_stiffening, 'xc')
  xcgs = girder_stiffening.xc;
else
  xcgs = nan(ngs, 2);
end
if has_table_field(girder_stiffening, 'xc_points')
  xcpts_gs = girder_stiffening.xc_points;
else
  xcpts_gs = nan(ngs, 3);
end
lbend_nom = nan(nng, 4);
xc_nom = nan(nng, 2);
xc_bounds_nom = nan(nng, 2);
xc_points_nom = nan(nng, 3);

% 補剛間隔の読み取り
has_stiff_entry = false(nmg, 1);
has_lbmax_entry = false(nmg, 1);
for i = 1:ngs
  % 指定値の読み取り
  lb1 = lbgs(i,1);
  lb2 = lbgs(i,2);
  lbmax_ = lbgs(i,3);

  % 左右の補剛間隔が未指定なら補剛なし
  if ismissing(lb1)
    lb1 = lbmax_;
  end
  if ismissing(lb2)
    lb2 = lbmax_;
  end

  % 結果の保存
  ngi = nnz(idmeg(i,:));
  igs = idmeg(i, 1:ngi);
  for j = 1:numel(igs)
    ig = igs(j);
    lb(ig,1:2) = [lb1 lb2];
    lbmax(ig) = lbmax_;
    has_stiff_entry(ig) = true;
    has_lbmax_entry(ig) = ~ismissing(lbmax_);
  end
  ing_list = member_girder.idnominal(igs, 1);
  ing_list = unique(ing_list(ing_list > 0));
  for j = 1:numel(ing_list)
    ing = ing_list(j);
    lbend_nom(ing, :) = lbend_gs(i, :);
    xc_nom(ing, :) = xcgs(i, :);
    xc_points_nom(ing, :) = xcpts_gs(i, :);
  end
end

% 節点情報（直交梁判定用）
idcnode = [member_column.idnode1 member_column.idnode2];
idgnode = [member_girder.idnode1 member_girder.idnode2];
idcnode_ = unique(idcnode(:));

% ループ1: lb(:,1:2) の確定（名目部材単位）
for ing = 1:nng
  isubs = ignominal(ing,:);
  isubs(isubs==0) = [];
  i0 = isubs(1);
  lnom = lgmn(i0);

  % Lb未指定/0（横補剛なし）→ 全長を補剛間隔
  if isnan(lb0(i0)) || lb0(i0) == 0
    lb(isubs, :) = lnom;
  end

  % 通し梁中間節点のlb処理
  if numel(isubs) > 1
    igorig = igoriginal(ing, 1:numel(isubs));
    for k = 1:numel(isubs)-1
      i1 = isubs(k);
      i2 = isubs(k+1);
      % KBRACE-MID 等の解析分割境界では Lb を合算しない
      if igorig(k) == igorig(k + 1)
        continue
      end
      % 補剛指定ありの場合はスキップ
      if has_stiff_entry(i1) || has_stiff_entry(i2)
        continue
      end
      % 中間節点に柱または直交梁があるか
      mid_node = idgnode(i1, 2);
      exist_col = any(idcnode_ == mid_node);
      eg1 = idgnode(:,1) == mid_node;
      eg2 = idgnode(:,2) == mid_node;
      eg1(isubs) = false;
      eg2(isubs) = false;
      has_ortho = exist_col || any([eg1; eg2]);
      if ~has_ortho
        lb_span = lmg(i1) + lmg(i2);
        lb(i1,2) = lb_span;
        lb(i2,1) = lb_span;
      end
    end
  end
end

% 名目部材単位でlb左右端を集約
lbn = zeros(nng, 2);
for ing = 1:nng
  isubs = ignominal(ing,:);
  isubs(isubs==0) = [];
  i0 = isubs(1);
  lb1 = lb(i0, 1);
  lb2 = lb(isubs(end), 2);
  lbn(ing, :) = [lb1, lb2];
end

% --- 保有耐力横補剛の対象チェック ---
% 単材の接合条件（H形鋼のみ・SS7計算編 6.4.7）
% 保有耐力横補剛の判定は断面算定の省略（F）指定に関係なく行う
% （SS7入力編 12.6.1 符号毎の指定）
is_target_slr = (gjoint(:,1:2)~=PRM.PIN);
is_target_slr(member_girder.section_type~=PRM.WFS, :) = false;
slrlb = lb;
slrlb(~is_target_slr(:,1),1) = 0;
slrlb(~is_target_slr(:,2),2) = 0;

% slr_lbmax の算定（名目梁単位で算出し全subに格納）
slr_lbmax = zeros(nmg, 1);
for ing = 1:nng
  isubs = ignominal(ing,:);
  isubs(isubs==0) = [];
  i0 = isubs(1);
  if has_lbmax_entry(i0)
    % 入力指定あり → 入力値を使用
    lbmax_nom = lbmax(i0);
  else
    % 入力指定なし → 名目梁内の全subのlbの最大値
    lbmax_nom = max(max(lb(isubs, :)));
  end
  slr_lbmax(isubs) = lbmax_nom;
end

% 通し梁の中央節点の検索
is_dummy_node = false(1,nnode);
for i = 1:nng
  idgs = ignominal(i,:);
  idgs(idgs==0) = [];
  nnn = idgnode(idgs,:)';
  nnn = nnn(:);
  nnn = nnn(2:end-1)';
  is_dummy_node(nnn) = true;
end

% 他に柱梁が接続されてなければ非対象
for ig = 1:nmg
  for j = 1:2
    exist_column = any(idcnode_==idgnode(ig,j));
    exist_girder1 = idgnode(:,1)==idgnode(ig,j);
    exist_girder2 = idgnode(:,2)==idgnode(ig,j);
    exist_girder1(ig) = false;
    exist_girder2(ig) = false;
    exist_girder = any([exist_girder1; exist_girder2]);
    if ~exist_column && ~exist_girder && ~any(is_dummy_node==idgnode(ig,j))
      is_target_slr(ig,j) = false;
    end
  end
end

% 通し梁の接合条件
for i = 1:nng
  idgs = ignominal(i,:);
  idgs(idgs==0) = [];

  % RC梁の除外
  if member_girder.section_type(idgs(1))==PRM.RCRS
    continue
  end

  % 接合条件の確認
  if gjoint(idgs(1),1)==PRM.PIN && gjoint(idgs(end),2)==PRM.PIN
    % 両端ピン
    is_target_slr(idgs,:) = false;
    slrlb(idgs,1) = 0;
    slrlb(idgs,2) = 0;
  elseif gjoint(idgs(1),1)==PRM.PIN && gjoint(idgs(end),2)~=PRM.PIN
    % 左端ピン
    is_target_slr(idgs,1) = false;
    is_target_slr(idgs(1:end-1),2) = false;
    slrlb(idgs,1) = 0;
    slrlb(idgs(1:end-1),2) = 0;
  elseif gjoint(idgs(1),1)~=PRM.PIN && gjoint(idgs(end),2)==PRM.PIN
    % 右端ピン
    is_target_slr(idgs,1) = false;
    is_target_slr(idgs(1:end-1),2) = false;
    slrlb(idgs(2:end),1) = 0;
    slrlb(idgs,2) = 0;
  end
end

% 名目梁単位の補剛区間数
nstiff_nom = zeros(nng, 1);
stiffening_n = nan(nng, 1);
stiffening_lb_report = nan(nng, 4);
for ing = 1:nng
  isubs = ignominal(ing,:);
  isubs(isubs==0) = [];
  lnom = lgmn(isubs(1));
  lbend_ = lbend_nom(ing, :);
  xc_ = xc_nom(ing, :);

  % 中央検定区間。xcは中央補剛位置であり区間数とは独立に決まる
  xa = xc_(1);
  xb = lnom - xc_(2);
  if all(~ismissing(xc_)) && all(xc_ >= 0) && xa < xb && xb <= lnom
    xc_bounds_nom(ing, :) = [xa xb];
  end

  if all(~ismissing(lbend_)) && all(lbend_ > 0)
    % 横補剛の直接入力あり。SS7入力編 表9.9.1 の採用順に従い
    % 左側1→右側1→左側2→右側2 で累積し名目梁長で打ち切る
    nint = find(cumsum(lbend_([1 3 2 4])) >= lnom - 0.5, 1, 'first');
    % 4間隔すべてを使っても名目梁長に届かない場合
    is_lb_all_used = isempty(nint);
    if is_lb_all_used
      % 上限。連携CSVのLb欄は4つで、4間隔＋中央1区間の
      % 5区間までしか表現できない
      nint = 5;
      stiffening_n(ing) = 4;
      % 帳票Lb1-4順: 入力 Lb_end=[左1 左2 右1 右2] の右ペアを反転
      stiffening_lb_report(ing, :) = lbend_([1 2 4 3]);
    end
  else
    % 等間隔配置。lbnの左右は同値になる
    nint = ceil(lnom / lbn(ing, 1));
  end
  nstiff_nom(ing) = nint;
end

% 結果保存
nominal_girder.nstiff = nstiff_nom;
nominal_girder.stiffening_lb = lbn;
nominal_girder.stiffening_lb_end = lbend_nom;
nominal_girder.stiffening_xc = xc_nom;
nominal_girder.stiffening_xc_bounds = xc_bounds_nom;
nominal_girder.stiffening_xc_points = xc_points_nom;
nominal_girder.stiffening_n = stiffening_n;
nominal_girder.stiffening_lb_report = stiffening_lb_report;
member_girder.slr_is_target = is_target_slr;
member_girder.slr_lb = slrlb;
member_girder.slr_lbmax = slr_lbmax;

return
end
