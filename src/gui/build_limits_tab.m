function h = build_limits_tab(parent, options)
% BUILD_LIMITS_TAB 終了条件タブの構築

tab = uitab(parent, 'Title', '終了条件');
gl = uigridlayout(tab, [5, 2]);
gl.RowHeight = {30, 30, 30, 30, '1x'};
gl.ColumnWidth = {100, '1x'};

h = struct();

lbl = uilabel(gl, 'Text', 'Max Phase:');
lbl.Layout.Row = 1; lbl.Layout.Column = 1;

h.sef_maxphase = uieditfield(gl, 'numeric', 'Value', options.maxphase);
h.sef_maxphase.Layout.Row = 1; h.sef_maxphase.Layout.Column = 2;

lbl = uilabel(gl, 'Text', 'Max Iter:');
lbl.Layout.Row = 2; lbl.Layout.Column = 1;

h.sef_maxiter = uieditfield(gl, 'numeric', 'Value', options.maxiter_in_LS);
h.sef_maxiter.Layout.Row = 2; h.sef_maxiter.Layout.Column = 2;

lbl = uilabel(gl, 'Text', 'Trial ID:');
lbl.Layout.Row = 3; lbl.Layout.Column = 1;

h.sef_trialid = uieditfield(gl, 'numeric', 'Value', options.idtrial);
h.sef_trialid.Layout.Row = 3; h.sef_trialid.Layout.Column = 2;
end
