function h = build_general_tab(parent, options)
%build_general_tab - 入出力と実行内容の設定欄を作る
%
%   h = build_general_tab(parent, options) は、基本設定タブを作る。
%
%   入力引数:
%     parent  - 配置先のタブグループ
%     options - 初期設定のCommonOption
%
%   出力引数:
%     h - 設定欄と表示欄のハンドルを持つ構造体

tab = uitab(parent, 'Title', '基本設定');
gl = uigridlayout(tab, [9, 3]);
gl.RowHeight = {30, 30, 30, 30, 30, 30, 30, 30, '1x'};
gl.ColumnWidth = {110, '1x', 80};

h = struct();
uilabel(gl, 'Text', 'Input File:');
h.edt_input = uieditfield(gl, 'text', 'Value', options.inputfile);
h.btn_input = uibutton(gl, 'Text', '...');

h.lbl_output = uilabel(gl, 'Text', 'Output File:');
h.edt_output = uieditfield(gl, 'text', 'Value', options.outputfile);
h.btn_output = uibutton(gl, 'Text', '...');

uilabel(gl, 'Text', 'ExeMode:');
h.dd_exemode = uidropdown(gl, 'Items', {'OPT', 'CHECK', ...
  'CONVERT', 'COPY'}, 'Value', options.exemode);
uilabel(gl, 'Text', '');

algorithm_items = {'LSR（全Phase）', 'LSFR（全Phase）', ...
  'LSR → LSFR（Phase 1 → Phase 2以降）', 'GA'};
uilabel(gl, 'Text', 'Algorithm:');
h.dd_algorithm = uidropdown(gl, 'Items', algorithm_items, 'ItemsData', ...
  {'LSR', 'LSFR', 'LSR_LSFR', 'GA'}, 'Value', options.algorithm);
uilabel(gl, 'Text', '');

% 整数と割合をそのまま指定できるようテキスト欄を使う。
uilabel(gl, 'Text', 'ワーカー数:');
h.edt_num_workers = uieditfield(gl, 'text', 'Value', ...
  char(string(options.num_workers)), 'Placeholder', '100%', ...
  'Tooltip', '正の整数または有効物理コア数に対する割合（既定100%）');
uilabel(gl, 'Text', '例: 4, 50%');

% コピー元を選び直しても、起動時の返却先は変わらない。
uilabel(gl, 'Text', 'SS7返却先:');
edt_target = uieditfield(gl, 'text', 'Value', options.outputfile, ...
  'Editable', 'off', 'Tooltip', 'GUI起動時のOutput File（編集不可）', ...
  'Placeholder', 'SS7返却先が指定されていません');
edt_target.Layout.Row = 6;
edt_target.Layout.Column = [2 3];

h.cb_pdf = uicheckbox(gl, 'Text', 'Create PDF Report');
h.cb_pdf.Value = options.do_writeout_pdf;
h.cb_pdf.Layout.Row = 7;
h.cb_pdf.Layout.Column = [1 3];

h.cb_nopreprocess = uicheckbox(gl, 'Text', ...
  '断面リスト事前処理を無効化（比較用）');
h.cb_nopreprocess.Value = ~options.do_preprocess_section_list;
h.cb_nopreprocess.Layout.Row = 8;
h.cb_nopreprocess.Layout.Column = [1 3];

return
end
