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