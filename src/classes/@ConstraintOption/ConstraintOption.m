classdef ConstraintOption
  properties
    % 制約条件フラグ
    consider_stress_ratio (1,1) logical = true
    consider_inter_story (1,1) logical = true
    consider_girder_deflection (1,1) logical = true
    consider_section_wt_ratio (1,1) logical = true
    consider_slenderness_ratio (1,1) logical = true
    consider_joint_bearing_strength (1,1) logical = true
    consider_joint_strength_ratio (1,1) logical = true
    consider_standard_section_list (1,1) logical = true
    consider_girder_height_gap_var (1,1) logical = true
    consider_girder_height_gap_section (1,1) logical = false
    consider_girder_height_smooth_var (1,1) logical = false
    consider_column_diameter_gap (1,1) logical = true

    % 余裕率
    alfa_stress_ratio (1,1) double = 0.05;
    alfa_inter_story (1,1) double = 0.05;
    alfa_girder_deflection (1,1) double = 0;
    alfa_section_wt_ratio (1,1) double = 0;
    alfa_slenderness_ratio (1,1) double = 0;
    alfa_joint_bearing_strength (1,1) double = 0;
    alfa_joint_strength_ratio (1,1) double = 0;
    alfa_standard_section_list (1,1) double = 0;
    alfa_girder_height_gap_var (1,1) double = 0;
    alfa_girder_height_gap_section (1,1) double = 0;
    alfa_girder_height_smooth_var (1,1) double = 1;
    alfa_column_diamter_gap (1,1) double = 0;

    % その他
    reqHgap (1,1) double = 0;
  
    % その他
    rank_column(1,1) double = PRM.COLUMN_RANK_FB;
    rank_girder(1,1) double = PRM.COLUMN_RANK_FA;
    % consider_thickness = false
    % consider_fix_group = false
    % consider_wt_ratio_L = true
    % consider_gwidth = false
  end
  methods
    function coptions = setFromDataBlock(coptions, data)
      for i=1:size(data,1)
        if ismissing(data{i,1})
          continue
        end
        alfa = data{i,3};
        switch data{i,1}
          case '許容応力度比'
            coptions.consider_stress_ratio = (data{i,2}=='Y');
            if ~ismissing(alfa)
              coptions.alfa_stress_ratio = alfa;
            end
          case '層間変形角'
            coptions.consider_inter_story = (data{i,2}=='Y');
            if ~ismissing(alfa)
              coptions.alfa_inter_story = alfa;
            end
          case '梁たわみ'
            coptions.consider_girder_deflection = (data{i,2}=='Y');
            if ~ismissing(alfa)
              coptions.alfa_girder_deflection = alfa;
            end
          case '幅厚比'
            coptions.consider_section_wt_ratio = (data{i,2}=='Y');
            if ~ismissing(alfa)
              coptions.alfa_section_wt_ratio = alfa;
            end
          case {'細長比', '保有耐力横補剛'}
            coptions.consider_slenderness_ratio = (data{i,2}=='Y');
            if ~ismissing(alfa)
              coptions.alfa_slenderness_ratio = alfa;
            end
          case {'保有耐力接合（仕口）', '保有耐力接合(仕口)'}
            coptions.consider_joint_bearing_strength = (data{i,2}=='Y');
            if ~ismissing(alfa)
              coptions.alfa_joint_bearing_strength = alfa;
            end
          case '柱梁耐力比'
            coptions.consider_joint_strength_ratio = (data{i,2}=='Y');
            if ~ismissing(alfa)
              coptions.alfa_joint_strength_ratio = alfa;
            end
          case '梁段差'
            coptions.consider_girder_height_gap_var = (data{i,2}=='Y');
            if ~ismissing(alfa)
              % coptions.alfa_girder_height_gap_var = 0;
              coptions.reqHgap = alfa;
            end
          case '梁段差実寸'
            coptions.consider_girder_height_gap_section = (data{i,2}=='Y');
            if ~ismissing(alfa)
              % coptions.alfa_girder_height_gap_section = 0;
              coptions.reqHgap = alfa;
            end
          case '柱外径上下階'
            coptions.consider_column_diameter_gap = (data{i,2}=='Y');
            if ~ismissing(alfa)
              coptions.alfa_column_diamter_gap = alfa;
            end
          case '梁せい分布平滑化'
            coptions.consider_girder_height_smooth_var = (data{i,2}=='Y');
            if ~ismissing(alfa)
              coptions.alfa_girder_height_smooth_var = alfa;
            end
          case '柱部材種別'
            switch data{i,2}
              case 'FA'
                coptions.rank_column = PRM.COLUMN_RANK_FA;
              case 'FB'
                coptions.rank_column = PRM.COLUMN_RANK_FB;
              case 'FC'
                coptions.rank_column = PRM.COLUMN_RANK_FC;
              case 'FD'
                coptions.rank_column = PRM.COLUMN_RANK_FD;
            end
          case '梁部材種別'
            switch data{i,2}
              case 'FA'
                coptions.rank_girder = PRM.GIRDER_RANK_FA;
              case 'FB'
                coptions.rank_girder = PRM.GIRDER_RANK_FB;
              case 'FC'
                coptions.rank_girder = PRM.GIRDER_RANK_FC;
              case 'FD'
                coptions.rank_girder = PRM.GIRDER_RANK_FD;
            end
        end
      end
    end
  end
end

