function C = calc_modified_C(...
  rs, Mc, M0, lm, lb, lxc, idg2m, is_through_girder)
% 弾性横座屈モーメントの修正係数Cの算定

% 計算の準備
nlc = size(rs,3);
nmeg = length(lb);
C = ones(nlc*3, nmeg); % (左端,右端,中央)x荷重ケース
for ilc = 1:nlc
  for ig = 1:nmeg
    im = idg2m(ig);
    Ml = -rs(im,5,ilc);
    Mr = rs(im,11,ilc);
    Mcc = -Mc(im,ilc);
    M0c = M0(im, 1);
    Mmax = abs(Ml-(Mr-Ml-4*M0c)^2/(16*M0c));
    lmax = lm(im)*(4*M0c+Ml-Mr)/(8*M0c);
    l = lm(im);
    lb1 = lb(im,1);
    lb2 = lb(im,2);
    lxc12 = [lxc(im,1) l-lxc(im,2)];
    for j=1:3
      switch j
        case 1
          % 左端
          if is_through_girder(ig,1)
            % 通し梁
            continue
          end
          M12 = [Ml calcMx(lb1)];
          x12 = [0 lb1];
        case 2
          % 右端
          if is_through_girder(ig,2)
            % 通し梁
            continue
          end
          M12 = [calcMx(l-lb2) Mr];
          x12 = [l-lb2 l];
        case 3
          % 中央
          if is_through_girder(ig,3)
            % 通し梁
            continue
          end
          M12 = calcMx(lxc12);
          x12 = lxc12;
      end

      % 対称変形モード
      if x12(1)<lmax && lmax<x12(2) &&  max(abs(M12))<Mmax
        continue
      end

      % 逆称変形モード
      [M1, M2] = sortM12(M12);
      C(3*(ilc-1)+j, ig) = 1.75-1.05*(M2/M1)+0.3*(M2/M1)^2;
    end
  end
end

% TODO: とりあえず
C(C>=2.3) = 2.3;
C_ = C;
C = zeros(nmeg,3,nlc);
for ilc = 1:nlc
  for ig = 1:nmeg
    id = (ilc-1)*3;
    C(ig,1,ilc) = C_(id+1,ig);
    C(ig,2,ilc) = C_(id+2,ig);
    C(ig,3,ilc) = C_(id+3,ig);
  end
end

return
%--------------------------------------------------------------------------
  function Mx = calcMx(x)
    Mx = 4*M0c*x.^2/l^2+(Mr-Ml-4*M0c).*x/l+Ml;
  end
  function [M1, M2] = sortM12(M12)
    if abs(M12(1))>=abs(M12(2))
      M1 = M12(1);
      M2 = M12(2);
    else
      M1 = M12(2);
      M2 = M12(1);
    end
  end
end

