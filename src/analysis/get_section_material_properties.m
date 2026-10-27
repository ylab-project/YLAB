function [Fs, isSNsec, idsec2mat] = ...
  get_section_material_properties(secdim, com)
%get_section_material_properties - 写像済み断面の材料特性を得る
%
%   [Fs, isSNsec, idsec2mat] =
%     get_section_material_properties(secdim, com) は、
%   候補が選んだ断面リストと既定材料から各断面の材料を取得する。
%
%   入力引数:
%     secdim - 写像済みの全断面寸法 [nsec×7] (mm)
%     com    - 断面と材料の対応
%
%   出力引数:
%     Fs        - 断面の材料F値 [nsec×1] (N/mm²)
%     isSNsec   - SN材の断面 [nsec×1]
%     idsec2mat - 断面から材料番号への対応 [nsec×1]

[Fs, idsec2mat] = com.secmgr.extractSectionMaterialF( ...
  secdim, com.material.F);
isSNsec = false(numel(idsec2mat), 1);
isSNsec(idsec2mat > 0) = com.material.isSN(idsec2mat(idsec2mat > 0));

return
end