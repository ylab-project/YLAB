function h = build_history_tab(parent, options)
% BUILD_HISTORY_TAB 履歴タブの構築

tab = uitab(parent, 'Title', '履歴');
gl = uigridlayout(tab, [5, 4]);
gl.RowHeight = {30, 20, 30, 30, 30};
gl.ColumnWidth = {120, '1x', 60, 40};

h = struct();

% History File
lbl = uilabel(gl, 'Text', 'History (.mat):', 'FontWeight', 'bold');
lbl.Layout.Row = 1; lbl.Layout.Column = 1;

h.edt_matfile = uieditfield(gl, 'text', 'Value', options.matfile);
h.edt_matfile.Layout.Row = 1; h.edt_matfile.Layout.Column = 2;

h.btn_browse = uibutton(gl, 'Text', '...');
h.btn_browse.Layout.Row = 1; h.btn_browse.Layout.Column = 3;

% Info Label
h.lbl_info = uilabel(gl, 'Text', 'No file loaded.', 'FontColor', [0.5 0.5 0.5]);
h.lbl_info.Layout.Row = 2; h.lbl_info.Layout.Column = [2 4];

% Resume Settings
lbl = uilabel(gl, 'Text', 'Resume Trial:');
lbl.Layout.Row = 3; lbl.Layout.Column = 1;

h.dd_res_trial = uidropdown(gl, 'Items', {'-'}, 'Enable', 'off');
h.dd_res_trial.Layout.Row = 3; h.dd_res_trial.Layout.Column = 2;

lbl = uilabel(gl, 'Text', 'Resume Phase:');
lbl.Layout.Row = 4; lbl.Layout.Column = 1;

h.dd_res_phase = uidropdown(gl, 'Items', {'-'}, 'Enable', 'off');
h.dd_res_phase.Layout.Row = 4; h.dd_res_phase.Layout.Column = 2;

lbl = uilabel(gl, 'Text', 'Iter:', 'HorizontalAlignment', 'right');
lbl.Layout.Row = 4; lbl.Layout.Column = 3;

h.sef_res_iter = uieditfield(gl, 'numeric', 'Value', 0, 'Enable', 'off');
h.sef_res_iter.Layout.Row = 4; h.sef_res_iter.Layout.Column = 4;

% Plot Button
h.btn_plot = uibutton(gl, 'Text', 'Plot History', 'Enable', 'off');
h.btn_plot.Layout.Row = 5; h.btn_plot.Layout.Column = [3 4];
end
