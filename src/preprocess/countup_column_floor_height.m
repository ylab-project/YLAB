function floor_height = countup_column_floor_height(com)
% 共通定数
nmc = com.nmec;
nfl = com.nfl;
% nnode = com.nnode;
% nstory = com.nstory;

% 共通配列
% column = com.member.column;
idc2fl = com.story.idfloor(com.member.column.idstory);
floor_height = com.floor.standard_height(idc2fl);
floor_height = [floor_height floor_height];
floor_standard_height = com.floor.standard_height;
idmc2n1 = com.member.column.idnode1;
idmc2n2 = com.member.column.idnode2;
idn2z = com.node.idz;
dz = com.node.dz;
glv = com.member.girder.level;
idgx1 = com.member.column.idmeg_face1x;
idgx2 = com.member.column.idmeg_face2x;
idgy1 = com.member.column.idmeg_face1y;
idgy2 = com.member.column.idmeg_face2y;

% 各柱位置での階高計算
for ic = 1:nmc
  % 節点上下移動分
  in1 = idmc2n1(ic); ifl1 = idn2z(in1);
  in2 = idmc2n2(ic); ifl2 = idn2z(in2)-1;

  if ifl2>nfl
    % TODO: とりあえず
    continue
  end

  % floor_height(ic,:) = floor_height(ic,:)-dz(in1)+dz(in2);
  floor_height(ic,:) = sum(floor_standard_height(ifl1:ifl2)) ...
    -dz(in1)+dz(in2);

  % 梁のレベル調整分
  for in=1:2
    for ixy=1:2     
      if in==1&&ixy==1
        idg = idgx1(ic,:);
      elseif in==1&&ixy==2
        idg = idgy1(ic,:);
      elseif in==2&&ixy==1
        idg = idgx2(ic,:);
      elseif in==2&&ixy==2
        idg = idgy2(ic,:);
      end

      % 該当部材なしの場合スキップ
      idg = idg(idg>0);
      if isempty(idg)
        continue
      end

      % 上下階の処理
      if in==1
        glv_ = mean(-glv(idg));
      else
        glv_ = mean(glv(idg));
      end
      floor_height(ic,ixy) = floor_height(ic,ixy)+glv_;
    end
  end
end
return
end

