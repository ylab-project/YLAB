function xyzlabel = member_xyzlabel(id, convar, ncol)
if nargin==2
  ncol = 1;
end

% 共通配列
dirBeam = convar.dirBeam;
idnode2coord = convar.idnode2coord;
idmem2js = convar.idmem2js;
idmem2je = convar.idmem2je;

switch dirBeam(id)
  case 0
    % Z方向
    fmt1a_ = '|%2d %2d %2d-%2s |';
    fmt1b_ = '|          |';
    fmt2a_ = '|%2d%2d%2d |';
    fmt2b_ = '|    %2d |';
    xl = idnode2coord(1,idmem2js(id));
    yl = idnode2coord(2,idmem2js(id));
    zl = idnode2coord(3,idmem2js(id));
    zl2 = idnode2coord(3,idmem2je(id));
    sss = num2str(zl2);
    if length(sss)<2
      sss = ['-' sss];
    end
    switch ncol
      case 0
        xyzlabel = {num2str(xl), num2str(yl), [num2str(zl) '-' sss]};
      case 1
        xyzlabel = {sprintf(fmt1a_, xl, yl, zl, sss), ...
          sprintf(fmt1b_)};
      case 2
        xyzlabel = {sprintf(fmt2a_, xl, yl, zl), ...
          sprintf(fmt2b_, zl2)};
    end
  case 1
    % X方向
    fmt1a_ = '|%2d-%s %2d %2d |';
    fmt1b_ = '|         |';
    fmt2a_ = '|%2d%2d%2d |';
    fmt2b_ = '|%2d     |';
    xl = idnode2coord(1,idmem2js(id));
    yl = idnode2coord(2,idmem2js(id));
    zl = idnode2coord(3,idmem2js(id));
    xl2 = idnode2coord(1,idmem2je(id));
    sss = num2str(xl2);
    if length(sss)<2
      sss = ['-' sss];
    end
    switch ncol
      case 0
        xyzlabel = {[num2str(xl) '-' sss], num2str(yl), num2str(zl)};
      case 1
        xyzlabel = {sprintf(fmt1a_, xl, sss, yl, zl), ...
          sprintf(fmt1b_)};
      case 2
        xyzlabel = {sprintf(fmt2a_, xl, yl, zl), ...
          sprintf(fmt2b_, xl2)};
    end
  case 2
    % Y方向
    fmt1a_ = '|%2d %2d-%s %2d |';
    fmt1b_ = '|          |';
    fmt2a_ = '|%2d%2d%2d |';
    fmt2b_ = '|  %2d   |';
    xl = idnode2coord(1,idmem2js(id));
    yl = idnode2coord(2,idmem2js(id));
    zl = idnode2coord(3,idmem2js(id));
    yl2 = idnode2coord(2,idmem2je(id));
    sss = num2str(yl2);
    if length(sss)<2
      sss = ['-' sss];
    end
    switch ncol
      case 0
        xyzlabel = {num2str(xl), [num2str(yl) '-' sss], num2str(zl)};
      case 1
        xyzlabel = {sprintf(fmt1a_, xl, yl, sss, zl), ...
          sprintf(fmt1b_)};
      case 2
        xyzlabel = {sprintf(fmt2a_, xl, yl, zl), ...
          sprintf(fmt2b_, yl2)};
    end
end
end
