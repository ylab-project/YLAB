function ksmat = stif_sys_matrix(A, Asy, Asz, Iy, Iz, JJ, ...
  cxl, cyl, lm, Em, Gm, xr, yr, lrxm, lrym, cbstiff, ...
  mtype, idn2df, idf2n, idm2n1, idm2n2, idm2scb, joint, ...
  ndf, nbw, flag, br_stif, factor_Iz, factor_J)
%stif_sys_matrix - 全体剛性行列の組立（帯行列形式）
%
%   ksmat = stif_sys_matrix(A, Asy, Asz, Iy, Iz, JJ, cxl, cyl, lm, ...
%     Em, Gm, xr, yr, lrxm, lrym, cbstiff, mtype, idn2df, idf2n, ...
%     idm2n1, idm2n2, idm2scb, joint, ndf, nbw, flag, br_stif, ...
%     factor_Iz, factor_J) は、各部材の要素剛性行列を組立て全体剛性
%   行列を帯行列形式で返す。梁はstif_beam_matrix、ブレースは br_stif
%   事前計算 ke を用いる。
%
%   入力引数:
%     A, Asy, Asz - 断面積・せん断断面積Y/Z [nm×1]
%     Iy, Iz, JJ  - 断面二次モーメントY/Z・ねじり定数 [nm×1]
%     cxl, cyl    - 部材局所系x/y軸の方向余弦 [nm×3]
%     lm          - 部材長 [nm×1]
%     Em, Gm      - ヤング係数・せん断弾性係数 [nm×1]
%     xr, yr      - 剛床重心座標 [nnode×1]
%     lrxm, lrym  - 剛域長X/Y [nm×2]
%     cbstiff     - 複合梁剛性配列
%     mtype       - 部材種別 [nm×1]（PRM.GIRDER等）
%     idn2df      - 節点→自由度番号 [nnode×6]
%     idf2n       - 自由度→節点番号 [ndf×2]
%     idm2n1,idm2n2 - 部材両端節点番号 [nm×1]
%     idm2scb     - 部材→複合梁マッピング [nm×1]
%     joint       - 接合条件 [nm×4]
%     ndf         - 全自由度数
%     nbw         - 帯幅
%     flag        - 剛性行列計算フラグ
%     br_stif     - ブレース剛性構造体配列（空可）
%     factor_Iz   - 梁の弱軸剛性 Iz の係数（スカラー、0=考慮OFF）
%     factor_J    - 捩り剛性 J の係数 [nm×1]（0=考慮OFF）
%
%   出力引数:
%     ksmat - 全体剛性行列（帯行列形式）[ndf×nbw]
%
%   備考:
%     - factor_Iz=0 / factor_J(im)=0 の場合、該当剛性を
%       PRM.STIFF_IGNORE_FACTOR 倍して微小化（SS7互換、完全 0 は
%       数値問題）。Iz は梁のみ（mtype==PRM.GIRDER）に factor_Iz を
%       適用、柱は通常値。J は部材種別不問で factor_J に従う。
%     - 剛域長が部材長以上の場合、剛性をscale倍で実質固結化する。

% 剛域長が部材長以上の場合の剛性スケール
scale = 1e10;

% 計算の準備
nm = length(A);
ksmat = zeros(ndf,nbw);
czl = cross(cxl, cyl, 2);
z = zeros(3,3);
xrm = [xr(idm2n1) xr(idm2n2)];
yrm = [yr(idm2n1) yr(idm2n2)];

% Iz/J 係数の事前展開（ループ内分岐を排除し単純乗算で済ませる）
% 梁: factor_Iz==0 なら STIFF_IGNORE_FACTOR、非0 なら factor_Iz。柱: 1
% 0 を完全 0 にせず微小値で代用するのは数値問題回避のため
Iz_fac = ones(nm, 1);
if factor_Iz == 0
  Iz_fac(mtype == PRM.GIRDER) = PRM.STIFF_IGNORE_FACTOR;
else
  Iz_fac(mtype == PRM.GIRDER) = factor_Iz;
end
J_fac = factor_J;
J_fac(J_fac == 0) = PRM.STIFF_IGNORE_FACTOR;

% ブレースのインデックスマップ
br_im_map = zeros(nm, 1);
for idx_ = 1:length(br_stif)
  br_im_map(br_stif(idx_).im) = idx_;
end

for im = 1:nm
  if br_im_map(im) > 0
    % ブレース: 事前計算済みkeを使用
    bidx = br_im_map(im);
    ke = br_stif(bidx).ke;
    ndi = br_stif(bidx).ndi;
  else
    % 梁要素
    
    % 剛域長
    lrxi = lrxm(im,:);
    lryi = lrym(im,:);

    % 局所系剛性行列
    li = lm(im); Ai = A(im);
    Asyi = Asy(im); Aszi = Asz(im);
    Iyi = Iy(im);
    Izi = Iz(im) * Iz_fac(im);
    Ji = JJ(im) * J_fac(im);
    Ei = Em(im); Gi = Gm(im);
    jointi = joint(im,:);

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

    if idm2scb(im)>0
      kcbi = cbstiff(idm2scb(im));
      ke = stif_beam_matrix(li, Ai, Asyi, Aszi, Iyi, Izi, Ji, ...
        Ei, Gi, lrxi, lryi, jointi, kcbi, flag);
    else
      ke = stif_beam_matrix(li, Ai, Asyi, Aszi, Iyi, Izi, Ji, ...
        Ei, Gi, lrxi, lryi, jointi, [], flag);
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
      fprintf('  E=%.3e, G=%.3e, l=%.3f\n', Ei, Gi, li);
      fprintf('  lrxi=[%.3f, %.3f], lryi=[%.3f, %.3f]\n', ...
        lrxi(1), lrxi(2), lryi(1), lryi(2));
      disp('ke行列:');
      disp(ke);
    end

    % 局所系→全体系変換行列
    t = [cxl(im,:); cyl(im,:); czl(im,:)];
    tm = [t z z z; z t z z; z z t z; z z z t];
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
  end

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
