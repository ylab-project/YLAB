function slr = genslr(member_girder)
%GENSLR この関数の概要をここに記述
%   詳細説明をここに記述

slr.istarget = member_girder.slr_is_target;
slr.lb = member_girder.slr_lb;
slr.istarget(member_girder.section_type==PRM.RCRS,:) = [];
slr.lb(member_girder.section_type==PRM.RCRS,:) = [];
end

