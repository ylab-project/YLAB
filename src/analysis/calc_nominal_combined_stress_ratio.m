function rcomb = calc_nominal_combined_stress_ratio(st, ftn, ...
  nmtype, stype_n, msdim_n, options)
%calc_nominal_combined_stress_ratio - S柱の組合せ応力度比を算定
%
%   rcomb = calc_nominal_combined_stress_ratio(st, ftn, nmtype,
%   stype_n, msdim_n, options) は、名目柱の柱脚（1列）と柱頭（2列）
%   について、軸力と曲げモーメントによる応力度とせん断応力度の組合せ
%   応力度の許容引張応力度に対する比（SS7計算編 6.5.3）を荷重ケース
%   別に算定する。帳票表示だけに使い、制約には用いない。
%   - 角形鋼管: sqrt((σc+σbx+σby)^2+3τ^2)/ft（式6.101）。τは
%     両方向のせん断応力度の大きい方
%   - 円形鋼管: sqrt(σc^2+3τ^2)/ft（式6.102）
%   - H形鋼: 曲げの設計におけるウェブの考慮（柱）が「する」のとき
%     だけ sqrt((σc+σ'b)^2+3τ^2)/ft（式6.100）。σ'b＝σb·(H−2tf)/H
%     はウェブ端の曲げ応力度で強軸まわりの値から求め、τはウェブの
%     せん断応力度（強軸まわりの曲げと対になる方向のせん断力による
%     もの）。「しない」のときは算定せず NaN
%   梁・ブレース・RC柱も算定せず NaN を返す。
%
%   入力引数:
%     st      - 名目部材の応力度 [nnm×ncomp×nlc]
%     ftn     - 許容引張応力度 [nnm×2]（長期、短期）
%     nmtype  - 名目部材の種別 [nnm×1]
%     stype_n - 名目部材の断面種別 [nnm×1]
%     msdim_n - 名目部材の断面寸法 [nnm×ndim]（H形鋼は H,B,tw,tf,r）
%     options - 計算オプション（consider_web_at_column）
%
%   出力引数:
%     rcomb - 組合せ応力度比 [nnm×2×nlc]（1列:柱脚、2列:柱頭。
%             算定しない部材は NaN）

% 計算の準備
[nnm, ~, nlc] = size(st);
rcomb = nan(nnm, 2, nlc);
is_column = nmtype(:) == PRM.COLUMN;
stype_n = stype_n(:);
is_hss = is_column & stype_n == PRM.HSS;
is_hsr = is_column & stype_n == PRM.HSR;
is_tube = is_hss | is_hsr;
is_h_y = is_column & stype_n == PRM.CWFS & options.consider_web_at_column;
is_h_z = is_column & stype_n == PRM.CWFSI & options.consider_web_at_column;
is_h = is_h_y | is_h_z;
target = is_tube | is_h;

% H形鋼のウェブ端の曲げ応力度の比 (H−2tf)/H
web_ratio = zeros(nnm, 1);
web_ratio(is_h) = (msdim_n(is_h, 1) - 2*msdim_n(is_h, 4)) ...
  ./ msdim_n(is_h, 1);

% 柱脚はi端（列1〜6）、柱頭はj端（列7〜12）の成分を使う。成分は
% 1: σc、2: τy（Qyによる）、3: τz（Qzによる）、5: 局所y軸まわりの
% σb、6: 局所z軸まわりのσb
col0 = [0 6];
for iend = 1:2
  ic = col0(iend);
  for ilc = 1:nlc
    ft = ftn(:, min(ilc, 2));
    sc = abs(st(:, ic+1, ilc));
    ty = abs(st(:, ic+2, ilc));
    tz = abs(st(:, ic+3, ilc));
    sby = abs(st(:, ic+5, ilc));
    sbz = abs(st(:, ic+6, ilc));

    % 角形鋼管は局所y軸・z軸まわりの曲げを加え、円形鋼管は軸応力度だけ
    sg = zeros(nnm, 1);
    tau = zeros(nnm, 1);
    sg(is_hss) = sc(is_hss) + sby(is_hss) + sbz(is_hss);
    sg(is_hsr) = sc(is_hsr);
    tau(is_tube) = max(ty(is_tube), tz(is_tube));

    % H形鋼。X方向強軸（CWFS）は局所y軸まわりが強軸でウェブの
    % せん断はQzによるτz、Y方向強軸（CWFSI）は局所z軸まわりが
    % 強軸でウェブのせん断はQyによるτy
    sg(is_h_y) = sc(is_h_y) + sby(is_h_y).*web_ratio(is_h_y);
    tau(is_h_y) = tz(is_h_y);
    sg(is_h_z) = sc(is_h_z) + sbz(is_h_z).*web_ratio(is_h_z);
    tau(is_h_z) = ty(is_h_z);

    rcomb(target, iend, ilc) = sqrt(sg(target).^2 ...
      + 3*tau(target).^2) ./ ft(target);
  end
end

return
end
