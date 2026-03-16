function slr = genslr(member_girder)
%genslr - 保有耐力横補剛チェック用の構造体を生成

slr.istarget = member_girder.slr_is_target;
slr.lb = member_girder.slr_lb;
slr.lbmax = member_girder.slr_lbmax;
isrc = member_girder.section_type==PRM.RCRS;
slr.istarget(isrc,:) = [];
slr.lb(isrc,:) = [];
slr.lbmax(isrc) = [];
end
