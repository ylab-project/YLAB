function Q_nb = calc_Q_nominal_brace(com, rs0, cxl, cyl)
%calc_Q_nominal_brace - 名目ブレースごとの水平力成分Qを算出
%
%   Q_nb = calc_Q_nominal_brace(com, rs0, cxl, cyl) は、
%   各名目ブレースについて構成部材の応力を全体座標系に変換し、
%   加力方向への水平力成分Qを算出します。
%
%   入力引数:
%     com - 共通オブジェクト
%     rs0 - 部材応力（重ね合わせ前）[nme×ncol×nlc]
%     cxl - 部材x軸方向余弦 [nme×3]
%     cyl - 部材y軸方向余弦 [nme×3]
%
%   出力引数:
%     Q_nb - 名目ブレースごとのQ値 [nnb×nlc] (単位: N)

nominal_brace = com.nominal.brace;
brace = com.member.brace;
nnb = com.num.nominal_brace;
lcdir = com.loadcase.dir;
nlc = length(lcdir);

Q_nb = zeros(nnb, nlc);
if nnb == 0
  return
end

% z軸方向余弦・断面位置補正
czl = cross(cxl, cyl, 2);
sign_cz = ones(size(cxl, 1), 1);
sign_cz(cxl(:, 3) < 0) = -1;

idir_nom = nominal_brace.idir;
idmeb = nominal_brace.idmeb;
idme = brace.idme;

for ilc = 1:nlc
  % 加力方向の判定
  switch lcdir(ilc)
    case {PRM.EXP, PRM.EXN}
      idir_eq = PRM.X;
    case {PRM.EYP, PRM.EYN}
      idir_eq = PRM.Y;
    otherwise
      idir_eq = 0;  % 非地震ケース
  end

  N = rs0(:, 1, ilc);
  Qy = rs0(:, 2, ilc);
  Qz = rs0(:, 3, ilc);

  for inb = 1:nnb
    ibij = idmeb(inb, :);
    % 非地震ケースはブレース配置方向で投影
    if idir_eq > 0
      ideq = idir_eq;
    else
      ideq = idir_nom(inb);
    end
    Q = 0;
    for ij = find(ibij > 0)
      im = idme(ibij(ij));
      Q = Q + (N(im) * cxl(im, ideq) ...
        + Qy(im) * cyl(im, ideq) ...
        + Qz(im) * czl(im, ideq)) * sign_cz(im);
    end
    Q_nb(inb, ilc) = Q;
  end
end

return
end
