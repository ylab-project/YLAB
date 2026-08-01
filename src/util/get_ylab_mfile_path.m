function path = get_ylab_mfile_path()
%get_ylab_mfile_path - 実行中のYLAB本体ファイルのパスを取得する
%
%   path = get_ylab_mfile_path() は、MATLAB が YLAB として解決して
%   いるファイルのフルパスを返す。同一フォルダに YLAB.p と YLAB.m が
%   ある場合は YLAB.p を返すため、どの実体が動いているか判別できる。
%
%   出力引数:
%     path - 実行中の YLAB.p または YLAB.m のフルパス

path = which('YLAB');

return
end
