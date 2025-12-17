function cbs = calc_column_base_section(...
  Dcb, cbstiff, column_base, column_base_list)
%CALC_COLUMN_BASE_SECTION この関数の概要をここに記述
% 柱脚剛性の計算

nseccb = length(column_base.type);
cbsid = zeros(1,nseccb);
cbsDf = zeros(nseccb,1);

for i=1:nseccb
  % 属性セット
  switch column_base.type(i)
    case PRM.CB_DIRECT
      % 剛性指定
    case PRM.CB_LIST
      % 柱脚リスト
      if column_base.idlist(i)==0
        continue
      end
      Dlist = column_base_list(column_base.idlist(i)).D;
      kbslist = column_base_list(column_base.idlist(i)).kbs;
      Dflist = column_base_list(column_base.idlist(i)).Df;
      [~, idcb_] = min(abs(Dlist-Dcb(i)));
      cbstiff(i) = kbslist(idcb_);
      cbsid(i) = idcb_;
      cbsDf(i) = Dflist(idcb_);
  end
end
cbs.stiff = cbstiff;
cbs.id = cbsid;
cbs.Df = cbsDf;
end

