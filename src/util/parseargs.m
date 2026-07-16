function options = parseargs(options, varargin)
%parseargs - 実行時引数の解釈処理
%
%   options = parseargs(options, varargin) は、実行時引数 varargin を
%   解釈してoptionsオブジェクトを更新する。フラグ引数（'-pdf' 等）と
%   キー・値ペアの両方を扱う。
%
%   入力引数:
%     options  - CommonOption オブジェクト
%     varargin - コマンドライン引数ペア
%
%   出力引数:
%     options - 解釈済みの CommonOption オブジェクト
%
%   備考:
%     フラグ引数:
%       '-pdf'        - PDF出力を有効化
%       '-nopdf'      - PDF出力を無効化
%       '-dev'        - 開発者モード（GUI強制）
%       '-legacy'     - レガシー出力形式を使用
%       '-nopreprocess' - 断面リスト事前処理を無効化
%       '-sequential' - 並列計算を無効化（プロファイリング用）
%       '-LSFR'       - 第2Phase以降でLSFRを使用
%       '-LSFR:full'  - 全PhaseでLSFRを使用
%       '-LSR'        - 局所探索法をLSRへ切り替える

n = length(varargin);
tf = true(1,n);
local_search_method_flag = '';
for i=1:n
  switch varargin{i}
    case '-nopdf'
      tf(i) = false;
      options.do_writeout_pdf = false;
    case '-pdf'
      tf(i) = false;
      options.do_writeout_pdf = true;
    case '-dev'
      tf(i) = false;
      options.developer_mode = true;
    case '-legacy'
      tf(i) = false;
      options.do_legacy_output = true;
    case '-nopreprocess'
      tf(i) = false;
      options.do_preprocess_section_list = false;
    case '-sequential'
      tf(i) = false;
      options.do_parallel = false;
    case '-LSFR'
      tf(i) = false;
      local_search_method_flag = 'LSFR';
      options.do_lsfr_all_phases = false;
    case '-LSFR:full'
      tf(i) = false;
      local_search_method_flag = 'LSFR';
      options.do_lsfr_all_phases = true;
    case '-LSR'
      tf(i) = false;
      local_search_method_flag = 'LSR';
      options.do_lsfr_all_phases = false;
  end
end
varargin = varargin(tf);

% 構文解析
p = inputParser;
p.PartialMatching = true;
addParameter(p, 'uimode', options.uimode);
addParameter(p, 'exemode', options.exemode);
addParameter(p, 'inputfile', options.inputfile);
addParameter(p, 'outputfile', options.outputfile);
addParameter(p, 'solutionfile', options.solutionfile);
addParameter(p, 'optionfile', options.optionfile);
addParameter(p, 'matfile', options.matfile);
addParameter(p, 'trial', options.idtrial_resume);
addParameter(p, 'phase', options.idphase_resume);
addParameter(p, 'iter', options.iter_resume);
addParameter(p, 'maxiter', options.maxiter_in_LS);
addParameter(p, 'maxphase', options.maxphase);
addParameter(p, 'lsfr_diagnostic_file', options.lsfr_diagnostic_file);
parse(p,varargin{:});

% UIモードの決定（文字列 -> 数値ID変換）
raw_uimode = p.Results.uimode;
if isnumeric(raw_uimode)
  options.uimode = raw_uimode;
elseif strcmpi(raw_uimode, 'GUI')
  options.uimode = PRM.UIMODE_GUI;
else
  options.uimode = PRM.UIMODE_CUI;
end

% -devフラグの優先（developer_mode=trueならGUIモード）
if options.developer_mode
  options.uimode = PRM.UIMODE_GUI;
end

options.exemode = p.Results.exemode;
options.inputfile = p.Results.inputfile;
options.outputfile = p.Results.outputfile;
options.solutionfile = p.Results.solutionfile;
options.optionfile = p.Results.optionfile;
options.matfile = p.Results.matfile;
options.lsfr_diagnostic_file = p.Results.lsfr_diagnostic_file;
if isstring(p.Results.trial)
  options.idtrial_resume = str2double(p.Results.trial);
else
  options.idtrial_resume = p.Results.trial;
end
if isstring(p.Results.phase)
  options.idphase_resume = str2double(p.Results.phase);
else
  options.idphase_resume = p.Results.phase;
end
if isstring(p.Results.iter)
  options.iter_resume = str2double(p.Results.iter);
else
  options.iter_resume = p.Results.iter;
end
if ischar(p.Results.maxiter) || isstring(p.Results.maxiter)
  options.maxiter_in_LS = str2double(p.Results.maxiter);
else
  options.maxiter_in_LS = p.Results.maxiter;
end
if ischar(p.Results.maxphase) || isstring(p.Results.maxphase)
  options.maxphase = str2double(p.Results.maxphase);
else
  options.maxphase = p.Results.maxphase;
end

% オプションファイルの読み込み
if ~isempty(options.optionfile)
  try
    options = setFromOptionfile(options);
  catch ME
    error('YLAB:InvalidOptionFile', ...
      'オプションファイルの読み込みに失敗しました: %s', ...
      ME.message);
  end
end
if ~isempty(local_search_method_flag)
  options.local_search_method = local_search_method_flag;
end

return
end
