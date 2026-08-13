function ration = calc_nominal_allowable_stress_ratio_tension_brace(...
  ration, stn, nominal, stype, A, msdim)
%calc_nominal_allowable_stress_ratio_tension_brace - TB応力比をN/Taで上書き
%
%   ration = calc_nominal_allowable_stress_ratio_tension_brace(
%     ration, stn, nominal, stype, A, msdim) は、
%   引張ブレース(TB)の応力比を等価許容応力度(Ta/A)ベースで
%   上書きする。標準の応力比計算ではF=0のためInfとなる
%   TB名目ブレースに対し、N/Taに相当する値をセットする。
%
%   入力引数:
%     ration  - 応力比配列 [nnm×PRM.RATION_NCOL×nlc]
%     stn     - 名目応力配列 [nnm×ncomp×nlc]
%     nominal - 名目部材データ構造体
%     stype   - 断面タイプ配列 [nme×1]
%     A       - 断面積配列 [nme×1]
%     msdim   - 断面寸法配列 [nme×ncol] (4列目=Ta[kN])
%
%   出力引数:
%     ration  - TB部分を上書き済みの応力比配列

nmtype = nominal.property.mtype;
idnm2m = nominal.property.idme;
ibbb = find(nmtype == PRM.BRACE);
nlc = size(ration, 3);

for imb = 1:length(ibbb)
  inm = ibbb(imb);
  ncol = nnz(idnm2m(inm, :));
  for jcol = 1:ncol
    im = idnm2m(inm, jcol);
    if stype(im) ~= PRM.TB
      continue
    end
    % 等価許容応力度 fa = Ta/A [N/mm2]
    Ta_N = msdim(im, 4) * 1e3;
    fa_tb = Ta_N / A(im);
    if fa_tb <= 0
      continue
    end
    % ration = σ/fa = N/Ta
    for ilc = 1:nlc
      ration(inm, 1, ilc) = stn(inm, 1, ilc) / fa_tb;
      ration(inm, 7, ilc) = stn(inm, 7, ilc) / fa_tb;
    end
    break
  end
end

return
end
