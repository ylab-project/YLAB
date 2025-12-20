function [action, options, target_output] = show_settings_dialog(options)
% SHOW_SETTINGS_DIALOG 設定変更ダイアログを表示する
%
%   [action, options, target_output] = show_settings_dialog(options)
%
%   Input:
%       options - 現在のCommonOptionオブジェクト
%
%   Output:
%       action - ユーザーの選択アクション
%           'continue' : 現在のMATLABセッションで続行 (Run)
%           'exit'     : 終了 (EXE実行、スクリプト作成、キャンセル含む)
%       mod_options - 更新されたoptionsオブジェクト
%       target_output_file - (continueの場合) 最終的にコピーすべきターゲットパス
%                            コピー不要な場合は空文字

%% 戻り値の初期化
action = 'exit';
mod_options = options;
target_output_file = '';

% ターゲットパス（本来の出力先）の保持
original_output_file = options.outputfile;

%% UIFigureの作成
dlg_width = 600;
dlg_height = 480;
screen_size = get(0, 'ScreenSize');
x_pos = (screen_size(3) - dlg_width) / 2;
y_pos = (screen_size(4) - dlg_height) / 2;

fig = uifigure('Name', 'YLAB Settings', ...
  'Position', [x_pos, y_pos, dlg_width, dlg_height], ...
  'WindowStyle', 'normal', ...
  'Resize', 'off');

%% レイアウト構築
main_gl = uigridlayout(fig, [2, 1]);
main_gl.RowHeight = {'1x', 40};
main_gl.Padding = [10 10 10 10];

tg = uitabgroup(main_gl);

% タブ構築 (外部関数)
h_gen = build_general_tab(tg, options);
h_hist = build_history_tab(tg, options);
h_lim = build_limits_tab(tg, options);

%% ボタンエリア
pnl_btns = uipanel(main_gl, 'BorderType', 'none');
pnl_btns.Layout.Row = 2;
bg_btns = uigridlayout(pnl_btns, [1, 6]);
bg_btns.ColumnWidth = {'1x', 100, 100, 100, 100, 80};

uilabel(bg_btns, 'Text', '');

uibutton(bg_btns, 'Text', '実行', ...
  'ButtonPushedFcn', @on_run_current, ...
  'Tooltip', '現在のMATLABセッションで実行します');

uibutton(bg_btns, 'Text', 'batファイル生成', ...
  'ButtonPushedFcn', @on_create_batch, ...
  'Tooltip', '実行用バッチファイルを作成します');

uibutton(bg_btns, 'Text', 'm-script生成', ...
  'ButtonPushedFcn', @on_create_mscript, ...
  'Tooltip', '実行用MATLABスクリプトを作成します');

uibutton(bg_btns, 'Text', 'フォルダを開く', ...
  'ButtonPushedFcn', @on_open_folder, ...
  'Tooltip', 'Input Fileのフォルダを開きます');

uibutton(bg_btns, 'Text', '終了', ...
  'ButtonPushedFcn', @on_cancel);

%% コールバック登録
h_gen.edt_input.ValueChangedFcn = @on_input_changed;
h_gen.btn_input.ButtonPushedFcn = @on_input_browse;
h_gen.btn_output.ButtonPushedFcn = @on_output_browse;

h_hist.edt_matfile.ValueChangedFcn = @(s,e) analyze_matfile_ui(s.Value);
h_hist.btn_browse.ButtonPushedFcn = @on_matfile_browse;
h_hist.btn_plot.ButtonPushedFcn = @on_history_plot;

%% 待機
uiwait(fig);

% 出力変数の確定
options = mod_options;
target_output = target_output_file;


