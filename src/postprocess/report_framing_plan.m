function section = report_framing_plan(rm, com)
%REPORT_FRAMING_PLAN 床伏図
%   詳細説明をここに記述

import mlreportgen.report.*
import mlreportgen.dom.*

% 共通定数
nblz = com.nblz;
nstory = com.nstory;
story = com.story;

% 断面符号
section = Section('略伏図');
para = Paragraph();
para.Style = [para.Style ...
  {OuterMargin("0pt","0pt","0pt","0pt") KeepWithNext(true)}];
append(section, para);
isss = 1:nstory;
popts = optionPlotFrame;
for idz = 1:nblz
  % popts.is_visible = true;
  popts.is_plot_section_name = true;
  popts.is_plot_dimension_line = true;
  fig = plot_frame_model(com, popts, idz);
  idstory = isss(story.idz==idz);
  idfloor = story.idfloor(idstory);
  if idfloor>0
    rm.appendFigure(section, fig, sprintf('%s層(%s階)\n', ...
      story.name{idstory}, story.floor_name{idstory}));
  else
    rm.appendFigure(section, fig, sprintf('%s層\n', story.name{idstory}));
  end
end
append(section, PageBreak());
fprintf('.');

% 節点番号
% section = Section(); section.Title = '節点番号';
para = Paragraph('節点番号');
append(section, para);
popts = optionPlotFrame();
for idz = 1:nblz
  popts.is_plot_node_number = true;
  fig = plot_frame_model(com, popts, idz);
  idstory = isss(story.idz==idz);
  idfloor = story.idfloor(idstory);
  if idfloor>0
    rm.appendFigure(section, fig, sprintf('%s層(%s階)\n', ...
      story.name{idstory}, story.floor_name{idstory}));
  else
    rm.appendFigure(section, fig, sprintf('%s層\n', story.name{idstory}));
  end
end
append(section, PageBreak());
fprintf('.');

% 部材番号
% section = Section(); section.Title = '部材番号';
para = Paragraph('部材番号');
append(section, para);
popts = optionPlotFrame();
for idz = 1:nblz
  popts.is_plot_member_number = true;
  fig = plot_frame_model(com, popts, idz);
  idstory = isss(story.idz==idz);
  idfloor = story.idfloor(idstory);
  if idfloor>0
    rm.appendFigure(section, fig, sprintf('%s層(%s階)\n', ...
      story.name{idstory}, story.floor_name{idstory}));
  else
    rm.appendFigure(section, fig, sprintf('%s層\n', story.name{idstory}));
  end
end
append(section, PageBreak());
fprintf('.');

% 設計変数番号
% section = Section(); section.Title = '設計変数番号';
para = Paragraph('設計変数番号');
append(section, para);
popts = optionPlotFrame();
for idz = 1:nblz
  popts.is_plot_design_varable_number = true;
  fig = plot_frame_model(com, popts, idz);
  idstory = isss(story.idz==idz);
  idfloor = story.idfloor(idstory);
  if idfloor>0
    rm.appendFigure(section, fig, sprintf('%s層(%s階)\n', ...
      story.name{idstory}, story.floor_name{idstory}));
  else
    rm.appendFigure(section, fig, sprintf('%s層\n', story.name{idstory}));
  end
end
append(section, PageBreak());
fprintf('.');

end

