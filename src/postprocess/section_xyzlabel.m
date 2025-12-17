function xyzlabel = section_xyzlabel(im, convar, is_separately)
% 部材番号imと同じ断面を持つ部材の通り(x,y,z)の範囲を探索

if (nargin==2)
  is_separately = false;
end

% 共通定数
% nc = convar.nc;
% ng = convar.ng;

% 共通配列
dirBeam = convar.dirBeam;
% idnode2coord = convar.idnode2coord;
% js = convar.js;
% je = convar.je;
% repginv = convar.repginv;
% repcinv = convar.repginv;
% xcoord = convar.xcoord;
% ycoord = convar.ycoord;
% zcoord = convar.zcoord;

% 独立なx,y通りの組の集合
ixysset = find_unique_ixyset(im, convar);
nxy = size(ixysset,2);

% 対応するz通りの集合
izsset = find_izset(im, ixysset, convar);

% 対応する終端の節点番号の集合
ixyzeset = find_end_ixyzset(im, ixysset, izsset, convar);

% xyzラベルの初期化
xyzlabel = cell(1,size(ixysset,2));

for ixy = 1:nxy
  % 通り範囲の検索
  ixs = ixysset(1,ixy);
  iys = ixysset(2,ixy);
  ixe = ixyzeset{ixy}(1,1);
  iye = ixyzeset{ixy}(2,1);
  izs1 = min(izsset{ixy});
  % ize1 = ixyzeset{ixy}(3,i1);
  [izs2, i2] = max(izsset{ixy});
  ize2 = ixyzeset{ixy}(3,i2);

  switch dirBeam(im)
    case 0
      % Z方向
      if is_separately
        xyzlabel{ixy} = {...
          sprintf('%2d', ixs), ...
          sprintf('%2d', iys), ...
          sprintf_range(izs1, izs2)};
      else
        xyzlabel{ixy} = sprintf('|%2d %2d %s |', ...
          ixs, iys, sprintf_range(izs1, izs2));
      end
    case 1
      % X方向
      if is_separately
        xyzlabel{ixy} = {...
          sprintf_range(ixs, ixe), ...
          sprintf('%2d', iys), ...
          sprintf_range(izs1, ize2)};
      else
        xyzlabel{ixy} = sprintf('|%s %2d %s |', ...
          sprintf_range(ixs, ixe), iys, sprintf_range(izs1, ize2));
      end

    case 2
      % Y方向
      if is_separately
        xyzlabel{ixy} = {...
          sprintf('%2d', ixs), ...
          sprintf_range(iys, iye), ...
          sprintf_range(izs1, ize2)};
      else
        xyzlabel{ixy} = sprintf('|%2d %s %s |', ...
          ixs, sprintf_range(iys, iye), sprintf_range(izs1, ize2));
      end
  end
end
end

%--------------------------------------------------------------------------
function icgset = find_member_same_section(im, convar)
% imと同じ断面を持つ部材番号集合の探索

% 共通定数
nc = convar.nc;
ng = convar.ng;

% 共通配列
c_g = convar.c_g;
idmem2c = convar.idmem2c;
idmem2g = convar.idmem2g;
idc2mem = convar.idc2mem;
idg2mem = convar.idg2mem;
repginv = convar.repginv;
repcinv = convar.repcinv;

switch c_g(im)
  case PRM.GIRDER
    icg = idmem2g(im);
    n = ng;
    repinv = repginv;
    id2mem = idg2mem;
  case PRM.COLUMN
    icg = idmem2c(im);
    n = nc;
    repinv = repcinv;
    id2mem = idc2mem;
end

irep = repinv(icg);
icgset = 1:n;
icgset = icgset(repinv==irep);
icgset = id2mem(icgset);
end

%--------------------------------------------------------------------------
function iuxyset = find_unique_ixyset(im, convar)
% imと同じ断面を持つ部材の独立な通りの組(x,y)の探索

% 共通配列
idnode2coord = convar.idnode2coord;
idmem2js = convar.idmem2js;

% 独立な通りの組(x,y)の抽出
icgset = find_member_same_section(im, convar);
iuxyset = unique(idnode2coord(1:2,idmem2js(icgset))','rows')';

end

%--------------------------------------------------------------------------
function izset = find_izset(im, ixyset, convar)
% ixyssetと同じ断面を持つ部材の独立な通りzの探索

% 共通配列
idnode2coord = convar.idnode2coord;
idmem2js = convar.idmem2js;

% imと同じ断面を持つ部材の通りの組(x,y,z)集合
icgset = find_member_same_section(im, convar);
ixyzset = idnode2coord(:,idmem2js(icgset));

% 各組(x,y)と対応するz通り番号の検索
nset = size(ixyset,2);
izset = cell(1,nset);
for i=1:nset
  iddd = ixyzset(1,:) == ixyset(1,i) & ixyzset(2,:) == ixyset(2,i);
  izset{i} = ixyzset(3,iddd);
end
end

%--------------------------------------------------------------------------
function ixyzeset = find_end_ixyzset(im, ixysset, izsset, convar)
% 共通定数
% idns = convar.idns;

% 共通配列
idnode2coord = convar.idnode2coord;
idcoord2node = convar.idcoord2node;
idmem2js = convar.idmem2js;
idmem2je = convar.idmem2je;

nxyset = size(ixysset,2);
ixyzeset = cell(1,nxyset);
icgset = find_member_same_section(im, convar);
jsset = idmem2js(icgset);
jeset = idmem2je(icgset);
for i=1:nxyset
  ixs = ixysset(1,i);
  iys = ixysset(2,i);
  ixyzeset{i} = zeros(3,length(izsset{i}));
  for j=1:length(izsset{i})
    izs = izsset{i}(j);
    ije = jeset(jsset == idcoord2node(ixs, iys, izs));
    ixyzeset{i}(:,j) =  idnode2coord(:,ije);
  end
end
end

%--------------------------------------------------------------------------
function label = sprintf_range(s,e)
if e<10
  label = sprintf('%2d--%s', s, num2str(e));
else
  label = sprintf('%2d-%s', s, num2str(e));
end
end