%% コールバック関数実装

  function on_input_browse(~, ~)
    current_val = h_gen.edt_input.Value;
    start_path = pwd;
    if ~isempty(current_val)
      if exist(current_val, 'file')
        d = dir(current_val); start_path = d(1).folder;
      else
        p = fileparts(current_val);
        if ~isempty(p) && exist(p, 'dir'), start_path = p; end
      end
    end
    if ispref('YLAB', 'LastDevPath')
      last_path = getpref('YLAB', 'LastDevPath');
      if exist(last_path, 'dir'), start_path = last_path; end
    end

    [file, path] = uigetfile(fullfile(start_path, '*.csv'));
    if file ~= 0
      new_input = fullfile(path, file);
      h_gen.edt_input.Value = new_input;
      if isempty(h_gen.edt_output.Value)
        h_gen.edt_output.Value = generate_output_path(new_input);
      end
      setpref('YLAB', 'LastDevPath', path);
    end
  end

  function on_input_changed(~, ~)
    % No action
  end

  function on_output_browse(~, ~)
    [file, path] = uiputfile('*.csv', 'Select Output File', h_gen.edt_output.Value);
    if file ~= 0
      h_gen.edt_output.Value = fullfile(path, file);
    end
  end

  function on_matfile_browse(~, ~)
    start_path = '';
    out_val = h_gen.edt_output.Value;
    if ~isempty(out_val)
      p_out = fileparts(out_val);
      if exist(p_out, 'dir'), start_path = p_out; end
    end

    filter = '*.mat';
    if ~isempty(start_path), filter = fullfile(start_path, '*.mat'); end

    [f, p] = uigetfile(filter, 'Select History File');
    if f ~= 0
      fullpath = fullfile(p, f);
      h_hist.edt_matfile.Value = fullpath;
      analyze_matfile_ui(fullpath);
    end
  end

  function analyze_matfile_ui(filepath)
    info = analyze_history(filepath);
    h_hist.lbl_info.Text = info.message;

    if info.isValid
      h_hist.lbl_info.FontColor = [0 0.6 0];

      t_items = cell(1, info.n_trial);
      for i=1:info.n_trial, t_items{i} = sprintf('Trial %d', i); end
      h_hist.dd_res_trial.Items = t_items;
      h_hist.dd_res_trial.Value = t_items{end};

      p_items = cell(1, info.n_phase);
      for i=1:info.n_phase, p_items{i} = sprintf('Phase %d', i); end
      h_hist.dd_res_phase.Items = p_items;
      h_hist.dd_res_phase.Value = p_items{end};

      if isfield(info, 'last_iter')
        h_hist.sef_res_iter.Value = info.last_iter;
      end

      h_hist.dd_res_trial.Enable = 'on';
      h_hist.dd_res_phase.Enable = 'on';
      h_hist.sef_res_iter.Enable = 'on';
      h_hist.btn_plot.Enable = 'on';
    else
      h_hist.lbl_info.FontColor = [0.8 0 0];
      h_hist.dd_res_trial.Enable = 'off';
      h_hist.dd_res_phase.Enable = 'off';
      h_hist.sef_res_iter.Enable = 'off';
      h_hist.btn_plot.Enable = 'off';
    end
  end

  function on_history_plot(~, ~)
    mat_file = h_hist.edt_matfile.Value;
    if isempty(mat_file), return; end

    t_str = h_hist.dd_res_trial.Value;
    if isempty(t_str), return; end
    id_t = sscanf(t_str, 'Trial %d');

    p_str = h_hist.dd_res_phase.Value;
    if isempty(p_str), return; end
    id_p = sscanf(p_str, 'Phase %d');

    plot_history(mat_file, id_t, id_p, @update_iter_from_plot);
  end

  function update_iter_from_plot(new_iter)
    h_hist.sef_res_iter.Value = new_iter;
  end

  function on_run_current(~, ~)
    update_options();
    if h_gen.cb_autocopy.Value
      target_output_file = original_output_file;
    else
      target_output_file = '';
    end
    action = 'continue';
    delete(fig);
  end

  function on_create_mscript(~, ~)
    update_options();

    try
      [p, ~, ~] = fileparts(mod_options.inputfile);

      if isempty(p), p = pwd; end

      current_path = '';
      if ispref('YLAB', 'DevRootPath'), current_path = getpref('YLAB', 'DevRootPath'); end
      if isempty(current_path) || ~exist(fullfile(current_path, 'YLAB.m'), 'file')
        p_ylab = which('YLAB');
        if ~isempty(p_ylab), current_path = fileparts(p_ylab); else, current_path = pwd; end
      end

      msg = sprintf('YLAB Source Path:\n%s', current_path);
      selection = uiconfirm(fig, msg, 'Confirm YLAB Path', ...
        'Options', {'OK', 'Change', 'Cancel'}, 'DefaultOption', 'OK', 'CancelOption', 'Cancel');

      switch selection
        case 'OK'
          approot = current_path;
        case 'Cancel'
          return;
      end
      if strcmp(selection, 'Change')
        sel_path = uigetdir(current_path, 'Select YLAB "main" source directory');
        if sel_path == 0, return; end
        approot = sel_path;
        setpref('YLAB', 'DevRootPath', approot);
      end
      if ~exist(fullfile(approot, 'YLAB.m'), 'file')
        uialert(fig, ['YLAB.m not found in: ' approot], 'Error'); return;
      end

      script_path = create_mscript(mod_options, approot, p, original_output_file, h_gen.cb_autocopy.Value);

      selection = uiconfirm(fig, ['M-Script created: ' script_path], 'Success', ...
        'Icon', 'success', 'Options', {'フォルダを開く', 'OK'});
      if strcmp(selection, 'フォルダを開く')
        system(['explorer "' strrep(p, '/', '\') '"']);
      end
    catch ME
      uialert(fig, ['Failed to create M-Script: ' ME.message], 'Error');
    end
  end

  function on_create_batch(~, ~)
    update_options();
    try
      [input_dir, ~, ~] = fileparts(mod_options.inputfile);
      if isempty(input_dir), input_dir = pwd; end
      bat_path = create_batfile(mod_options, input_dir);
      uiconfirm(fig, ['Batch file created: ' bat_path], 'Success', 'Icon', 'success', 'Options', {'OK'});
    catch ME
      uialert(fig, ['Failed to create batch file: ' ME.message], 'Error');
    end
  end

  function on_open_folder(~, ~)
    input_path = h_gen.edt_input.Value;
    if isempty(input_path)
      uialert(fig, 'Input Fileが指定されていません', 'Error');
      return;
    end
    folder_path = fileparts(input_path);
    if isempty(folder_path) || ~exist(folder_path, 'dir')
      uialert(fig, 'フォルダが見つかりません', 'Error');
      return;
    end
    system(['explorer "' strrep(folder_path, '/', '\') '"']);
  end
  function on_cancel(~, ~)
    action = 'exit';
    delete(fig);
  end

  function update_options()
    % General
    mod_options.inputfile = h_gen.edt_input.Value;
    mod_options.outputfile = h_gen.edt_output.Value;
    mod_options.exemode = h_gen.dd_exemode.Value;
    mod_options.do_writeout_pdf = h_gen.cb_pdf.Value;

    % History
    mod_options.matfile = h_hist.edt_matfile.Value;
    if strcmp(h_hist.dd_res_trial.Enable, 'on')
      t_str = h_hist.dd_res_trial.Value;
      if ~isempty(t_str), mod_options.idtrial_resume = sscanf(t_str, 'Trial %d'); end
      p_str = h_hist.dd_res_phase.Value;
      if ~isempty(p_str), mod_options.idphase_resume = sscanf(p_str, 'Phase %d'); end
      mod_options.iter_resume = h_hist.sef_res_iter.Value;
    end

    % Limits
    mod_options.maxphase = h_lim.sef_maxphase.Value;
    mod_options.maxiter_in_LS = h_lim.sef_maxiter.Value;
    mod_options.idtrial = h_lim.sef_trialid.Value;

    setpref('YLAB', 'LastInputFile', mod_options.inputfile);
  end

  function out_path = generate_output_path(in_path)
    if isempty(in_path), out_path = ''; return; end
    [p, n, ~] = fileparts(in_path);
    out_dir = fullfile(p, 'out');
    out_path = fullfile(out_dir, [n '_output.csv']);
  end
end
