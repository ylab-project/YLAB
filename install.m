function install
%install - パス設定関数（公開環境用）
%
%   install は、YLAB 公開環境用にパスを設定する。
%   MATLAB のパスをデフォルトに戻した上で、YLAB 配下の
%   必要なディレクトリを addpath する。
%
%   備考:
%     - 引数・戻り値はなし。
%     - mfilename('fullpath') を基準に絶対パスを解決する。

% ルートディレクトリの取得（install.m のある場所）
app_dir = fileparts(mfilename('fullpath'));

% パスをデフォルトにリセット（クリーンな状態にする）
restoredefaultpath;

% 基本パスの追加
addpath(app_dir);
app_paths = {'src', 'src/analysis', 'src/classes', 'src/lsr', ...
  'src/postprocess', 'src/preprocess', 'src/util', 'src/gui'};
addpathlist_(app_dir, app_paths)
return
end

function addpathlist_(target_dir, paths)
%addpathlist_ - 指定ディレクトリ配下の相対パス群を addpath する
%
%   addpathlist_(target_dir, paths) は、target_dir を起点として
%   paths の各要素を結合した絶対パスを順に addpath する。
%   存在しないディレクトリはスキップする。
%
%   入力引数:
%     target_dir - 起点ディレクトリの絶対パス (char)
%     paths      - 相対パス文字列のセル配列 (cell of char)

for i = 1:numel(paths)
  p = fullfile(target_dir, paths{i});
  if exist(p, 'dir')
    addpath(p);
  end
end
end