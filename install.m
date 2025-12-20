function install(opts)
% install - パス設定関数
%
% 使用法:
%   install              % 通常のインストール
%   install(isTest=true) % 名前付き引数での指定（R2021a以降）

arguments
  opts.isTest logical = false   % デフォルト値はfalse
end

% ルートディレクトリの取得（install.m のある場所）
rootDir = fileparts(mfilename('fullpath'));

% パスをデフォルトにリセット（クリーンな状態にする）
restoredefaultpath;

% 基本パスの追加
addpath(rootDir);
list = {...
  'src', ...
  'src/analysis', ...
  'src/classes' , ...
  'src/lsr', ...
  'src/postprocess', ...
  'src/preprocess', ...
  'src/util', ...
  'src/gui'};

% テスト実行時はtestディレクトリも追加
if opts.isTest
  list{end+1} = 'test';
  list{end+1} = 'test/utils';
  list{end+1} = 'tools';
  list{end+1} = 'tmp';
  list{end+1} = 'src/lsr_legacy';
end

% パスの追加
n = length(list);
for i=1:n
  targetPath = fullfile(rootDir, list{i});
  if exist(targetPath, 'dir')
    addpath(targetPath);
  end
end

return
end