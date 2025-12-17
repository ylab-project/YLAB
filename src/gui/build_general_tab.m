function h = build_general_tab(parent, options)
% BUILD_GENERAL_TAB 基本設定タブの構築
%
%   h = build_general_tab(parent, options)
%   Returns a struct of UI handles.

tab = uitab(parent, 'Title', '基本設定');
gl = uigridlayout(tab, [6, 3]);
gl.RowHeight = {30, 30, 30, 30, 30, '1x'};
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
h.dd_exemode = uidropdown(gl, 'Items', {'OPT', 'CHECK', 'CONVERT', 'GA'}, 'Value', options.exemode);
uilabel(gl, 'Text', '');

% 4: Auto Copy
h.cb_autocopy = uicheckbox(gl, 'Text', 'Copy Output File to Original source');
h.cb_autocopy.Layout.Row = 4; h.cb_autocopy.Layout.Column = [1 3];

% 5: PDF
h.cb_pdf = uicheckbox(gl, 'Text', 'Create PDF Report');
h.cb_pdf.Value = options.do_writeout_pdf;
h.cb_pdf.Layout.Row = 5; h.cb_pdf.Layout.Column = [1 3];
end
