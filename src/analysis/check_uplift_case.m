function isuplifted_ilc = check_uplift_case(idnode2jf, ...
  idsup2node, issupfixed, sks, dvec, ilc)
%check_uplift_case - 浮き上がり判定（単一ケース）
%
%   isuplifted_ilc = check_uplift_case(idnode2jf, ...
%     idsup2node, issupfixed, sks, dvec, ilc) は、
%   指定荷重ケースの支点浮き上がり状態を判定する。
%
%   入力引数:
%     idnode2jf - 節点→自由度変換 [nnode×6]
%     idsup2node - 支点→節点変換 [nsup×1]
%     issupfixed - 支点拘束 [nsup×6]
%     sks - 支点ばね対角値 [6*nsup×nlc]
%     dvec - 変位ベクトル [ndf×nlc]
%     ilc - 対象荷重ケース番号（>=2）
%
%   出力引数:
%     isuplifted_ilc - 浮き上がり状態 [nsup×1]
%
%   備考:
%     - SS7計算編 5.6(3) は（浮き上がり耐力＋鉛直荷重時軸力）と
%       付加軸力の相殺で判定する。YLAB は耐力入力を持たないため
%       耐力を 0 とし、PRM.UPLIFT_FORCE_TOL は数値許容差に用いる。
%     - 長期と当該ケースでばね値が異なるため、変位の和ではなく
%       それぞれの剛性を掛けたばね力の和で判定する。

nsup = length(idsup2node);
ijf = idnode2jf(idsup2node, 3);
ir = (0:nsup-1)' * 6 + 3;
% 支点鉛直ばね力（上向き正）
fz = sks(ir, ilc) .* dvec(ijf, ilc) + sks(ir, 1) .* dvec(ijf, 1);
isuplifted_ilc = issupfixed(:, 3) & fz > PRM.UPLIFT_FORCE_TOL;

return
end
