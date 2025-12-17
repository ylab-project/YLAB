function [idnode2df, idnode2ind, idstory2noderep, xr, yr, ndf, ...
  idf2node, story_isrigid] = countup_node2df(com)
% idnode2df   <- idnjf  : 節点番号から自由度番号への変換
% idnode2ind  <- njdp   : 節点番号から独立節点番号への変換
% idnoderep   <- njr    : 剛床の代表節点番号
% xr : 重心からのx方向距離
% yr : 重心からのy方向距離

% 共通定数
nnode = com.nnode;
nstory = com.nstory;

% 共通配列
node = com.node;
story = com.story;
story_isrigid = story.isrigid;
% flex_diaphragm = com.flex_diaphragm;
% isflex = false(1,nnode);
% isflex(flex_diaphragm.idnode) = true;

% 剛床の代表節点
idnode2ind = (1:nnode)';
idstory2noderep = nan(nstory,1);
id = 0; iddd = 1:nnode;
for is=1:nstory
  if story_isrigid(is)
    id = id+1;
    ttt = iddd(node.idz==story.idz(is)&node.type==PRM.NODE_STANDARD);
    if isempty(ttt)
      % 剛床に属する節点がない
      story_isrigid(is) = false;
      continue
    end
    idnode2ind(ttt) = ttt(1);
    idstory2noderep(is) = ttt(1);
  end
end

% 節点の独立自由度数
jf = 3*ones(nnode,1);
jf(unique(idnode2ind)) = 6;

% 剛床の節点自由度変換
idnode2df = zeros(nnode,6);
njef = cumsum(jf);
njsf = [1; njef(1:end-1)+1];
ndf = njef(end);
for i = 1:nnode
  if jf(i) == 6
    idnode2df(i,:) = njsf(i):njef(i);
  else
    idnode2df(i,1) = idnode2df(idnode2ind(i),1);
    idnode2df(i,2) = idnode2df(idnode2ind(i),2);
    idnode2df(i,3:5) = njsf(i):njef(i);
    idnode2df(i,6) = idnode2df(idnode2ind(i),6);
  end
end

% 同一化節点の自由度番号付け替え
for i=1:nnode
  if node.idrep(i)==0
    continue
  end
  idnoderep = node.idrep(i);
  idnode2df(i,:) = idnode2df(idnoderep,:);
end

% 重心からの節点距離
xr = zeros(nnode,1);
yr = zeros(nnode,1);
% xr = node.x;
% yr = node.y;
iddd = 1:nstory;
for i = 1:nnode
  if node.type(i) ~= PRM.NODE_STANDARD
    continue
  end
  % 代表節点の層番号
  ist = iddd(story.idz == node.idstory(idnode2ind(i)));
  % 重心が指定されているか判定
  if isempty(ist)
    continue
  end
  if story.isrigid(ist) && ~isnan(story.xg(ist))
    % 重心からの距離の計算
    xr(i) = node.x(i) - story.xg(ist);
    yr(i) = node.y(i) - story.yg(ist);
  end
end

% 自由度から節点番号への変換
idf2node = zeros(ndf,2);
for in=1:nnode
  idf = idnode2df(in,:);
  for j=1:6
    idf2node(idf(j),1) = in;
    idf2node(idf(j),2) = j;
  end
end

% 剛床代表節点への置き換え
for in=1:nnode
  idf = idnode2df(in,[1 2 6]);
  idf2node(idf,1) = idnode2ind(in);
end
return
end
