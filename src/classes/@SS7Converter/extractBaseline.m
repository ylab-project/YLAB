function [baseline, story] = extractBaseline(obj)
% データブロックの取り出し
xydata = obj.dataBlock.get_data_block('構造スパン');
story_data = obj.dataBlock.get_data_block('構造階高');

% X軸名
xnames = [xydata(:,1); xydata(:,2)];
ismissingrow = false(1,length(xnames));
for i=1:length(xnames)
  if ismissing(xnames{i})
    ismissingrow(i) = true;
  end
end
xnames(ismissingrow) = [];
xnames = unique(xnames, 'stable');

% Y軸名
ynames = [xydata(:,8); xydata(:,9)];
ismissingrow = false(1,length(ynames));
for i=1:length(ynames)
  if ismissing(ynames{i})
    ismissingrow(i) = true;
  end
end
ynames(ismissingrow) = [];
ynames = unique(ynames, 'stable');

% 層名
story_names = story_data(:,1);

% 整理
baseline.x.name = xnames;
baseline.y.name = ynames;
story.name = story_names;
end
