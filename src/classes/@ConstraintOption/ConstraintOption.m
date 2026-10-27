classdef ConstraintOption
  properties
    % 制約条件フラグ
    consider_stress_ratio (1,1) logical = true
    consider_inter_story (1,1) logical = true
    consider_girder_deflection (1,1) logical = true
    consider_section_wt_ratio (1,1) logical = true
    consider_group_rank (1,1) logical = false
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
    alfa_group_rank (1,1) double = 0;
    alfa_slenderness_ratio (1,1) double = 0;
    alfa_joint_bearing_strength (1,1) double = 0;
    alfa_joint_strength_ratio (1,1) double = 0;
    alfa_standard_section_list (1,1) double = 0;
    alfa_girder_height_gap_var (1,1) double = 0;
    alfa_girder_height_gap_section (1,1) double = 0;
    alfa_column_diamter_gap (1,1) double = 0;

    % その他
    reqHgap (1,1) double = 0;
  
    % その他
    rank_group(1,1) double = PRM.GROUP_RANK_A;
    rank_column(1,1) double = PRM.MEMBER_RANK_FB;
    rank_girder(1,1) double = PRM.MEMBER_RANK_FA;
    % consider_thickness = false
    % consider_fix_group = false
    % consider_wt_ratio_L = true
    % consider_gwidth = false
  end
  methods
    function coptions = setFromDataBlock(coptions, data)
      %setFromDataBlock - 制約条件ブロックの指定を計算条件へ反映する
      %
      %   coptions = setFromDataBlock(coptions, data) は、指定された
      %   制約の有無、余裕率、部材種別と部材群種別を設定する。
      %
      %   入力引数:
      %     coptions - 反映前の制約条件
      %     data - 読込済み制約条件ブロック [n×m] cell（m>=2）
      %
      %   出力引数:
      %     coptions - 入力の指定を反映した制約条件

      % 余裕率を全行省略した2列CSVにも対応する
      data(:, end+1:3) = {missing};
      idrow = find(strcmp(data(:, 1), '部材群種別'));
      if numel(idrow) > 1
        throw_err('Input', 'DuplicateGroupRankInput', ...
          '制約条件', idrow(2), '部材群種別');
      end
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
          case '部材群種別'
            rank = find(strcmp(PRM.GROUP_RANK_NAME( ...
              PRM.GROUP_RANK_A:PRM.GROUP_RANK_C), data{i,2}));
            coptions.consider_group_rank = ~isempty(rank);
            if coptions.consider_group_rank
              coptions.rank_group = rank;
            elseif ~strcmp(data{i,2}, 'N')
              throw_err('Input', 'InvalidGroupRankSwitch', '制約条件', i);
            end
            [alfa, valid] = normalize_numeric_cell(alfa);
            if ~valid || alfa < 0 || alfa >= 1
              throw_err('Input', 'InvalidGroupRankMargin', '制約条件', i);
            end
            if ~isnan(alfa)
              coptions.alfa_group_rank = alfa;
            end
          case '柱梁部材群種別'
            throw_err('Input', 'ObsoleteGroupRankOption', '制約条件', i);
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
              throw_err('Input', 'ObsoleteGirderHeightSmoothOption', ...
                '制約条件', i);
            end
          case '柱部材種別'
            idx = find(strcmp(PRM.MEMBER_RANK_NAME, data{i,2}), 1);
            if ~isempty(idx)
              coptions.rank_column = idx;
            end
          case '梁部材種別'
            idx = find(strcmp(PRM.MEMBER_RANK_NAME, data{i,2}), 1);
            if ~isempty(idx)
              coptions.rank_girder = idx;
            end
        end
      end

      return
    end
  end
end
