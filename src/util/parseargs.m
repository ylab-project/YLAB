function options = parseargs(options, varargin)
%PARSEARGS 実行時引数の解釈処理
%
%   options = parseargs(options, varargin)
%
%   入力:
%       options - CommonOption オブジェクト
%       varargin - コマンドライン引数ペア

n = length(varargin);
tf = true(1,n);
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
parse(p,varargin{:});

% 結果の保存
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
    options = set_from_optionfile(options);
  catch ME
    error('YLAB:InvalidOptionFile', ...
      'オプションファイルの読み込みに失敗しました: %s', ME.message);
  end
end

end
