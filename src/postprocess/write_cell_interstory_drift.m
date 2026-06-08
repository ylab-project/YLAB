function [head, body] = write_cell_interstory_drift(...
  com, result, options, icase)

% 共通定数
nfl = com.nfl;
nph = options.num_penthouse_floor;

% 共通配列
floor_name = com.floor.name;
angle = result.drift.angle;
idcolumn = result.drift.idcolumn;
coord_name = com.member.column.coord_name;
drift_height = result.drift.height;
drift_delta_x = result.drift.delta_x;
drift_delta_y = result.drift.delta_y;

%% 層間変形角 ---
head = cell(2,9);
body = cell(nfl,9);
if isempty(angle)
  return
end

%% ヘッダ 
head(1,:) = {'階', 'X軸', 'Y軸', '柱構造', '階高', 'δx', 'δy', 'δ', ...
  '最大層間変形角'};
head(2,5:8) = {'mm', 'mm', 'mm', 'mm'};

%% 層間変形角の書き出し
for j=1:nfl-nph
  jfl = nfl-j+1-nph;
  ic = idcolumn(jfl,icase);
  fh = drift_height(jfl, icase);
  body{j,1} = floor_name{jfl};
  body{j,2} = coord_name{ic,1};
  body{j,3} = coord_name{ic,2};
  body{j,4} = 'S';
  body{j,5} = fh;
  body{j,6} = drift_delta_x(jfl, icase);
  body{j,7} = drift_delta_y(jfl, icase);
  body{j,8} = angle(jfl,icase)*fh;
  body{j,9} = sprintf('1/%6.0f', 1/abs(angle(jfl,icase)));
end
return
end
