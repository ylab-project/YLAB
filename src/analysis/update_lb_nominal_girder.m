function lbng = update_lb_nominal_girder(lg, lbng)
%COM_ この関数の概要をここに記述
%   詳細説明をここに記述
nmeg = length(lg);

for ig=1:nmeg

  % 何も指定がなければ部材長をセット
  if all(isnan(lbng(ig,1:3)))
    lbng(ig,1:3) = lg(ig);
    continue
  end

  % 左だけがセットされていれば均等とする
  if ~isnan(lbng(ig,1)) && all(isnan(lbng(ig,2:3)))
    lbng(ig,1:3) = lbng(ig,1);
    continue
  end

  % 左右がセットされていて最大の指定がなければ左右の大きい方を最大長とする
  if all(~isnan(lbng(ig,1:2))) && isnan(lbng(ig,3))
    lbng(ig,3) = max(lbng(ig,1:2));
  end

  % 最大だけがセットされていて左右の指定がなければ最大長を左右長とする
  % -> 補剛なしの場合
  if all(isnan(lbng(ig,1:2))) && ~isnan(lbng(ig,3))
    lbng(ig,1:2) = lbng(ig,3);
  end

end

return
end