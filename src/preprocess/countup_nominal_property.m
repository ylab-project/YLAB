function [nominal_property, idnominal_girder, idnominal_column, ...
  idnominal_brace, idnominal] = countup_nominal_property(com)
%countup_nominal_property - 名目部材と解析要素の対応を組み立てる
%
%   [nominal_property, idnominal_girder, idnominal_column, ...
%     idnominal_brace, idnominal] = countup_nominal_property(com) は、
%   梁・柱・ブレースの構成順序を保って名目部材番号を割り当てる。
%   名目部材から解析要素への対応と各部材からの逆引きを返す。
%
%   入力引数:
%     com - 解析要素と種別ごとの名目部材を保持する共通情報
%
%   出力引数:
%     nominal_property - 部材種別と構成要素の対応表
%     idnominal_girder  - 名目梁から名目部材への対応 [nnmg×1]
%     idnominal_column  - 名目柱から名目部材への対応 [nnmc×1]
%     idnominal_brace   - 名目ブレースから名目部材への対応 [nbr×1]
%     idnominal         - 全解析要素から名目部材への対応 [nm×1]

% 計算の準備
nominal_girder = com.nominal.girder;
nominal_column = com.nominal.column;
nominal_brace = com.nominal.brace;
idmg2m = com.member.girder.idme;
idmc2m = com.member.column.idme;
idmb2m = com.member.brace.idme;

% 定数
nm = com.nme;
nnmg = size(nominal_girder,1);
nnmc = size(nominal_column,1);
nbr = size(nominal_brace,1);
nnm = nnmg+nnmc+nbr;
maxcol = max(max(nominal_girder.idsub,[],'all'), ...
  max(nominal_column.idsub,[],'all'));
if nbr>0
  maxcol = max(maxcol, size(nominal_brace.idmeb,2));
end

% 一本部材のカウント
mtype = zeros(nnm,1);
idme = zeros(nnm,maxcol);
id = 0;

% 梁部材
idnominal_girder = zeros(nnmg,1);
for ig=1:nnmg
  id = id+1;
  mtype(id) = PRM.GIRDER;
  ncol = nnz(nominal_girder.idmeg(ig,:));
  idmeg = nominal_girder.idmeg(ig,1:ncol);
  idme(id,1:ncol) = idmg2m(idmeg);
  idnominal_girder(ig) = id;
end

% 柱部材
idnominal_column = zeros(nnmc,1);
for ic=1:nnmc
  id = id+1;
  mtype(id) = PRM.COLUMN;
  ncol = nnz(nominal_column.idmec(ic,:));
  idmec = nominal_column.idmec(ic,1:ncol);
  idme(id,1:ncol) = idmc2m(idmec);
  idnominal_column(ic) = id;
end

% ブレース部材
idnominal_brace = zeros(nbr,1);
for ib=1:nbr
  id = id+1;
  mtype(id) = PRM.BRACE;
  rows = nominal_brace.idmeb(ib,:);
  rows = rows(rows>0);
  idme(id,1:numel(rows)) = idmb2m(rows);
  idnominal_brace(ib) = id;
end

% 逆引き
idnominal = zeros(nm,1);
for inm = 1:nnm
  for j=1:nnz(idme(inm,:))
    idnominal(idme(inm,j)) = inm;
  end
end

% 結果の保存
nominal_property = table(mtype, idme);

return
end
