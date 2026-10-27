function options = setFromOptionfile(options)
%setFromOptionfile - オプションCSVから共通設定を読み込む
%
%   options = setFromOptionfile(options) は、キーと値のCSVを読み、
%   指定された設定を更新する。値の範囲はプロパティ代入時に検証する。
%
%   入力引数:
%     options - optionfileに読込先を持つ共通オプション
%
%   出力引数:
%     options - 読込後の共通オプション

mat = readmatrix(options.optionfile, Delimiter=',', ...
  CommentStyle='%', OutputType='string', NumHeaderLines=0);

for i=1:size(mat,1)
  % --- フラグ ---
  switch mat{i,1}
    case 'consider_self_weight'
      options.consider_self_weight = (mat{i,2}=='T');
    case 'consider_shear_deformation'
      options.consider_shear_deformation = (mat{i,2}=='T');
    case 'consider_lateral_torsional_buckling'
      options.consider_lateral_torsional_buckling = (mat{i,2}=='T');
    case 'consider_column_buckling_length_factor'
      options.consider_column_buckling_length_factor = (mat{i,2}=='T');
    case 'consider_girder_scallop'
      options.consider_girder_scallop = (mat{i,2}=='T');
    case 'consider_foundation_uplift'
      options.consider_foundation_uplift = (mat{i,2}=='T');
    case 'do_parallel'
      options.do_parallel = (mat{i,2}=='T');
  end

  % --- 値 ---
  switch mat{i,1}
    case 'girder_scallop_size'
      options.girder_scallop_size = str2double(mat{i,2});
    case 'iter_set'
      options.iter_set = str2double(mat{i,2}):str2double(mat{i,3});
    case 'maxiter_in_LS'
      options.maxiter_in_LS = str2double(mat{i,2});
    case 'maxcache'
      options.maxcache = str2double(mat{i,2});
    case 'algorithm'
      options.algorithm = char(mat{i,2});
    case 'max_fusion_depth'
      options.max_fusion_depth = str2double(mat{i,2});
    case 'fusion_keep_ratio'
      options.fusion_keep_ratio = str2double(mat{i,2});
    case 'max_num_fusion_candidate'
      options.max_num_fusion_candidate = str2double(mat{i,2});
    case 'max_num_restoration_seed'
      options.max_num_restoration_seed = str2double(mat{i,2});
    case 'max_num_restoration_candidate'
      options.max_num_restoration_candidate = str2double(mat{i,2});
    case 'lsfr_diagnostic_file'
      options.lsfr_diagnostic_file = char(mat{i,2});
    case 'display'
      options.display = mat{i,2};
    case 'column_member_length_type'
      options.column_member_length_type = str2double(mat{i,2});
  end
end

return
end
