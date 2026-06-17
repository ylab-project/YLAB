function felement = update_felement(ar, cxl, cyl, idmem2node, nnode, nlc)
%update_felement - ar を更新後に全体座標系の節点単位等価節点力を再構築
%
%   felement = update_felement(ar, cxl, cyl, idmem2node, nnode, nlc) は、
%   部材座標系の ar 配列から節点単位の等価節点力 felement [nnode×6×nlc]
%   を再計算する。
%
%   入力引数:
%     ar         - 要素座標系の等価節点力 [nm×12×nlc]
%     cxl,cyl    - 部材座標系の方向余弦
%     idmem2node - 部材→節点番号 [nm×2]
%     nnode      - 節点数
%     nlc        - 荷重ケース数
%
%   出力引数:
%     felement   - 再計算後の節点単位等価節点力

% 計算の準備
nm = size(ar, 1);
felement = zeros(nnode, 6, nlc);

% 部材座標第3軸
czl = cross(cxl, cyl, 2);

% 要素荷重のセット
%   ar: 要素座標系
%   felement: 全体座標系 [nnode×6×nlc]
%   座標変換行列は{F}=[T]^T{f}
iddd = 1:nm;
for ilc = 1:nlc
  istarget = any(ar(:,:,ilc) ~= 0, 2);
  immm = iddd(istarget);
  for im = immm
    arunit = ar(im,:,ilc)';
    tt = [cxl(im,:)' cyl(im,:)' czl(im,:)'];
    in1 = idmem2node(im, 1);
    f_i = [tt*arunit(1:3); tt*arunit(4:6)];
    felement(in1, :, ilc) = felement(in1, :, ilc) + reshape(f_i, 1, 6);
    in2 = idmem2node(im, 2);
    f_j = [tt*arunit(7:9); tt*arunit(10:12)];
    felement(in2, :, ilc) = felement(in2, :, ilc) + reshape(f_j, 1, 6);
  end
end

return
end
