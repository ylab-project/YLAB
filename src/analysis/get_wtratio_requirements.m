function [grank, crank, is_wtcon, idg, idc] = ...
  get_wtratio_requirements(com, options)
%get_wtratio_requirements - 幅厚比の実効要求種別と評価対象を得る
%
%   [grank, crank, is_wtcon, idg, idc] =
%     get_wtratio_requirements(com, options) は、
%   断面別の要求と群種別によるFC下限を合わせる。
%
%   入力引数:
%     com     - 断面・部材・階の対応と要求種別
%     options - 共通オプション
%
%   出力引数:
%     grank, crank - 梁・柱の実効要求種別 [nsec×1]
%     is_wtcon     - 幅厚比を評価する断面 [nsec×1]
%     idg, idc     - 幅厚比対象の代表断面行番号 [ngwt×1], [ncwt×1]

grank = zeros(com.nsec, 1);
grank(com.section.girder.idsec) = com.section.girder.rank;
crank = zeros(com.nsec, 1);
crank(com.section.column.idsec) = com.section.column.rank;
is_group = false(com.nsec, 1);
if options.coptions.consider_group_rank
  idfl = find(com.floor.rank_group > 0);
  mp = com.member.property;
  idme = find(any(ismember(mp.idfloor, idfl), 2) & ...
    ismember(mp.section_type, [PRM.WFS PRM.HSS PRM.CWFS PRM.CWFSI]));
  idme = get_group_rank_members(com, idme);
  idsrep2s = com.section.representative.idsec;
  ids = idsrep2s(com.section.property.idsrep(mp.idsec(idme)));
  is_group(ids) = true;
end
grank(is_group) = min(grank(is_group), PRM.MEMBER_RANK_FC);
crank(is_group) = min(crank(is_group), PRM.MEMBER_RANK_FC);
is_wtcon = is_group | options.coptions.consider_section_wt_ratio;
if nargout >= 4
  rep = com.section.representative;
  idg = find(rep.section_type == PRM.WFS & is_wtcon(rep.idsec));
  idc = find(ismember(rep.section_type, [PRM.HSS PRM.CWFS PRM.CWFSI]) & ...
    is_wtcon(rep.idsec));
end

return
end
