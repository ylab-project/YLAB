function options = setFromDataBlock(options, data)
%setFromDataBlock - データブロックからCommonOptionのフィールドを設定する
%
%   options = setFromDataBlock(options, data) は、入力CSVから読み取った
%   データブロック data の各行のキー（1列目）に応じて、options の
%   対応するフィールドを更新して返す。
%
%   入力引数:
%     options - CommonOption オブジェクト
%     data    - データブロック (cell配列、1列目:項目名、2列目以降:値)
%
%   出力引数:
%     options - 更新された CommonOption オブジェクト

% --- 基本事項の設定 ---
for i=1:size(data,1)
  if ismissing(data{i,1})
    continue
  end
  switch data{i,1}
    case '地下階数'
      options.num_basement_floor = data{i,2};
    case 'PH階数'
      options.num_penthouse_floor = data{i,2};
    case 'GLから1階床までの高さ'
      if ~ismissing(data{i,2})
        options.gl_to_first_floor_height = data{i,2};
      end
  end
end

% --- 構造計算用条件の設定 ---
for i=1:size(data,1)
  if ismissing(data{i,1})
    continue
  end
  switch data{i,1}
    case '構造階高の自動計算'
      options.do_autoupdate_floor_height = (data{i,2}=='Y');
    case '自重の自動計算'
      % options.consider_allowable_stress_at_face = (data{i,2}=='Y');
      options.consider_self_weight = (data{i,2}=='Y');
      p1 = data{i,3};
      if ~ismissing(p1)
        options.self_weight_extra_factor_girder	= p1;
      end
      p2 = data{i,4};
      if ~ismissing(p2)
        options.self_weight_extra_factor_column	= p2;
      end
    case '仕上荷重の考慮'
      options.consider_finishing_material = (data{i,2}=='Y');
    case '仕上S柱'
      p = data{i,2};
      if ~ismissing(p)
        options.finishing_material_s_column	= p;
      end
    case '仕上S梁'
      p = data{i,2};
      if ~ismissing(p)
        options.finishing_material_s_girder	= p;
      end
    case '仕上RC梁'
      p = data{i,2};
      if ~ismissing(p)
        options.finishing_material_rc_girder = p;
      end
    case '仕上RC柱'
      p = data{i,2};
      if ~ismissing(p)
        options.finishing_material_rc_column = p;
      end
    case '柱・梁せん断変形の考慮'
      options.consider_shear_deformation = (data{i,2}=='Y');
    case '梁水平面内変形の考慮'
      p = data{i,2};
      if ~ismissing(p)
        if ~ismember(p, [PRM.GIRDER_HSTIFF_ZERO, ...
            PRM.GIRDER_HSTIFF_ACTUAL, PRM.GIRDER_HSTIFF_RIGID])
          error(['梁水平面内変形の考慮は 1/2/3 ' ...
            'のいずれかを指定してください']);
        end
        options.girder_horizontal_stiffness_type = p;
      end
    case '横座屈の考慮'
      options.consider_lateral_torsional_buckling = (data{i,2}=='Y');
    case '柱座屈長さ係数の自動計算'
      options.consider_column_buckling_length_factor = (data{i,2}=='Y');
    case '柱座屈長さ係数の自動計算入力値α'
      p = data{i,2};
      if ~ismissing(p)
        options.brace_share_threshold = p;
      end
    case 'スカラップの考慮'
      options.consider_girder_scallop = (data{i,2}=='Y');
      p1 = data{i,3};
      if ~ismissing(p1)
        options.girder_scallop_size = p1;
      end
    case '支点浮き上がりの考慮'
      options.consider_foundation_uplift = (data{i,2}=='Y');
    case '梁・柱面での断面算定'
      options.consider_allowable_stress_at_face = (data{i,2}=='Y');
    case '床による梁剛性の考慮'
      options.consider_composite_slab_effect_s = data{i,2};
      options.consider_composite_slab_effect_rc = data{i,2};
      if data{i,2}==PRM.COMPOSITE_SLAB_DIRECT
        options.composite_slab_coefficient_s = [data{i,3} data{i,4}];
        options.composite_slab_coefficient_rc = [data{i,3} data{i,4}];
      end
    case '床によるS梁剛性の考慮'
      options.consider_composite_slab_effect_s = data{i,2};
      if data{i,2}==PRM.COMPOSITE_SLAB_DIRECT
        options.composite_slab_coefficient_s = [data{i,3} data{i,4}];
      end
    case '床によるRC梁剛性の考慮'
      options.consider_composite_slab_effect_rc = data{i,2};
      if data{i,2}==PRM.COMPOSITE_SLAB_DIRECT
        options.composite_slab_coefficient_rc = [data{i,3} data{i,4}];
      end
    case 'RC柱・梁Aの計算方法'
      p = data{i,5};
      if ~ismissing(p)
        options.rc_shear_area_type = validate_rc_area_type(p, ...
          'せん断変形用Aの計算方法');
      end
      if i < size(data,1) && isequal(tochar(data{i+1,2}), ...
          '軸変形用Aの計算方法')
        p = data{i+1,5};
        if ~ismissing(p)
          options.rc_axial_area_type = validate_rc_area_type(p, ...
            '軸変形用Aの計算方法');
        end
      end
    case 'ブレースの取り付き位置'
      options.position_brace_foundation_girder = data{i,2};      
    case '曲げの設計におけるウェブの考慮（梁中央部）'
      options.consider_web_at_girder_center = (data{i,2}=='Y');
    case '曲げの設計におけるウェブの考慮（梁端部）'
      options.consider_web_at_girder_end = (data{i,2}=='Y');
    case 'SN材H形鋼の幅厚比制限値の考慮'
      options.consider_SNH_WTRATIO = (data{i,2}=='Y');
    case 'S梁の軸力を考慮した検定'
      p = data{i,2};
      if ~ismissing(p)
        if ~ismember(p, [PRM.S_GIRDER_AXIAL_NONE, ...
            PRM.S_GIRDER_AXIAL_ALL, PRM.S_GIRDER_AXIAL_AUTO])
          error(['S梁の軸力を考慮した検定は 1/2/3 ' ...
            'のいずれかを指定してください']);
        end
        options.s_girder_axial_design = p;
      end
    case '保有耐力横補剛の事前処理'
      options.do_limit_slr_section = (data{i,2}=='Y');
    case '保有耐力接合（仕口）の事前処理'
      options.do_limit_jbs_section = (data{i,2}=='Y');
    case '保有耐力接合（仕口）の検討'
      p2 = data{i,2};
      if ~ismissing(p2)
        options.jbs_mu_formula = p2;
      end
      p3 = data{i,3};
      if ~ismissing(p3)
        options.jbs_alpha_type = p3;
      end
    case '幅厚比の事前処理'
      options.do_limit_wtratio_section = (data{i,2}=='Y');
    case '柱部材長のとり方'
      p = data{i,2};
      if ~ismissing(p)
        options.column_member_length_type = p;
      end
    case '設計ルート'
      p = data{i,2};
      if ~ismissing(p)
        options.design_route = p;
      end
  end
