function lbcn = calc_nominal_lb_column(lmc, nominal_column)
% 名目柱部材の補剛間隔を計算する
% 
% この関数は、名目柱部材の補剛間隔を算出する。各名目柱部材に対して
% 開始端、終了端、および最大値の補剛間隔を決定し、テーブル形式で
% 返す。
%
% Syntax
%   lbcn = calc_nominal_lb_column(lmc, nominal_column)
%
% Inputs
%   lmc (double array): 部材の補剛間隔配列
%   nominal_column (struct): 名目柱部材の情報を含む構造体
%       .idmec: 名目柱部材と構成部材のインデックス対応表
%
% Outputs
%   lbcn (table): 名目柱部材の補剛間隔テーブル
%       is: 開始端補剛間隔
%       ie: 終了端補剛間隔
%       max: 最大補剛間隔
%
% Example
%   >> lmc = [3.5, 4.0, 3.8, 4.2];
%   >> nominal_column.idmec = [1, 2; 3, 4];
%   >> lbcn = calc_nominal_lb_column(lmc, nominal_column)
%   lbcn = 
%       is    ie    max
%       3.5   4.0   4.0
%       3.8   4.2   4.2

% 定数
% nmg = size(lbg,1);
nnmc = size(nominal_column.idmec,1);

% 計算の準備
idnmc2mc = nominal_column.idmec;

% 初期化
lbcn_ = zeros(nnmc,3);
for inmc=1:nnmc
  ncol = nnz(idnmc2mc(inmc,:));
  im1 = idnmc2mc(inmc,1);
  im2 = idnmc2mc(inmc,ncol);
  if ncol==1
    lbcn_(inmc,:) = lmc(im1);
  else
    lbcn_(inmc,1) = lmc(im1);
    lbcn_(inmc,2) = lmc(im2);
    %TODO: 中央部材の扱いは保留
    if lmc(im1)>lmc(im2)
      lbcn_(inmc,3) = lmc(im1);
    else
      lbcn_(inmc,3) = lmc(im2);
    end
  end
end

% Tableに変換
lbcn = array2table(lbcn_, ...
    'VariableNames', {'is','ie','max'});
end

