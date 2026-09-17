function dfn0 = calc_nominal_design_force(df0, nominal_property, member)
%calc_nominal_design_force - 名目部材の端部設計応力を集約する
%
%   dfn0 = calc_nominal_design_force(df0, nominal_property, member) は、
%   構成要素の両端から名目部材の設計応力を取得する。全名目部材で
%   i端は先頭要素、j端は末尾要素から採る。ブレース分割柱の
%   柱脚軸力・せん断力は、ブレース取り付き位置＝梁面位置から採る。
%   曲げは端部応力採用位置のオプションに従って補正した値を使う。
%
%   入力引数:
%     df0              - 位置補正済みの設計応力 [nme×12×nlc]
%                        各端はN・Qの3成分、Mの3成分の順
%     nominal_property - 名目部材と構成要素の対応
%     member           - 柱種別と部材・名目部材の対応
%
%   出力引数:
%     dfn0 - 名目部材の設計応力 [nnm×12×nlc]（df0と同じ符号・単位）

% 名目部材の構成要素、柱から部材への対応、柱種別を取り出す
nnm = size(nominal_property.idme,1);
idnm2m = nominal_property.idme;
idmc2m = member.column.idme;
ctype = member.column.type;

% 名目部材ごとに、先頭の要素からi端(成分1-6)、
% 末尾の要素からj端(成分7-12)の設計応力を取得する。
% 単一要素の部材では先頭と末尾が同じ要素になる。
% nsubは構成要素数、imtは末尾要素の部材番号
nsub = sum(idnm2m > 0, 2);
imt = idnm2m(sub2ind(size(idnm2m), (1:nnm).', nsub));
dfn0 = df0(idnm2m(:,1),:,:);
dfn0(:,7:12,:) = df0(imt,7:12,:);

% ブレース分割柱の柱脚N・Q(成分1-3)は、梁面位置の
% COLUMN_FOR_BRACE_BODYの柱脚から採る。柱頭N・Qと両端Mは、
% 上で取得した値を使う。Mはcalc_design_forceで補正済み。
idmec = find(ctype == PRM.COLUMN_FOR_BRACE_BODY);
inm = member.property.idnominal(idmc2m(idmec));
dfn0(inm,1:3,:) = df0(idmc2m(idmec),1:3,:);

return
end
