function [congdef, deflection_angle] = ...
  calc_nominal_girder_deflection( ...
  idmeg, idmg2m, gstype, lm, lf, ...
  rs, M0sw, Em, Iy, gdmax)
%calc_nominal_girder_deflection - 名目梁単位のたわみ算定
%
%   SS7マニュアル 6.4.4 式(6.37)に基づき、名目梁単位で
%   弾性たわみを算定する。中央Mは区分的放物線評価で
%   算出し、M0 = M_center - (ML+MR)/2 とする。
%
%   入力引数:
%     idmeg  [nng×nsub] - 名目梁→sub梁マッピング
%     idmg2m [nmeg×1] - 梁→部材インデックス
%     gstype [nmeg×1] - 梁断面タイプ
%     lm     [nme×1] - 部材長
%     lf     構造体 - フェイス長 (.girder [nmeg×2])
%     rs     [nme×12×nlc] - 部材応力
%     M0sw   [nme×1] - 付加曲げ＋自重モーメント
%     Em     [nme×1] - ヤング率
%     Iy     [nme×1] - 断面二次モーメント（剛性計算条件準拠）
%     gdmax  スカラー - たわみ制限値(1/gdmax)
%
%   出力引数:
%     congdef [nng×1] - たわみ制約値
%     deflection_angle [nng×1] - たわみ角

nng = size(idmeg, 1);
deflection_angle = zeros(nng, 1);

for ing = 1:nng
  igs = idmeg(ing,:);
  igs(igs==0) = [];
  ig0 = igs(1);
  if gstype(ig0) ~= PRM.WFS
    continue
  end

  nsub = length(igs);
  im_igs = idmg2m(igs);

  % sub 部材の M 分布データ収集
  sub_lm = lm(im_igs);
  sub_Ml = zeros(nsub, 1);
  sub_Mr = zeros(nsub, 1);
  sub_M0 = zeros(nsub, 1);
  for k = 1:nsub
    im = im_igs(k);
    sub_Ml(k) = -rs(im, 5, 1);
    sub_Mr(k) = rs(im, 11, 1);
    sub_M0(k) = M0sw(im, 1);
  end
  sub_x0 = [0; cumsum(sub_lm(1:end-1))];

  % 名目梁の内法スパン
  lnom = sum(sub_lm);
  lf_l = lf.girder(ig0, 1);
  lf_r = lf.girder(igs(end), 2);
  lgn = lnom - lf_l - lf_r;
  if lgn <= 0
    continue
  end

  % 中央 M（区分的放物線評価）
  xc = lf_l + lgn / 2;
  Mc = calcMx_pw(xc, sub_x0, sub_lm, ...
    sub_Ml, sub_Mr, sub_M0);

  % M0: (ML+MR)/2 - M_center（内部M0と同符号）
  ML = sub_Ml(1);
  MR = sub_Mr(end);
  M0_nom = (ML + MR) / 2 - Mc;

  % たわみ算定（式6.37）
  Eg_ = Em(im_igs(1));
  Iy_ = Iy(im_igs(1));
  Mcg = ML + MR;
  delta = 5*M0_nom*lgn^2 / (48*Eg_*Iy_) ...
    - Mcg / (16*Eg_*Iy_) * lgn^2;
  deflection_angle(ing) = delta / lgn;
end

congdef = abs(deflection_angle) * gdmax - 1;

return
end

%------------------------------------------------------------------
function Mx = calcMx_pw(x, sub_x0, sub_lm, ...
  sub_Ml, sub_Mr, sub_M0)
%calcMx_pw - 区分的放物線でM(x)を評価
ksub = find(sub_x0 <= x, 1, 'last');
t = x - sub_x0(ksub);
lk = sub_lm(ksub);
Mlk = sub_Ml(ksub);
Mrk = sub_Mr(ksub);
M0k = sub_M0(ksub);
Mx = 4*M0k*t^2/lk^2 ...
  + (Mrk - Mlk - 4*M0k)*t/lk + Mlk;

return
end
