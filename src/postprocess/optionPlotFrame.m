classdef optionPlotFrame
  %PLOT_FRAME_OPTION_CLASS このクラスの概要をここに記述
  %   詳細説明をここに記述
  
  properties
    is_visible(1,1) logical = false;
    % is_visible(1,1) logical = true;
    is_plot_node_number(1,1) logical = false;
    is_plot_section_name(1,1) logical = false;
    is_plot_member_number(1,1) logical = false;
    is_plot_design_varable_number(1,1) logical = false;
    is_plot_proportional_cross_sectional_area(1,1) logical  = false
    is_plot_dimension_line(1,1) logical = false;
    %
    mode char {mustBeMember(mode,{'PLAN','XFRAME','YFRAME', '3D'})} = 'PLAN'
    line_width (1,1) double = 1;
    cross_sectional_area (1,:) double
  end
  
  methods
    function obj = optionPlotFrame()
    end
    
  end
end

