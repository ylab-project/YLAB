function lbgn = calc_nominal_lb_girder(lbg, nominal_girder)
% 名目梁部材の補剛間隔を計算する
% 
% この関数は、名目梁部材の補剛間隔を算出する。各名目梁部材に対して
% 開始端、終了端、および最大値の補剛間隔を決定し、テーブル形式で
% 返す。
%
% Syntax
%   lbgn = calc_nominal_lb_girder(lbg, nominal_girder)
%
% Inputs
%   lbg (double array): 部材の補剛間隔配列
%   nominal_girder (struct): 名目梁部材の情報を含む構造体
%       .idmeg: 名目梁部材と構成部材のインデックス対応表
%
% Outputs
%   lbgn (table): 名目梁部材の補剛間隔テーブル
%       is: 開始端補剛間隔
%       ie: 終了端補剛間隔
%       max: 最大補剛間隔
%
% Example
%   >> lbg = [3.5, 2.8, 4.0; 4.0, 3.2, 4.5; 3.8, 3.0, 4.2];
%   >> nominal_girder.idmeg = [1, 2; 3, 0];
%   >> lbgn = calc_nominal_lb_girder(lbg, nominal_girder)
%   lbgn = 
%       is    ie    max
%       3.5   4.0   4.0
%       3.8   3.8   4.2

% 定数
% nmg = size(lbg,1);
nnmg = size(nominal_girder.idmeg,1);

% 計算の準備
idnmg2mg = nominal_girder.idmeg;

% 初期化
lbgn_ = zeros(nnmg,3);
for inmg=1:nnmg
  ncol = nnz(idnmg2mg(inmg,:));
  im1 = idnmg2mg(inmg,1);
  im2 = idnmg2mg(inmg,ncol);
  if ncol==1
    lbgn_(inmg,:) = lbg(im1,:);
  else
    lbgn_(inmg,1) = lbg(im1,1);
    lbgn_(inmg,2) = lbg(im2,1);
    %TODO: 中央部材の扱いは保留
    lbgn_(inmg,3) = lbg(im1,3);
  end
end

% Tableに変換
lbgn = array2table(lbgn_, ...
    'VariableNames', {'is','ie','max'});
end

