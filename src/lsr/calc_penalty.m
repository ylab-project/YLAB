function [pfval, vio] = calc_penalty(fval, cvec, muvec, tau, ...
  penalty_method, ppp)
%calc_penalty - 制約違反量を求めてペナルティ関数値を評価する
%
%   [pfval, vio] = calc_penalty(fval, cvec, muvec, tau, ...
%     penalty_method, ppp) は、許容差以下の制約値を充足とみなした
%   違反量を求め、目的関数値へペナルティ項を加えた値を返す。
%
%   入力引数:
%     fval           - 目的関数値
%     cvec           - 制約値 [1×nc]（正が違反）
%     muvec          - 制約ごとのペナルティ係数 [nc×1]
%     tau            - 制約値の許容差。cvec<=tau を充足とする
%     penalty_method - ペナルティ方式。PRM.PENALTY_SUM_TOTAL（違反量と
%                      係数の積の総和）、PENALTY_MAXIMUM（違反量ノルム
%                      に最大係数）、PENALTY_WEIGHTED_NORM（係数を掛けた
%                      違反量のノルム）
%     ppp            - 違反量ノルムの指数（総和方式では使わない）
%
%   出力引数:
%     pfval - ペナルティ関数値
%     vio   - 制約違反量 [1×nc]。cvec<=tau で0、cvec>tau で cvec

% 許容差以下の制約値は充足とみなし違反量を0にする
vio = cvec;
vio(vio <= tau) = 0;
switch penalty_method
  case PRM.PENALTY_SUM_TOTAL
    % 違反量と係数の積の総和を加える
    pfval = fval+sum(vio(:).*muvec(:));
  case PRM.PENALTY_MAXIMUM
    % 違反量の ppp ノルムに最大係数を掛けて加える
    vvv = sum(vio.^ppp,2)^(1/ppp);
    pfval = fval+max(muvec)*vvv;
  case PRM.PENALTY_WEIGHTED_NORM
    % 係数を掛けた違反量の ppp ノルムを加える（係数は制約ごとに効く）
    vvv = sum((vio(:).*muvec(:)).^ppp)^(1/ppp);
    pfval = fval+vvv;
end

return
end
