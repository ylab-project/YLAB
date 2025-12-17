function [Dmat, H, idtstory2H, Hmax, idtstory2Hmax] = ...
  Hdiff_matrix(xvar, idstory2varH, options)
%DIFFERENCE_MATRIX この関数の概要をここに記述
%   詳細説明をここに記述

% 計算の準備
idvarH = reshape(idstory2varH(idstory2varH>0),1,[]);
idvarH = unique(idvarH);
H = xvar(idvarH);
nH = length(idvarH);
idH = 1:nH;

% 有効層の検索
istarget = ~all(idstory2varH==0,2);
idstory2varH = idstory2varH(istarget,:);
[ntstory, ntaxis] = size(idstory2varH);

% 局所番号への付け替え:idstory2H
idtstory2H = idstory2varH;
for i=1:ntstory
  for j=1:ntaxis
    if (idstory2varH(i,j)>0)
      idtstory2H(i,j) = idH(idvarH==idstory2varH(i,j));
    end
  end
end

% 最大値の初期化
Hmax = zeros(ntstory,1);
idstory2varHmax = zeros(ntstory,1);
idtstory2Hmax = zeros(ntstory,1);

% 差分行列の作成
switch options.coptions.alfa_girder_height_smooth_var
  case PRM.GIRDER_HEIGHT_SMOOTH_MAX
    for i=1:ntstory
      ids2vH = idstory2varH(i,:);
      ids2vH = ids2vH(ids2vH>0);
      [Hmax(i), iii] = max(xvar(ids2vH));
      idstory2varHmax(i) = ids2vH(iii);
      idtstory2Hmax(i) = idH(ids2vH(iii)==idvarH);
    end
    Dmat = Hdiff_matrix_sub(idtstory2Hmax);

  case PRM.GIRDER_HEIGHT_SMOOTH_AXIS
    Dmat = Hdiff_matrix_sub(idtstory2H);

end
return
%--------------------------------------------------------------------------
  function Dmat = Hdiff_matrix_sub(idstory2H)
    nnn = sum(idstory2H>0)-1;
    nD = sum(nnn-1);
    Dmat = zeros(nD,nH);
    id = 0;
    for i_=1:size(idstory2H,2)
      iddd = idstory2H(:,i_);
      iddd(iddd==0) = [];
      iddd = unique(iddd,'stable');
      for j_=1:length(iddd)-1
        id = id+1;
        Dmat(id,iddd([j_ j_+1])) = [-1 1];
      end
    end
    Dmat = Dmat(1:id,:);
    return
  end
end

