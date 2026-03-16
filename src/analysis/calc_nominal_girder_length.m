function [lgmn, lgn] = calc_nominal_girder_length(idmeg, lgm)
%calc_nominal_girder_length - 名目梁長の算定
%
%   分割部材の部材長を合計し、名目梁の全長を算定する。
%
%   入力引数:
%     idmeg [nng×max_nsub] - 名目梁→sub梁マッピング
%     lgm   [nmg×1] - 梁部材長（sub部材単位）
%
%   出力引数:
%     lgmn [nmg×1] - 各sub部材に名目梁長を格納
%     lgn  [nng×1] - 名目梁長

nng = size(idmeg, 1);
lgmn = lgm;
lgn = zeros(nng, 1);

for i = 1:nng
  ncol = nnz(idmeg(i,:));
  iddd = idmeg(i, 1:ncol);
  l = sum(lgm(iddd));
  lgmn(iddd) = l;
  lgn(i) = l;
end

return
end

