function h = build_general_tab(parent, options)
% BUILD_GENERAL_TAB 基本設定タブの構築
%
%   h = build_general_tab(parent, options)
%   Returns a struct of UI handles.

tab = uitab(parent, 'Title', '基本設定');
gl = uigridlayout(tab, [8, 3]);
gl.RowHeight = {30, 30, 30, 30, 30, 30, 30, '1x'};
gl.ColumnWidth = {100, '1x', 80};

h = struct();

% 1: Input
uilabel(gl, 'Text', 'Input File:');
h.edt_input = uieditfield(gl, 'text', 'Value', options.inputfile);
h.btn_input = uibutton(gl, 'Text', '...');

% 2: Output
uilabel(gl, 'Text', 'Output File:');
h.edt_output = uieditfield(gl, 'text', 'Value', options.outputfile);
h.btn_output = uibutton(gl, 'Text', '...');

% 3: ExeMode
uilabel(gl, 'Text', 'ExeMode:');
h.dd_exemode = uidropdown(gl, 'Items', {'OPT', 'CHECK', ...
  'CONVERT'}, 'Value', options.exemode);
uilabel(gl, 'Text', '');

% 4: Algorithm
algorithm_items = {'LSR（全Phase）', 'LSFR（全Phase）', ...
  'LSR → LSFR（Phase 1 → Phase 2以降）', 'GA'};
uilabel(gl, 'Text', 'Algorithm:');
h.dd_algorithm = uidropdown(gl, 'Items', algorithm_items, 'ItemsData', ...
  {'LSR', 'LSFR', 'LSR_LSFR', 'GA'}, 'Value', options.algorithm);
uilabel(gl, 'Text', '');

% 5: Auto Copy
h.cb_autocopy = uicheckbox(gl, 'Text', ...
  'Copy Output File to Original source');
h.cb_autocopy.Layout.Row = 5; h.cb_autocopy.Layout.Column = [1 3];

% 6: PDF
h.cb_pdf = uicheckbox(gl, 'Text', 'Create PDF Report');
h.cb_pdf.Value = options.do_writeout_pdf;
h.cb_pdf.Layout.Row = 6;
h.cb_pdf.Layout.Column = [1 3];

% 7: Preprocess
h.cb_nopreprocess = uicheckbox(gl, 'Text', ...
  '断面リスト事前処理を無効化（比較用）');
h.cb_nopreprocess.Value = ~options.do_preprocess_section_list;
h.cb_nopreprocess.Layout.Row = 7;
h.cb_nopreprocess.Layout.Column = [1 3];

return
end
