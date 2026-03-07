function lnm_bk = calc_nominal_column_length_for_buckling( ...
  lnm, lr, mtype, idmc2nc, nominal_column)
%calc_nominal_column_length_for_buckling - 座屈解析用名目部材長の計算
%
%   lnm_bk = calc_nominal_column_length_for_buckling(...) は、
%   通し柱の名目部材長 lnm から方向別Σlrを控除した
%   座屈解析用の部材長を算出する。
%
%   入力引数:
%     lnm            - 通し部材長 [nme×1]
%     lr             - 剛域長 (struct: columnx, columny)
%     mtype          - 部材タイプ [nme×1]
%     idmc2nc        - 柱→名目柱番号 [nme×2]
%     nominal_column - 通し柱テーブル
%
%   出力引数:
%     lnm_bk - 座屈解析用名目部材長 [nme×2]

lnm_bk = [lnm lnm];
slr_x = sum(lr.columnx, 2);
slr_y = sum(lr.columny, 2);
idmc2nc_ = idmc2nc(:,1);
nnc_ = size(nominal_column.idmec, 1);
tlr_x = accumarray(idmc2nc_, slr_x, [nnc_ 1]);
tlr_y = accumarray(idmc2nc_, slr_y, [nnc_ 1]);
lnm_bk(mtype==PRM.COLUMN,:) = ...
  lnm_bk(mtype==PRM.COLUMN,:) ...
  - [tlr_x(idmc2nc_) tlr_y(idmc2nc_)];

return
end
