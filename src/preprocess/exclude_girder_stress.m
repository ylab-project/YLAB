function [isvar, girder_rank] = exclude_girder_stress(com)
%EXCLUDE_GIRDER_STRESS この関数の概要をここに記述
%   詳細説明をここに記述

% 定数
nsg = com.nsecg;

% 計算の準備
design_variable = com.design.variable;
section_girder = com.section.girder;
is_girder_stress = com.exclusion.is_section_girder_allowable_stress;

% 検定除外断面の処理
isvar = design_variable.isvar;
girder_rank = section_girder.rank;
for ig=1:nsg
  if (~is_girder_stress(ig))

    % 設計変数の固定
    idvar = section_girder.idvar(ig,:);
    ncol = nnz(idvar);
    isvar(idvar(1:ncol)) = false;

    % 幅厚比の除外 -> ランクFD
    girder_rank(ig) = PRM.GIRDER_RANK_FD;
  end
end

return
end

