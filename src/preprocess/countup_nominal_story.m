function [nominal_story, idstory2nominal] = countup_nominal_story(com)
% 共通定数
nstory = com.nstory;
story = com.story;

% 名目層を数え上げる
nnstory = sum(story.isdummy==false);
id = 0;
name = cell(nnstory,1);
idstory = zeros(nnstory,1);
for ist=1:nstory
  if story.isdummy(ist)
    continue
  end
  id = id+1;
  idstory(id) = ist;
  name{id} = story.name{ist};
end

% ID変換用:層番号->名目層番号
idstory2nominal = zeros(nstory,1);
idstory2nominal(idstory) = 1:nnstory;
for ist=1:nstory
  if story.isdummy(ist)
    idstory2nominal(ist) = idstory2nominal(story.id_dependent_story(ist));
  end
end

% 結果の整理
nominal_story = table(name, idstory);
return
end
