function build
% buildYLAB YLABのスタンドアロンアプリケーションとインストーラをビルドする

% 環境設定とインストール
if exist('install.m', 'file')
  install;
end

% バージョン情報の取得
% YLAB.p を通じてバージョンを取得
try
  [~, res, ~] = YLAB('-version');
  version = res.version;
  devDate = res.devDate;
catch
  warning('Could not get version from YLAB.p. Using default.');
  version = '0.0.0';
  devDate = datetime('now');
end

% 出力ディレクトリの準備
buildDir = fullfile(pwd, 'build');
cleanup_build_dir(buildDir);

% ビルド実行
fprintf('Building Standalone Application (from YLAB.p)\n');

% Pコードからは依存関係が自動抽出されないため、src フォルダを明示的に追加
srcDir = fullfile(pwd, 'src');
appDir = fileparts(mfilename('fullpath'));
lsfrDir = fullfile(fileparts(appDir), 'src', 'lsfr');
if exist(lsfrDir, 'dir')
  addpath(lsfrDir);
end

% Toolboxの有無を確認
hasReportGen = ~isempty(ver('rptgen')) || ~isempty(ver('rptgencore'));
hasGlobalOpt = ~isempty(ver('globaloptim'));

% 除外パターンの構築
excludePatterns = {};
if hasReportGen
  fprintf('Report Generator detected: PDF feature enabled\n');
else
  fprintf('Report Generator not found: PDF feature disabled\n');
  excludePatterns{end+1} = '^(report_|reportManager|makeDOMCompilable)';
end

if hasGlobalOpt
  fprintf('Global Optimization Toolbox detected: GA mode enabled\n');
else
  fprintf('Global Optimization Toolbox not found: GA mode disabled\n');
  excludePatterns{end+1} = '^call_ga\.m$';
end

% ソースファイルの収集
if isempty(excludePatterns)
  additionalFiles = {srcDir};
else
  additionalFiles = collectSourceFiles(srcDir, excludePatterns);
  fprintf('  Excluded files based on available toolboxes\n');
end
if exist(lsfrDir, 'dir')
  additionalFiles{end + 1} = lsfrDir;
end

% Pファイル解析警告を一時的に抑制（srcDir で依存関係を手動追加済み）
warnId = 'Compiler:build:shared:cannotAnalyzePFiles';
warnState = warning('off', warnId);
restoreWarn = onCleanup(@() warning(warnState));

results = compiler.build.standaloneApplication(...
  "YLAB.p", ...
  "OutputDir", "build", ...
  "AdditionalFiles", additionalFiles, ...
  "Verbose", "on", ...
  "ExecutableVersion", version ...
  );

% インストーラーの作成
description = sprintf([ ...
  'YLAB (Y-Lab Structural Optimization) is an advanced ' ...
  'structural optimization program ' ...
  'for building frame design using local search algorithms.\n\n' ...
  'This application was developed on %s by Yamakawa Laboratory ' ...
  'at Tokyo University of Science (TUS).\n\n' ...
  'Features:\n' ...
  '• Comprehensive tools for optimizing steel frame structures\n' ...
  '• Support for H-beams, hollow sections, ' ...
  'and buckling-restrained braces\n' ...
  '• Multiple execution modes: optimization analysis, ' ...
  'result verification, and SS7 data conversion\n' ...
  '• Advanced local search algorithms for structural optimization\n\n' ...
  'Copyright (c) Yamakawa Laboratory, ' ...
  'Tokyo University of Science'], devDate);

fprintf('Packaging Installer...\n');

cleanupWarnIds = { ...
  'MATLAB:class:DestructorError', ...
  'MATLAB:DELETE:Permission'};
cleanupWarnStates = set_warning_state(cleanupWarnIds, 'off');
restoreWarn = onCleanup(@() restore_warning_state(cleanupWarnStates));

compiler.package.installer(results, ...
  "ApplicationName", "YLAB", ...
  "AuthorCompany", "Yamakawa Lab.", ...
  "AuthorEmail", "myamakawa@rs.tus.ac.jp", ...
  "AuthorName", "Makoto Yamakawa", ...
  "InstallerName", "YLabInstaller", ...
  "Version", version, ...
  "DefaultInstallationDir", "C:\\Program Files\\YLAB\\YLAB", ...
  "OutputDir", "build", ...
  "Description", description, ...
  "Verbose", "on");

clear restoreWarn
cleanup_installer_temp(buildDir);

