function brace_unit_weight = calc_brb_unit_weight( ...
  section_brace, member_brace, secmgr, secdim)
%calc_brb_unit_weight - BRBのメーカー指定単位重量を取得
%
% BRB断面のrho（kg/m）を断面リストから取得し、
% N/mm単位に変換してブレース部材配列に展開する。
% BRB以外のブレースは0。
%
% Inputs:
%   section_brace - ブレース断面構造体
%   member_brace  - ブレース部材構造体
%   secmgr        - 断面マネージャ
%   secdim        - 断面寸法配列
%
% Outputs:
%   brace_unit_weight - ブレース単位重量 [nmeb x 1] N/mm

nmeb = length(member_brace.idsecb);
brace_unit_weight = zeros(nmeb, 1);
stype_b = section_brace.type;
idsecb = section_brace.idsec;
is_brb = stype_b == PRM.BRB;
if any(is_brb)
  rec = getListRecord( ...
    secmgr, secdim(idsecb(is_brb), :));
  % kg/m → N/mm
  uw_brb = rec.rho * PRM.GRAVITY / 1000;
  % 断面→部材への展開
  uw_sec = zeros(size(stype_b));
  uw_sec(is_brb) = uw_brb;
  brace_unit_weight = uw_sec(member_brace.idsecb);
end

return
end
