function is_joint_bearing_strength = exclude_joint_bearing_strength(com)
%EXCLUDE_GIRDER_STRESS 保有耐力接合（仕口）の除外指定
%   詳細説明をここに記述

% H形部材の端部結合条件の判定
gjoint = com.member.girder.joint;
gtype = com.member.girder.section_type;
gnode = [com.member.girder.idnode1 com.member.girder.idnode2];
wfsnode = gnode(gtype==PRM.WFS,1:2);
wfsjoint = gjoint(gtype==PRM.WFS,1:2);
cnode = sort([com.member.column.idnode1; com.member.column.idnode2]);

% 剛接合を対象
is_joint_bearing_strength = (wfsjoint==PRM.FIX);

% 柱に接合しない接合部は除外
nwfs = sum(gtype==PRM.WFS);

for iwfs=1:nwfs
  for ij=1:2
    if ~is_joint_bearing_strength(iwfs,ij)
      continue
    end
    if all(wfsnode(iwfs,ij)~=cnode)
      is_joint_bearing_strength(iwfs,ij) = false;
    end
  end
end

return
end