fprintf('Build successful.\n');

end

%--------------------------------------------------------------------------
function cleanup_build_dir(buildDir)
%cleanup_build_dir - ビルド出力フォルダを初期化する

if exist(buildDir, 'dir')
  fprintf('Cleaning up build directory...\n');
  remove_build_dir(buildDir);
end

[ok, msg] = mkdir(buildDir);
if ~ok
  errMsg = 'ビルド出力フォルダを作成できません: %s\n%s';
  error('YLAB:Build:MkdirFailed', errMsg, buildDir, msg);
end

return
end

%--------------------------------------------------------------------------
function remove_build_dir(buildDir)
%remove_build_dir - ビルド出力フォルダを削除する

tryCount = 8;
waitSec = 1.0;
lastMsg = '';
for i = 1:tryCount
  [ok, msg] = rmdir(buildDir, 's');
  if ok || ~exist(buildDir, 'dir')
    return
  end
  lastMsg = msg;
  pause(waitSec);
end

if exist(buildDir, 'dir')
  error('YLAB:Build:CleanupFailed', ...
    ['ビルド出力フォルダを削除できません: %s\n' ...
    'MATLAB、YLAB、エクスプローラー、Dropbox 同期が ' ...
    'このフォルダを使用していないか確認してください。\n%s'], ...
    buildDir, lastMsg);
end

return
end

%--------------------------------------------------------------------------
function cleanup_installer_temp(buildDir)
%cleanup_installer_temp - インストーラー作成時の一時フォルダを削除する

tempNames = {'YLAB_resources', 'uninstall_icon_resources'};
for i = 1:numel(tempNames)
  tempDir = fullfile(buildDir, tempNames{i});
  cleanup_temp_dir(tempDir);
end
cleanup_temp_file(fullfile(buildDir, 'installAgentURL.txt'));

return
end

%--------------------------------------------------------------------------
function cleanup_temp_dir(tempDir)
%cleanup_temp_dir - 指定された一時フォルダを削除する

if ~exist(tempDir, 'dir')
  return
end

tryCount = 5;
waitSec = 0.5;
for i = 1:tryCount
  [ok, ~] = rmdir(tempDir, 's');
  if ok || ~exist(tempDir, 'dir')
    return
  end
  pause(waitSec);
end

fprintf('インストーラー一時フォルダを残しました: %s\n', tempDir);

return
end

%--------------------------------------------------------------------------
function cleanup_temp_file(tempFile)
%cleanup_temp_file - 指定された一時ファイルを削除する

if ~exist(tempFile, 'file')
  return
end

tryCount = 5;
waitSec = 0.5;
warnState = warning('off', 'MATLAB:DELETE:Permission');
restoreWarn = onCleanup(@() warning(warnState));
for i = 1:tryCount
  delete(tempFile);
  if ~exist(tempFile, 'file')
    return
  end
  pause(waitSec);
end

fprintf('インストーラー一時ファイルを残しました: %s\n', tempFile);

return
end

%--------------------------------------------------------------------------
function warnStates = set_warning_state(warnIds, state)
%set_warning_state - 指定された警告状態をまとめて変更する

warnStates = repmat(warning('query', warnIds{1}), 1, numel(warnIds));
for i = 1:numel(warnIds)
  warnStates(i) = warning(state, warnIds{i});
end

return
end

%--------------------------------------------------------------------------
function restore_warning_state(warnStates)
%restore_warning_state - 保存した警告状態を復元する

for i = 1:numel(warnStates)
  warning(warnStates(i));
end

return
end

%--------------------------------------------------------------------------
function files = collectSourceFiles(srcDir, excludePatterns)
%collectSourceFiles 指定パターンに一致するファイルを除外してソースを収集
%   excludePatterns: 除外する正規表現パターンのセル配列

allFiles = dir(fullfile(srcDir, '**', '*.m'));

% 各ファイルがいずれかの除外パターンに一致するかチェック
keep = true(1, numel(allFiles));
for i = 1:numel(allFiles)
  for j = 1:numel(excludePatterns)
    if ~isempty(regexp(allFiles(i).name, excludePatterns{j}, 'once'))
      keep(i) = false;
      break;
    end
  end
end
filteredFiles = allFiles(keep);

files = cell(1, numel(filteredFiles));
for i = 1:numel(filteredFiles)
  files{i} = fullfile(filteredFiles(i).folder, filteredFiles(i).name);
end
end
