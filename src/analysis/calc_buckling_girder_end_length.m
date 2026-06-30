function lg_end = calc_buckling_girder_end_length(lnm, lm, mtype, ...
  js, je, nominal_girder)
%calc_buckling_girder_end_length - 梁端別の座屈K用剛比長を作成
%
%   lg_end = calc_buckling_girder_end_length(lnm, lm, mtype,
%   js, je, nominal_girder) は、柱座屈長さ係数KのG算定で用いる
%   梁剛比長さを部材端別に返す。通常は通し部材長lnmを使い、
%   通し梁の内部節点に接続するsub梁端だけ構造心間長lmを使う。
%
%   入力引数:
%     lnm            - 通し部材の構造心間距離 [nme×1]
%     lm             - セグメント構造心間距離 [nme×1]
%     mtype          - 部材タイプ [nme×1]
%     js             - 部材始端節点番号 [nme×1]
%     je             - 部材終端節点番号 [nme×1]
%     nominal_girder - 名目梁テーブル
%
%   出力引数:
%     lg_end - 梁端別の剛比長さ [nme×2]
%              (:,1)=i端、(:,2)=j端

lg_end = [lnm(:) lnm(:)];

if ~has_table_field(nominal_girder, 'isthrough')
  return
end

idmeg = nominal_girder.idmeg;
idmg2m = find(mtype == PRM.GIRDER);

for ing = 1:size(idmeg, 1)
  if ~nominal_girder.isthrough(ing)
    continue
  end

  ids = idmeg(ing, :);
  ids = ids(ids > 0);
  if numel(ids) < 2
    continue
  end

  for k = 1:(numel(ids) - 1)
    im1 = idmg2m(ids(k));
    im2 = idmg2m(ids(k + 1));
    [iend1, iend2] = find_shared_member_end(js, je, im1, im2);
    lg_end(im1, iend1) = lm(im1);
    lg_end(im2, iend2) = lm(im2);
  end
end

return
end

%--------------------------------------------------------------
function [iend1, iend2] = find_shared_member_end(js, je, im1, im2)
%find_shared_member_end - 2部材の共有節点に対応する端番号を返す
%
%   [iend1, iend2] = find_shared_member_end(js, je, im1, im2) は、
%   部材im1とim2が共有する節点を探し、それぞれの端番号を返す。

nodes1 = [js(im1) je(im1)];
nodes2 = [js(im2) je(im2)];
iend1 = 0;
iend2 = 0;

for i = 1:2
  for j = 1:2
    if nodes1(i) ~= nodes2(j)
      continue
    end
    if iend1 ~= 0
      error('YLAB:InvalidThroughGirder', ...
        'Adjacent girders share multiple nodes.');
    end
    iend1 = i;
    iend2 = j;
  end
end

if iend1 == 0
  error('YLAB:InvalidThroughGirder', ...
    'Adjacent through girders do not share a node.');
end

return
end
