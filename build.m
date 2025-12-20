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
if exist(buildDir, 'dir')
  fprintf('Cleaning up build directory...\n');
  [~, ~] = rmdir(buildDir, 's');
end
pause(1); % OSのファイル解放待ち
if ~exist(buildDir, 'dir')
  mkdir(buildDir);
end

% ビルド実行
fprintf('Building Standalone Application (from YLAB.p)\n');

% Pコードからは依存関係が自動抽出されないため、src フォルダを明示的に追加
srcDir = fullfile(pwd, 'src');

% Report Generator Toolboxの有無を確認
hasReportGen = ~isempty(ver('rptgen')) || ~isempty(ver('rptgencore'));

if hasReportGen
  % Toolboxあり: src全体を含める（PDF機能有効）
  fprintf('Report Generator detected: PDF feature enabled\n');
  additionalFiles = {srcDir};
else
  % Toolboxなし: report関連を除外（PDF機能無効）
  fprintf('Report Generator not found: PDF feature disabled\n');
  additionalFiles = collectSourceFilesWithoutReport(srcDir);
  fprintf('  Excluding %d report-related files\n', ...
    numel(dir(fullfile(srcDir, '**', 'report*.m'))));
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

compiler.package.installer(results, ...
  "ApplicationName", "YLAB", ...
  "AuthorCompany", "TUS", ...
  "AuthorEmail", "myamakawa@rs.tus.ac.jp", ...
  "AuthorName", "Yamakawa Lab.", ...
  "InstallerName", "YLabInstaller", ...
  "Version", version, ...
  "DefaultInstallationDir", "C:\\Program Files\\TUS\\YLAB", ...
  "OutputDir", "build", ...
  "Description", description, ...
  "Verbose", "on");

fprintf('Build successful.\n');

end

%--------------------------------------------------------------------------
function files = collectSourceFilesWithoutReport(srcDir)
%collectSourceFilesWithoutReport Report Generator依存ファイルを除外
%   report_*.m, reportManager.m, makeDOMCompilable.m を除外したリストを返す

allFiles = dir(fullfile(srcDir, '**', '*.m'));
excludePattern = '^(report_|reportManager|makeDOMCompilable)';
keep = cellfun(@(x) isempty(regexp(x, excludePattern, 'once')), {allFiles.name});
filteredFiles = allFiles(keep);

files = cell(1, numel(filteredFiles));
for i = 1:numel(filteredFiles)
  files{i} = fullfile(filteredFiles(i).folder, filteredFiles(i).name);
end
end