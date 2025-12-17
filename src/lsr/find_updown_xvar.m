function [upsec, dwsec, xvar] = find_updown_xvar(...
  idvar, sechss, secwfs, ids2var, ids2type)
%FIND_NEAREST_HTHICK この関数の概要をここに記述
%   詳細説明をここに記述

% 設計変数がどの断面に関係するかをチェック



% H,Bに適合する規格断面のチェック
isGivenH = abs(seclist.H-secwfs(1))<=options.tolHgap;
isGivenB = abs(seclist.B-secwfs(2))<=options.tolBgap;
isGiven = isGivenH&isGivenB;
seclist = [seclist.H(isGiven) seclist.B(isGiven) ...
  seclist.tw(isGiven) seclist.tf(isGiven)];


% 判定
% TODO 幅厚比距離にする？
switch twortf
  case 'tw'
    tid = 3;
  case 'tf'
    tid = 4;
  otherwise
    error('twかtfを指定してください')
end

% ワンサイズアップ
ttt = seclist(:,tid); isup = ttt>secwfs(tid);
if all(~isup)
  idup = [];
else
  ttt(~isup) = inf; tup = min(ttt);
  sss = seclist; sss(ttt~=tup,tid) = inf;
  ddd = sum((sss-repmat(secwfs,size(sss,1),1)).^2,2);
  [~,idup] = min(ddd);
end
upsec = seclist(idup,:);

% ワンサイズダウン
ttt = seclist(:,tid); isdw = ttt<secwfs(tid);
if all(~isdw)
  iddw = [];
else
  ttt(~isdw) = -inf; tdw = max(ttt);
  sss = seclist; sss(ttt~=tdw,tid) = -inf;
  ddd = sum((sss-repmat(secwfs,size(sss,1),1)).^2,2);
  [~,iddw] = min(ddd);
end
dwsec = seclist(iddw,:);

return
end



