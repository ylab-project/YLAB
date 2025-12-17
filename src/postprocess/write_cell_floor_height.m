function [fhhead, fhbody] = write_cell_floor_height(...
  xvar, com, result, options)

% 共通配列
story = result.story;
floor = result.floor;

% 共通定数
nstory = com.nstory;
nfloor = size(floor,1);

% ヘッダ
fhhead = cell(3, 12);
fhhead(1,1:12) = {'層','階','構造','階高','構造階高' ...
  ,'階高と','梁のレベル','調整','二重ｽﾗﾌﾞ','床面積' ...
  ,'ダミー層','従属層'};
fhhead(2,6:8) = {'梁心の差','押さえ','レベル'};
fhhead(3,4:10) = {'mm','mm','mm','','mm','','m2'};

% ボディ
fhbody = cell(nstory, 12);
irow = 0;
ifff = 1:nfloor;
for ist = nstory:-1:1
  irow = irow+1;
  fhbody{irow,1} = story.name{ist};
  ifl = ifff(floor.idstory==ist);
  if ~isempty(ifl)
    fhbody{irow,2} = floor.name{ifl};
    fhbody{irow,4} = sprintf('%.0f',floor.standard_height(ifl));
    fhbody{irow,5} = sprintf('%.0f',floor.height(ifl));
  end
  fhbody{irow,6} = sprintf('%.0f',-story.delta_height(ist));
end

return
end

