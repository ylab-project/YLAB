function lbnc = update_lb_nominal_column(lc, lc_nominal, nominal_column)
%COM_ この関数の概要をここに記述
%   詳細説明をここに記述

% 定数
% nmec = length(lc);
nnmc = size(nominal_column,1);

% 計算の準備
lbnc = repmat(lc_nominal,1,3);

for inc=1:nnmc

  % 途中に梁が接続されてなければ通し部材長のまま
  if all(~nominal_column.is_girder_connected(inc,:)...
      &~nominal_column.is_brace_connected(inc,:))
    continue
  end

  % 長さの計算
  ncol = nominal_column.idsub(inc,2);
  idmec = nominal_column.idmec(inc,1:ncol);
  lbc_ = lc(idmec);
  % TODO とりあえず途中にすべて梁があるかないかのみとする
  lbcmax = max(lbc_);
  % lbc(inc,1) = lbc_(1);
  % lbc(inc,2) = lbc_(ncol);
  % lbc(inc,3) = lbcmax;
  lbnc(idmec,1) = lbc_(1);
  lbnc(idmec,2) = lbc_(ncol);
  lbnc(idmec,3) = lbcmax;
end

return
end