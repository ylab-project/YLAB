function section = report_framing_elevation(rm, com, mode)
%REPORT_FRAMING_ELEVATION 軸組図
%   詳細説明をここに記述

import mlreportgen.report.*
import mlreportgen.dom.*

% 共通定数
switch mode
  case 'XFRAME'
    nbl = com.nbly;
    label = com.baseline.y.name;
    section = Section('略軸組図：X方向');
  case 'YFRAME'
    nbl = com.nblx;
    label = com.baseline.x.name;
    section = Section('略軸組図：Y方向');
end
fmt = '%sフレーム\n';

% 断面符号
para = Paragraph();
para.Style = [para.Style ...
  {OuterMargin("0pt","0pt","0pt","0pt") KeepWithNext(true)}];
append(section, para);

ibbb = 1:nbl;
popts = optionPlotFrame;
for id = 1:nbl
  popts.mode = mode;
  % popts.is_visible = true;
  popts.is_plot_section_name = true;
  popts.is_plot_dimension_line = true;
  fig = plot_frame_model(com, popts, id);
  rm.appendFigure(section, fig, sprintf(fmt,label{id}));
end
% append(sec, PageBreak());
% append(section, sec); 

% % 節点番号
% sec = Section(); sec.Title = '節点番号';
% para = Paragraph();
% para.Style = [para.Style ...
%   {OuterMargin("0pt","0pt","16pt","0pt") KeepWithNext(true)}];
% append(robj, para);
% popts = optionPlotFrame;
% for id = 1:nbl
%   popts.mode = mode;
%   popts.is_plot_node_number = true;
%   % popts.is_plot_dimension_line = true;
%   fig = plot_frame_model(com, popts, id);
%   rm.appendFigure(sec, fig, sprintf(fmt,id));
% end
% % append(sec, PageBreak());
% append(robj, sec); 

% % 部材番号
% sec = Section(); sec.Title = '部材番号';
% popts = optionPlotFrame;
% for id = 1:nbl
%   popts.mode = mode;
%   popts.is_plot_member_number = true;
%   fig = plot_frame_model(com, popts, id);
%   rm.appendFigure(sec, fig, sprintf(fmt,id));
% end
% append(sec, PageBreak());
% append(robj, sec); 

% % 設計変数番号
% sec = Section(); sec.Title = '設計変数番号';
% popts = optionPlotFrame;
% for id = 1:nbl
%   popts.mode = mode;
%   popts.is_plot_design_varable_number = true;
%   fig = plot_frame_model(com, popts, id);
%   rm.appendFigure(sec, fig, sprintf(fmt,id));  
% end
% append(sec, PageBreak());
% append(robj, sec); 

end

