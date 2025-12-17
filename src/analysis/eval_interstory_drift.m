function [condrift, drift_angle, idcolumn, dx, dy] = eval_interstory_drift(...
  dispnode, floor_height, lcdir, dmax, idfl2s, idmc2st, idc2n, ...
  idn2z, options)

% 定数
nlc = size(dispnode,3);
nfl = length(idfl2s);
nmc = size(idmc2st,1);
nph = options.num_penthouse_floor;

% 計算の準備
dx = zeros(nmc, nlc);
dy = zeros(nmc, nlc);
drift_angle = zeros(nfl-nph, nlc);
idcolumn = zeros(nfl, nlc);

% 各柱位置での層間変形角
for ic=1:nmc
  dx1 = dispnode(idc2n(ic,1),1,:);
  dx2 = dispnode(idc2n(ic,2),1,:);
  dy1 = dispnode(idc2n(ic,1),2,:);
  dy2 = dispnode(idc2n(ic,2),2,:);
  dx(ic,:) = abs(reshape(dx2-dx1,1,[]))/floor_height(ic,1);
  dy(ic,:) = abs(reshape(dy2-dy1,1,[]))/floor_height(ic,2);
end

% 荷重ケースごとの最大層間変形角
idc2fl1 = idn2z(idc2n(:,1));
idc2fl2 = idn2z(idc2n(:,2))-1;
icccc = 1:nmc;
for ifl = 1:nfl-nph
  istarget = idc2fl1<=ifl & ifl<=idc2fl2;
  iccc = icccc(istarget);
  % is = idfl2s(ifl);
  % iccc = iddd(idmc2st==is);
  for ilc=1:nlc
    switch ilc
      case PRM.EXP
        ddd = dx(iccc,ilc);
      case PRM.EXN
        ddd = dx(iccc,ilc);
      case PRM.EYP
        ddd = dy(iccc,ilc);
      case PRM.EYN
        ddd = dy(iccc,ilc);
      otherwise
        continue
    end
    [dddmax, idmax] = max(ddd);
    drift_angle(ifl,ilc) = dddmax;
    idcolumn(ifl,ilc) = iccc(idmax);
  end
end

% 制約関数値に変換
condrift = reshape(drift_angle(:,lcdir>1),[],1)*dmax-1;
return
end

