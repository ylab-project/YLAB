function member_girder = countup_girder_stiffening_direct(com)

% 共通配列
member_column = com.member.column;
member_girder = com.member.girder;
girder_stiffening = com.girder_stiffening;
ignominal = com.nominal.girder.idmeg;
gjoint = com.member.girder.joint;

% 定数
nmg = size(member_girder,1);
nnode = size(com.node,1);

% 補剛間隔
% nstiff = member_girder.nstiff;
lb0 = member_girder.Lb;
lm = member_girder.lm;
lm_nominal = member_girder.lm_nominal;

% 計算の準備
lb = [lb0 lb0 lb0];
xc = zeros(nmg,3);
is_through = member_girder.isthrough;
ngs = size(girder_stiffening,1);
idmeg = girder_stiffening.idmeg;
lbgs = girder_stiffening.Lb;
xcgs = girder_stiffening.xc;

% 補剛間隔
for i=1:ngs
  % 指定値の読み取り
  lb1 = lbgs(i,1);
  lb2 = lbgs(i,2);
  lbmax = lbgs(i,3);
  xc1 = xcgs(i,1);
  xc2 = xcgs(i,2);

  % 左右の補剛間隔が指定されてなければ補剛なし
  if ismissing(lb1)
    lb1 = lbmax;
    xc1 = 0;
  end
  if ismissing(lb2)
    lb2 = lbmax;
    xc2 = 0;
  end

  % 結果の保存
  ngi = nnz(idmeg(i,:));
  for j=1:ngi
    lb(idmeg(i,j),:) = [lb1 lb2 lbmax];
    xc(idmeg(i,j),1:2) = [xc1 xc2];
  end
end

% 中央位置
for i=1:nmg
  % 指定されている場合はそのまま
  if all(~ismissing(xc(i,:))) && xc(i,2)>0
    continue
  end

  % 指定されていない場合
  lb1 = min(lb(i,1),lm(i));
  lb2 = min(lb(i,2),lm(i));
  lbmax = min(lb(i,3),lm(i));
  lbmin = min([lb(i,:) lm(i)]);
  nstiff = lm(i)/lbmin;
  if nstiff-1<0.01
    % 補剛なし
    xc1 = 0;
    xc2 = 0;
  elseif mod(nstiff,2)<=0.1
    % 均等偶数本
    xc1 = max(lm(i)/2-lbmax,0);
    xc2 = lm(i)/2;
  elseif (lm(i)-lb1-lb2)/lbmax<=1.01 && (lm(i)-lb1-lb2)/lbmax>0.01
    % 中央区間は最大区間以下
    xc1 = lb1;
    xc2 = lb2;
  else
    % 最大区間とする
    xc1 = max((lm(i)-lbmax)/2,0);
    xc2 = max((lm(i)-lbmax)/2,0);
  end
  xc1 = min(xc1,lm(i));
  xc2 = min(xc2,lm(i));
  xc(i,1:2) = [xc1 xc2];
end

% 通し梁中央位置
for i=1:nmg
  xc(i,3) = lm_nominal(i)/2;
end

% チェック用
% lb3 = lm-xc(:,1)-xc(:,2);
% check = max([lb(:,1) lb(:,2) lb3],[],2)-lb(:,3);

% 対象外の削除
for i=1:nmg
  for j=1:2
    if is_through(i,j)
      lb(i,j) = 0;
    end
  end
end

% --- 保有耐力横補剛の対象チェック ---
% 単材の接合条件
is_target_slr = (gjoint(:,1:2)~=PRM.PIN);
is_target_slr(member_girder.section_type==PRM.RCRS,:) = false;
slrlb = lb;
slrlb(~is_target_slr(:,1),1) = 0;
slrlb(~is_target_slr(:,2),2) = 0;

% 通し梁の中央節点の検索
idcnode = [member_column.idnode1 member_column.idnode2];
idgnode = [member_girder.idnode1 member_girder.idnode2];
is_dummy_node = false(1,nnode);
for i=1:size(ignominal,1)
  idgs = ignominal(i,:);
  idgs(idgs==0) = [];
  nnn = idgnode(idgs,:)';
  nnn = nnn(:);
  nnn = nnn(2:end-1)';
  is_dummy_node(nnn) = true;
end

% 他に柱梁が接続されてなければ非対象
idcnode_ = unique(idcnode(:));
for ig=1:nmg
  for j=1:2
    exist_column = any(idcnode_==idgnode(ig,j));
    exist_girder1 = idgnode(:,1)==idgnode(ig,j);
    exist_girder2 = idgnode(:,2)==idgnode(ig,j);
    exist_girder1(ig) = false;
    exist_girder2(ig) = false;
    exist_girder = any([exist_girder1; exist_girder2]);
    if  ~exist_column && ~exist_girder ...
      && ~any(is_dummy_node==idgnode(ig,j))
      is_target_slr(ig,j) = false;
    end
  end
end

% 通し梁の接合条件
for i=1:size(ignominal,1)
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
    % 必要補剛間隔はすべて0
    slrlb(idgs,1) = 0;
    slrlb(idgs,2) = 0;
  elseif gjoint(idgs(1),1)==PRM.PIN && gjoint(idgs(end),2)~=PRM.PIN
    % 左端ピン
    is_target_slr(idgs,1) = false;
    is_target_slr(idgs(1:end-1),2) = false;
    % 必要補剛間隔は右端のみ残す
    slrlb(idgs,1) = 0;
    slrlb(idgs(1:end-1),2) = 0;
  elseif gjoint(idgs(1),1)~=PRM.PIN && gjoint(idgs(end),2)==PRM.PIN
    % 右端ピン
    is_target_slr(idgs,1) = false;
    is_target_slr(idgs(1:end-1),2) = false;
    % 必要補剛間隔は左端のみ残す
    slrlb(idgs(2:end),1) = 0;
    slrlb(idgs,2) = 0;
  end
end

% 結果保存
member_girder.stiffening_lb = lb;
member_girder.stiffening_xc = xc;
member_girder.slr_is_target = is_target_slr;
member_girder.slr_lb = slrlb;
end
