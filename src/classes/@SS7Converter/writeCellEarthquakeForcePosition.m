function [position, header] = writeCellEarthquakeForcePosition(obj)
%writeCellEarthquakeForcePosition - 地震力作用位置ブロックを生成

eq = obj.earthquake;
n = numel(eq.idstory);
position = cell(n, 8);

header = {
  '%階', '剛床', '指定方法', 'X軸', 'Y軸', 'X座標', 'Y座標'; ...
  '%', '', '', '', '', 'mm', 'mm'};
for i=1:n
  position{i, 1} = eq.floor_name{i};
  position{i, 2} = '主剛床';
  position{i, 3} = '絶対座標';
  position{i, 4} = '';
  position{i, 5} = '';
  position{i, 6} = eq.gx(i);
  position{i, 7} = eq.gy(i);
end

return
end
