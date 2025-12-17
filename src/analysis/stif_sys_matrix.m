function ksmat = stif_sys_matrix(A, Asy, Asz, Iy, Iz, JJ, ...
  cxl, cyl, lm, Em, prm, xr, yr, lrxm, lrym, cbstiff, mtype, ...
  idn2df, idf2n, idm2n1, idm2n2, idm2scb, joint, ...
  ndf, nbw, flag)

% scale変数の定義（未定義だったので追加）
scale = 1e10;  % 剛域長が部材長以上の場合の剛性スケール

% 計算の準備
nm = length(A);
ksmat = zeros(ndf,nbw);
czl = cross(cxl, cyl, 2);
z = zeros(3,3);
xrm = [xr(idm2n1) xr(idm2n2)];
yrm = [yr(idm2n1) yr(idm2n2)];

for im = 1:nm
  % 剛域長
  lrxi = lrxm(im,:);
  lryi = lrym(im,:);

  % 局所系剛性行列
  li = lm(im); Ai = A(im); Asyi = Asy(im); Aszi = Asz(im);
  Iyi = Iy(im); Izi = Iz(im); Ji = JJ(im);                 
  Ei = Em(im); pri = prm(im); jointi = joint(im,:);

  if any(lrxi+lryi>=li)
    fprintf(['警告: 部材 %d で剛域長が部材長以上です ' ...
      '(li=%.3f, lrxi=[%.3f, %.3f], lryi=[%.3f, %.3f])\n'], ...
      im, li, lrxi(1), lrxi(2), lryi(1), lryi(2));
    lrxi = [0 0];
    lryi = [0 0];
    Ai = Ai*scale;
    Asyi = Asyi*scale;
    Aszi = Aszi*scale;
    Iyi = Iyi*scale;
    Izi = Izi*scale;
    Ji = Ji*scale;
  end

  % ブレース
  if mtype(im) == PRM.BRACE || mtype(im) == PRM.HORIZONTAL_BRACE
    Asyi = Ai; Aszi = Ai;
    jointi(:) = PRM.PIN;
  end

  if idm2scb(im)>0
    kcbi = cbstiff(idm2scb(im));
    ke = stif_beam_matrix(...
      li, Ai, Asyi, Aszi, Iyi, Izi, Ji, Ei, pri, lrxi, lryi, ...
      jointi, kcbi, flag);
  else
    % TODO:剛域と柱脚ばねは同時にしか考えていない
    ke = stif_beam_matrix(...
      li, Ai, Asyi, Aszi, Iyi, Izi, Ji, Ei, pri, lrxi, lryi, ...
      jointi, [], flag);
  end

  % 剛域を考慮した座標変換
  if any([lrxi lryi]>0)
    tr = eye(12);
    tr(3,5) = -lrxi(1);
    tr(9,11) = lrxi(2);
    tr(2,6) = lryi(1);
    tr(8,12) = -lryi(2);
    ke = tr'*ke*tr;
  end

  if any(isnan(ke(:)))
    fprintf('エラー: 部材 %d でNaNが検出されました\n', im);
    fprintf('  A=%.3e, Asy=%.3e, Asz=%.3e\n', Ai, Asyi, Aszi);
    fprintf('  Iy=%.3e, Iz=%.3e, JJ=%.3e\n', Iyi, Izi, Ji);
    fprintf('  E=%.3e, pr=%.3f, l=%.3f\n', Ei, pri, li);
    fprintf('  lrxi=[%.3f, %.3f], lryi=[%.3f, %.3f]\n', ...
      lrxi(1), lrxi(2), lryi(1), lryi(2));
    disp('ke行列:');
    disp(ke);
    % error('剛性行列にNaNが含まれています');
  end

  % 局所系→全体系変換行列
  t = [cxl(im,:); cyl(im,:); czl(im,:)];
  tm = [t z z z; z t z z; z z t z; z z z t;];
  ke = tm'*ke*tm;

  % 自由度番号
  ndi = [idn2df(idm2n1(im),:) idn2df(idm2n2(im),:)];

  % 剛床を考慮した変換行列
  tg = eye(12);
  tg(1,6) = -yrm(im,1);
  tg(2,6) = xrm(im,1);
  tg(7,12) = -yrm(im,2);
  tg(8,12) = xrm(im,2);
  ke = tg'*ke*tg;

  % 剛性行列の重ね合わせ
  for i = 1:12
    for j = 1:12
      k = ndi(j)-ndi(i);
      if k>=0
        k = k+1;
        ksmat(ndi(i),k) = ksmat(ndi(i),k)+ke(i,j);
      end
    end
  end
end

% ダミー自由度の処理
iddd = 1:ndf;
iddd = iddd(idf2n(:,1)==0);
ksmat(iddd,1) = 1.d6;
return
end
