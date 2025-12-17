function [nominal_property, idnominal_girder, idnominal_column, ...
  idnominal_brace, idnominal] = countup_nominal_property(com)

% 計算の準備
nominal_girder = com.nominal.girder;
nominal_column = com.nominal.column;
nominal_brace = com.nominal.brace;
girder = com.member.girder;
column = com.member.column;
brace = com.member.brace;
idmg2m = com.member.girder.idme;
idmc2m = com.member.column.idme;
idmb2m = com.member.brace.idme;

% 定数
nm = size(com.member.property,1);
nmg = size(girder,1);
nmc = size(column,1);
nmb = size(brace,1);
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
ntype = zeros(nnm,1);
idsub = zeros(nnm,3);
idmdf = zeros(nnm,13);
idme = zeros(nnm,maxcol);
id = 0;

% 梁部材
idng = zeros(nnm,1);
idnominal_girder = zeros(nnmg,1);
for ig=1:nnmg
  id = id+1;
  mtype(id) = PRM.GIRDER;
  idng(id) = ig;
  idsub(id,1:3) = nominal_girder.idsub(ig,1:3);
  ncol = nnz(nominal_girder.idmeg(ig,:));
  idmeg = nominal_girder.idmeg(ig,1:ncol);
  idme(id,1:ncol) = idmg2m(idmeg);
  idnominal_girder(ig) = id;

  % 名目部材種別
  if(ncol>1)
    ntype(id) = PRM.NOMINAL_MULTI_MEMBER;
  end
end

% 柱部材
idnc = zeros(nnm,1);
idnominal_column = zeros(nnmc,1);
for ic=1:nnmc
  id = id+1;
  mtype(id) = PRM.COLUMN;
  idnc(id) = ic;
  idsub(id,1:2) = nominal_column.idsub(ic,1:2);
  ncol = nnz(nominal_column.idmec(ic,:));
  idmec = nominal_column.idmec(ic,1:ncol);
  idme(id,1:ncol) = idmc2m(idmec);
  idnominal_column(ic) = id;

  % 名目部材種別
  if any(column.type(idmec)==PRM.COLUMN_FOR_BRACE1)
    ntype(id) = PRM.NOMINAL_MULTI_COLUMN_BRACE;
  elseif(ncol>1)
    ntype(id) = PRM.NOMINAL_MULTI_MEMBER;
  end

end

% ブレース部材
idb = zeros(nnm,1);
idnominal_brace = zeros(nbr,1);
for ib=1:nbr
  id = id+1;
  mtype(id) = PRM.BRACE;
  idb(id) = ib;
  idsub(id,1:2) = nominal_brace.idsub(ib,1:2);
  rows = nominal_brace.idmeb(ib,:);
  rows = rows(rows>0);
  idme(id,1:numel(rows)) = idmb2m(rows);
  idnominal_brace(ib) = id;

  if numel(rows)>1
    ntype(id) = PRM.NOMINAL_MULTI_MEMBER;
  end
end

% 逆引き
idnominal = zeros(nm,1);
for inm = 1:nnm
  for j=1:nnz(idme(inm,:))
    idnominal(idme(inm,j)) = inm;
  end
end

% Table作成
nominal_property = table(mtype, ntype, idme, idsub, idng, idnc, idb);
return
end
