function [nominal_girder, idnominal] = countup_nominal_girder(com)
%CALC_GIRDER_THROUGH_LENGTH この関数の概要をここに記述
%   詳細説明をここに記述

% 共通配列
idconnected_girder = com.member.girder.idconnected_girder;
idx_girder = com.member.girder.idx;
idy_girder = com.member.girder.idy;
lgm = com.member.property.lm(com.member.girder.idme);
girder = com.member.girder;
issgas = com.exclusion.is_section_girder_allowable_stress;

% 計算の準備
nmg = length(idconnected_girder);
nnmg = nnz(idconnected_girder);
mcol = 10;
idmeg = zeros(nnmg, mcol);
ischecked = false(1,nmg);

% 通し梁の検索
igt = 0;
for ig=1:nmg
  idnext = idconnected_girder(ig);

  % チェック済
  if ischecked(ig)
    continue
  end

  % カウント
  igt = igt+1;
  idmeg(igt,1) = ig;
  ischecked(ig) = true;
  
  % 接続部材なし
  if idnext==0
    continue
  end

  % 接続部材あり
  jgt = 2;
  idmeg(igt,2) = idnext;
  idconnected_girder(ig) = 0;
  ischecked(idnext) = true;

  % 接続検索
  for ig2 = 1:1000
    idcur = idnext;
    idnext = idconnected_girder(idnext);
    idconnected_girder(idcur) = 0;
    if (idnext==0)
      % 接続部材なし
      break
    end

    % 接続部材追加
    jgt = jgt+1;
    idmeg(igt,jgt) = idnext;
    ischecked(idnext) = true;
  end

end

% 配列リサイズ
mcol = max(sum(idmeg>0,2));
nnmg = igt;
idmeg = idmeg(1:nnmg, 1:mcol);

% 通り順に並び替え
for i=1:nnmg
  ncol = nnz(idmeg(i,:));
  if ncol==1
    continue
  end
  iddd = idmeg(i,1:ncol);
  idx = idx_girder(iddd,1);
  idy = idy_girder(iddd,1);
  if idy(1)==idy(2)
    % X方向
    [~, idsort] = sort(idx);
  else
    % Y方向
    [~, idsort] = sort(idy);
  end
  idmeg(i,1:ncol) = idmeg(i,idsort);
end

% 部材長
l_nominal_girder = zeros(nnmg, mcol);
for i=1:nnmg
  ncol = nnz(idmeg(i,:));
  l_nominal_girder(i,1:ncol) = lgm(idmeg(i,1:ncol));
end

% 左右中央部材
idsub = zeros(nnmg,3);
for i=1:nnmg
  ncol = nnz(idmeg(i,:));
  % iddd = id_nominal_girder(i,1:ncol);
  % idlrc(i,1) = iddd(1);
  % idlrc(i,2) = iddd(end);
  idsub(i,1) = 1;
  idsub(i,2) = ncol;
  lgm = sum(l_nominal_girder(i))/2;
  for j=1:ncol
    if l_nominal_girder(i,j)>=lgm
      % idlrc(i,3) = iddd(j);
      idsub(i,3) = j;
      break
    end
  end
end

% 向き
idir = girder.idir(idmeg(:,1));

% nominal部材通り番号
story_name = girder.story_name(idmeg(:,1));
frame_name = girder.frame_name(idmeg(:,1));
idstory = girder.idstory(idmeg(:,1));
idx = zeros(nnmg,2);
idy = zeros(nnmg,2);
idz = zeros(nnmg,2);
idzn = zeros(nnmg,2);
coord_name = girder.coord_name(idmeg(:,1),:);
for i=1:nnmg
  ig_first = idmeg(i,1);
  idx(i,1) = girder.idx(ig_first,1);
  idy(i,1) = girder.idy(ig_first,1);
  idz(i,1) = girder.idz(ig_first,1);
  idzn(i,1) = girder.idzn(ig_first,1);
  coord_name{i,1} = girder.coord_name{ig_first,1};
  jl = idsub(i,2);
  if jl<1 || jl>size(idmeg,2) || idmeg(i,jl)==0
    ig_last = ig_first;
  else
    ig_last = idmeg(i,jl);
  end
  idx(i,2) = girder.idx(ig_last,2);
  idy(i,2) = girder.idy(ig_last,2);
  idz(i,2) = girder.idz(ig_last,2);
  idzn(i,2) = girder.idzn(ig_last,2);
  coord_name{i,2} = girder.coord_name{ig_last,2};
end

% 逆引き
idnominal = zeros(nmg,2);
for ing=1:nnmg
  for j=1:mcol
    ig = idmeg(ing,j);
    if ig>0
      idnominal(ig,:) = [ing j];
    end
  end
end

% 許容応力度制約除外判定
is_allowable_stress = true(nnmg,1);
for ig=1:nnmg
  idmeg_ = idmeg(ig,1);
  idsecg = girder.idsecg(idmeg_);
  is_allowable_stress(ig) = issgas(idsecg);
end

% 結果の保存
nominal_girder = table(idmeg, idsub, story_name, frame_name, ...
  coord_name, idstory, idir, idx, idy, idz, idzn, ...
  is_allowable_stress);
return
end



