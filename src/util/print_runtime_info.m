function print_runtime_info(app_version, dev_date, ylab_path)
%print_runtime_info - バージョンと実行環境を表示する
%
%   print_runtime_info(app_version, dev_date, ylab_path) は、YLABの
%   バージョン、MATLABのリリース、実行中の本体ファイルを表示する。
%
%   入力引数:
%     app_version - YLABのバージョン文字列 (char)
%     dev_date    - 開発日 (datetime)
%     ylab_path   - 実行中の本体ファイルのフルパス (char)

matlab_release = matlabRelease;
release_date = string(dev_date, 'yyyy-MM-dd');
fprintf('YLAB %s (released on %s)\n', app_version, release_date);
fprintf('MATLAB: %s Update %d\n', matlab_release.Release, ...
  matlab_release.Update);
fprintf('Module: %s\n', ylab_path);

return
end
