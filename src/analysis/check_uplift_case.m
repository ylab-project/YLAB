function isuplifted_ilc = check_uplift_case( ...
  idnode2jf, idsup2node, issupfixed, ...
  dvec, ilc)
%check_uplift_case - 浮き上がり判定（単一ケース）
%
%   isuplifted_ilc = check_uplift_case( ...
%     idnode2jf, idsup2node, issupfixed, ...
%     dvec, ilc) は、
%   指定荷重ケースの支点浮き上がり状態を判定する。
%
%   入力引数:
%     idnode2jf - 節点→自由度変換 [nnode×6]
%     idsup2node - 支点→節点変換 [nsup×1]
%     issupfixed - 支点拘束 [nsup×6]
%     dvec - 変位ベクトル [ndf×nlc]
%     ilc - 対象荷重ケース番号（>=2）
%
%   出力引数:
%     isuplifted_ilc - 浮き上がり状態 [nsup×1]
%
%   備考:
%     - 判定: dvec(ilc) + dvec(1) > 1e-6

nsup = length(idsup2node);
isuplifted_ilc = false(nsup, 1);
for isj = 1:nsup
  ijsup = idsup2node(isj);
  ijf = idnode2jf(ijsup, 3);
  suz = dvec(ijf, ilc) + dvec(ijf, 1);
  isuplifted_ilc(isj) = ...
    issupfixed(isj, 3) & suz > 1.d-6;
end

return
end
