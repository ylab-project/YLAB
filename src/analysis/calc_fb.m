function [fb, fbb, fbc] = calc_fb(...
  mewfs, C, clam, ft, mtype, stype, Lb, options)
% Calculation of allowable bending stress (fb)

% 計算の準備
nme = length(mtype);
nmec = sum(+(mtype)==PRM.COLUMN);
nmeg = sum(+(mtype)==PRM.GIRDER);
nlc = size(C,3);

% 曲げ許容応力度の算定
fb = zeros(nme,3,nlc); % (左端,右端,中央)x荷重ケース
fbb = zeros(nmeg,3,nlc);
fbc = zeros(nmec,2);
ic = 0; ig = 0; iwfs = 0;
for im = 1:nme
  if stype(im)==PRM.WFS
    iwfs = iwfs+1;
  end
  switch mtype(im)
    case PRM.GIRDER
      ig = ig+1;
      for jlc = 1:nlc
        if jlc==1
          Ft = ft(im,1);
        else
          Ft = ft(im,2);
        end
        if ~options.consider_lateral_torsional_buckling
          fbb(ig,:,jlc) = Ft;
          continue
        end
        if stype(im)~=PRM.WFS
          fbb(ig,:,jlc) = Ft;
          continue
        end
        H = mewfs(iwfs,1);
        B = mewfs(iwfs,2);
        tw = mewfs(iwfs,3);
        tf = mewfs(iwfs,4);
        lbi = Lb(ig,:);
        C1 = C(ig,:,jlc);
        siy = sqrt((tf*B^3/12)/(tf*B+(H/6-tf)*tw));
        fb1 = (1-0.4*(lbi/siy).^2./(C1*clam(im)^2)).*Ft;
        fb2 = 89000./(lbi*H/(tf*B));
        if jlc>1
          fb2 = fb2*1.5;
        end
        fb_ = max(fb1,fb2);
        fb_(fb_>Ft) = Ft;
        fbb(ig,:,jlc) = fb_;
      end
    case PRM.COLUMN
      ic = ic+1;
      fbc(ic,1) = ft(im,1);
  end
end
fbc(:,2) = fbc(:,1)*1.5;

% 結果の整理
fb(mtype==PRM.GIRDER,:,:) = fbb;
for j=1:3
  fb(mtype==PRM.COLUMN,j,1) = fbc(:,1);
  for ilc=2:5
    fb(mtype==PRM.COLUMN,j,ilc) = fbc(:,2);
  end
end

return
end

