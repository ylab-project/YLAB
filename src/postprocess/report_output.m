function report_output(xvar, com, options)
makeDOMCompilable();
import mlreportgen.report.*
import mlreportgen.dom.*

% 共通定数
nblx = com.nblx;
nbly = com.nbly;
nblz = com.nblz;

% 共通設定
rm = reportManager();
rm.workdir = options.workdirpath;
[outpath, outname] = fileparts(options.outputfile);
reportfile = fullfile(outpath, outname);
set(0, 'defaultAxesFontName', 'Times')
set(0, 'defaultTextFontName', 'Times');
set(0, 'defaultAxesFontSize', 9);
set(0, 'defaultTextFontSize', 9);
warning('off','MATLAB:print:ContentTypeImageSuggested');

% 計算の準備
secmgr = com.secmgr;
section = com.section;
member = com.member;
baseline = com.baseline;
node = com.node;
lm = com.member.property.lm;

% 解析
story = com.story;
floor = com.floor;
[fval, fdetail] = objective_lsr(xvar, secmgr, baseline, node, ...
  section, member, story, floor, options);
[cvec, result] = analysis_constraint(xvar, com, options);
% lm = com.member.property.lm;
% lm = result.lm;
% TODO: とりあえず
com.baseline = result.baseline;
com.node = result.node;
com.floor = result.floor;
com.story = result.story;

% レポート オブジェクトの作成
rpt = Report(reportfile, 'pdf');
rpt.Locale = 'en';
pageLayoutObj = PDFPageLayout;
pageLayoutObj.Style = [pageLayoutObj.Style ...
  {FontSize(rm.font_size) FontFamily(rm.font_family)}];
fprintf('【出力準備中】');

% --- タイトル ページ --- 
tp = TitlePage;
tp.Title = '最適化計算結果';
tp.Subtitle = com.modelname;
tp.Author = [];
tp.Subtitle = com.modelname;
% tp.PubDate = date();
fprintf('.');

% --- モデル図 ---
poptions = optionPlotFrame;
poptions.mode = '3D';
fig = plot_frame_model(com, poptions);
rm.appendFigure(tp, fig);
append(rpt, tp);
fprintf('.');

% --- 目次 ---
append(rpt, TableOfContents);
fprintf('.');

% --- 概要 ---
ch = Chapter('概要');
append(ch, com.comment);
append(ch, LineBreak());

% --- 設計変数 ---
append(ch, report_desgin_setting(com, options));
append(ch, PageBreak()); 
fprintf('.');

% --- 床伏図 ---
append(ch, report_framing_plan(rm, com));
fprintf('.');

% --- 軸組図 ---
% Xフレーム
append(ch, report_framing_elevation(rm, com, 'XFRAME'));
fprintf('.');

% Yフレーム ---
append(ch, report_framing_elevation(rm, com, 'YFRAME'));
fprintf('.');
append(rpt, ch);

% --- 最適解 ---
ch = Chapter('最適解');
append(ch, report_desgin_variables(com, xvar));

% --- 鋼材量 ---
append(ch, report_steel_weigth(fval));
append(ch, LineBreak());
fprintf('.');

% --- 断面リスト ---
sec = report_section_dimensions(xvar, com, result, options);
append(ch, sec); fprintf('.');
append(ch, PageBreak()); 

append(rpt, ch); 

% % --- 断面性能 ---
% sec = Section();
% sec = report_section_properties(sec, convar, result);
% append(ch, sec); fprintf('.');

% % --- 節点変位 ---
% ch = Chapter(); ch.Title = '節点変位';
% sec = Section();
% sec = report_nodal_displacement(sec, convar, result);
% append(ch, sec); 
% append(rpt, ch); 
% fprintf('.');
% 
% % --- 節点変位 ---
% ch = Chapter(); ch.Title = '断面算定';
% sec = Section(); sec.Title = '断面算定表';
% subsec = report_section_calculation_girder(Section(), convar, result);
% append(sec, subsec);
% append(ch, sec);
% append(rpt, ch); 
% fprintf('.');

% --- 終了処理 ---
try
  close(rpt);
catch ME
  try
    pause(1);
    rmdir([reportfile '_FO']);
  catch ME
    % disp(ME.message);
  end
end

try
  fclose('all');
  delete([rm.figname '-*.pdf']);
catch ME
  disp(ME.message);
end
return
end