end

if ~options.do_preprocess_section_list
  options.do_limit_wtratio_section = false;
  options.do_limit_slr_section = false;
  options.do_limit_jbs_section = false;
end

% --- 最適化計算条件の設定 ---
for i=1:size(data,1)
  if ismissing(data{i,1})
    continue
  end
  switch data{i,1}
    case 'do_parallel'
      options.do_parallel = (data{i,2}=='Y');
    case 'iter_set'
      options.iter_set = data{i,2}:data{i,3};
    case 'maxiter_in_LS'
      if ~isfinite(options.maxiter_in_LS)
        options.maxiter_in_LS = data{i,2};
      end
    case 'maxcache'
      options.maxcache = data{i,2};
    case 'local_search_method'
      options.local_search_method = char(data{i,2});
    case 'max_fusion_depth'
      options.max_fusion_depth = data{i,2};
    case 'max_num_fusion_seed'
      options.max_num_fusion_seed = data{i,2};
    case 'max_num_fusion_candidate'
      options.max_num_fusion_candidate = data{i,2};
    case 'max_num_restoration_seed'
      options.max_num_restoration_seed = data{i,2};
    case 'max_num_restoration_candidate'
      options.max_num_restoration_candidate = data{i,2};
    case 'lsfr_diagnostic_file'
      options.lsfr_diagnostic_file = char(data{i,2});
    case 'display'
      options.display = data{i,2};
    case 'initial_penalty'
      for j=1:PRM.MAX_NUM_PHASE
        val = data{i,j+1};
        if isnumeric(val) && ~ismissing(val)
          options.mu0(j) = val;
        end
      end
  end
end

% % --- 出力制御条件の設定 ---
% for i=1:size(data,1)
%   if ismissing(data{i,1})
%     continue
%   end
% 
%   % --- 出力制御用のオプション値 ---
%   ncol = size(data,2)-1;
%   switch data{i,1}
%     case '梁断面リスト'
%       for j=2:size(data,2)
%         if ismissing(data{i,j})
%           ncol = j-1;
%           break
%         end
%         if isempty(data{i,j})
%           ncol = j-1;
%           break
%         end
%       end
%       if isempty(options.output_girder_list_label)
%         options.output_girder_list_label = data(i,2:ncol);
%       else
%         options.output_girder_list_label = ...
%           [options.output_girder_list_label data(i,2:ncol)];
%       end
% 
%     case '柱断面リスト'
%       for j=2:size(data,2)
%         if ismissing(data{i,j})
%           ncol = j-1;
%           break
%         end
%       end
%       if isempty(options.output_column_list_label)
%         options.output_column_list_label = data(i,2:ncol);
%       else
%         options.output_column_list_label = ...
%           [options.output_column_list_label data(i,2:ncol)];
%       end
%   end
% end

if ~options.consider_girder_scallop
  options.girder_scallop_size = 0;
end

return
end

function value = validate_rc_area_type(value, label)
%validate_rc_area_type - RC柱・梁Aの計算方法の指定値を検証する
valid = [PRM.RC_AREA_FLOOR_WALL, PRM.RC_AREA_WALL_ONLY, ...
  PRM.RC_AREA_SECTION_ONLY];
if ~ismember(value, valid)
  error('CommonOption:InvalidRcAreaType', ...
    '%s は 1/2/3 のいずれかを指定してください', label);
end
return
end
