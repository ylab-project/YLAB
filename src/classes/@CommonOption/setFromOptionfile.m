function options = setFromOptionfile(options)
%SET_FROM_OPTIONFILE この関数の概要をここに記述
%   詳細説明をここに記述
mat = readmatrix(options.optionfile, ...
  Delimiter=',', ...
  CommentStyle='%', ...
  OutputType='string', ...
  NumHeaderLines=0);

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
    case 'display'
      options.display = mat{i,2};
  end
end

end


