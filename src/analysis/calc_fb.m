function [fb, fbb, fbc] = calc_fb(...
  mewfs, C, clam, ft, mtype, stype, Lb, options)
%calc_fb - 鋼材部材の曲げ許容応力度 fb を算定
%
%   [fb, fbb, fbc] = calc_fb(mewfs, C, clam, ft, mtype, stype, Lb, options)
%   は、梁・柱の各部材の曲げ許容応力度を計算する。梁(WFS)では横座屈
%   考慮時に siy ベース式と H/(tf*B) ベース式の最大値を採り、Ft で
%   上限を取る。柱は ft をそのまま用いる（地震時は1.5倍）。
%
%   入力引数:
%     mewfs   - WFS部材のH形断面諸元 [H,B,tw,tf,...] [nmewfs×N]
%     C       - 許容曲げ補正係数 [nmeg×3×nlc]
%     clam    - 限界細長比 [nme×1]
%     ft      - 許容引張応力 [nme×2] (1列目:長期,2列目:短期)
%     mtype   - 部材種別 (PRM.GIRDER / PRM.COLUMN) [nme×1]
%     stype   - 断面種別 (PRM.WFS 等) [nme×1]
%     Lb      - 梁の横補剛間距離 [nmeg×3] (左端,右端,中央)
%     options - オプション構造体
%                .consider_lateral_torsional_buckling : 横座屈考慮フラグ
%
%   出力引数:
%     fb  - 全部材の曲げ許容応力度 [nme×3×nlc]
%     fbb - 梁の曲げ許容応力度 [nmeg×3×nlc]
%     fbc - 柱の曲げ許容応力度 [nmec×2] (1列目:長期,2列目:短期)
%
%   備考:
%     - siy はSS7マニュアル準拠で「圧縮フランジ＋ウェブ1/6 のT形断面」
%       の弱軸断面二次半径として算出する。
%     - mewfs のA,Iz(r込み)は calc_prop_wfs により取得する。

% 計算の準備
nme = length(mtype);
nmec = sum(+(mtype)==PRM.COLUMN);
nmeg = sum(+(mtype)==PRM.GIRDER);
nlc = size(C,3);

% H形断面のr込みA,Izを一括取得（圧縮フランジ＋ウェブ1/6のT形断面 i 計算用）
if ~isempty(mewfs)
  sp_wfs = calc_prop_wfs(mewfs);
else
  sp_wfs = zeros(0,16);
end

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
        Az = sp_wfs(iwfs,1);
        Iz = sp_wfs(iwfs,5);
        lbi = Lb(ig,:);
        C1 = C(ig,:,jlc);
        I16 = Iz/2 - (H*tw^3/12)/3;
        A16 = Az/2 - (H*tw)/3;
        siy = sqrt(I16/A16);
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

