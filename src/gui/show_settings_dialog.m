function [action, options] = show_settings_dialog(options)
%show_settings_dialog - 計算設定または既存CSVの返却を受け付ける
%
%   [action, options] = show_settings_dialog(options) は、設定画面を
%   表示する。COPYは画面内でコピーを完了してから終了する。
%
%   入力引数:
%     options - 起動時のCommonOption
%
%   出力引数:
%     action  - 計算を続ける'continue'、画面を終了する'exit'
%     options - 計算実行時に更新したCommonOption

%% 戻り値の初期化
action = 'exit';
mod_options = options;

% ターゲットパス（本来の出力先）の保持
original_output_file = options.outputfile;

%% UIFigureの作成
dlg_width = 600;
dlg_height = 480;
screen_size = get(0, 'ScreenSize');
x_pos = (screen_size(3) - dlg_width) / 2;
y_pos = (screen_size(4) - dlg_height) / 2;

fig = uifigure('Name', 'YLAB Settings', 'Position', ...
  [x_pos, y_pos, dlg_width, dlg_height], 'WindowStyle', 'normal', ...
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

% 実行ボタンの表示と有効状態はon_exemode_changedで決める
btn_run = uibutton(bg_btns, 'Text', '実行', 'ButtonPushedFcn', ...
  @on_run_current);

% batファイル生成は配布実行時のみ有効（EXEの場所が確定する）
bat_enable = ~isempty(options.exepath);
if bat_enable
  bat_tooltip = '実行用バッチファイルを作成します';
else
  bat_tooltip = ['EXEの場所が確定しないため使用できません。' ...
    'MATLAB実行時は m-script 生成を使用します'];
end

btn_batch = uibutton(bg_btns, 'Text', 'batファイル生成', ...
  'ButtonPushedFcn', @on_create_batch, 'Tooltip', bat_tooltip);

btn_mscript = uibutton(bg_btns, 'Text', 'm-script生成', ...
  'ButtonPushedFcn', @on_create_mscript, 'Tooltip', ...
  '実行用MATLABスクリプトを作成します');

uibutton(bg_btns, 'Text', 'フォルダを開く', 'ButtonPushedFcn', ...
  @on_open_folder, 'Tooltip', 'Input Fileのフォルダを開きます');

uibutton(bg_btns, 'Text', '終了', 'ButtonPushedFcn', @on_cancel);

%% コールバック登録
h_gen.btn_input.ButtonPushedFcn = @on_input_browse;
h_gen.btn_output.ButtonPushedFcn = @on_output_browse;
h_gen.dd_exemode.ValueChangedFcn = @on_exemode_changed;
on_exemode_changed(h_gen.dd_exemode, []);

h_hist.edt_matfile.ValueChangedFcn = @(s,e) analyze_matfile_ui(s.Value);
h_hist.btn_browse.ButtonPushedFcn = @on_matfile_browse;
h_hist.btn_plot.ButtonPushedFcn = @on_history_plot;

%% 待機
uiwait(fig);

% 出力変数の確定
options = mod_options;

return

%% コールバック関数実装

  function on_exemode_changed(source, ~)
  %on_exemode_changed - COPYと計算に応じて操作欄を切り替える
  %
  %   on_exemode_changed(source, event) は、設定値を保ったまま
  %   操作欄の有効状態とボタンの表示を切り替える。
  %
  %   入力引数:
  %     source - ExeModeドロップダウン
  %     event  - 未使用のUIイベント
  %
  %   出力引数:
  %     なし

    is_copy = strcmp(source.Value, 'COPY');
    if is_copy
      h_gen.lbl_output.Text = 'コピー元CSV:';
      btn_run.Text = 'コピー';
      btn_run.Tooltip = '既存CSVを返却先へコピーして終了します';
    else
      h_gen.lbl_output.Text = 'Output File:';
      btn_run.Text = '実行';
      btn_run.Tooltip = '現在のMATLABセッションで実行します';
    end
    h_gen.edt_input.Enable = ~is_copy;
    h_gen.btn_input.Enable = ~is_copy;
    h_gen.dd_algorithm.Enable = strcmp(source.Value, 'OPT');
    h_gen.edt_num_workers.Enable = strcmp(source.Value, 'OPT') ...
      && options.do_parallel;
    h_gen.cb_pdf.Enable = ~is_copy;
    h_gen.cb_nopreprocess.Enable = ~is_copy;
    h_hist.edt_matfile.Enable = ~is_copy;
    h_hist.btn_browse.Enable = ~is_copy;
    h_lim.sef_maxphase.Enable = ~is_copy;
    h_lim.sef_maxiter.Enable = ~is_copy;
    h_lim.sef_trialid.Enable = ~is_copy;
    % 読込済みの選択肢から再開欄の有効状態を戻す。
    resume_on = ~is_copy && ~strcmp(h_hist.dd_res_trial.Value, '-');
    h_hist.dd_res_trial.Enable = resume_on;
    h_hist.dd_res_phase.Enable = resume_on;
    h_hist.sef_res_iter.Enable = resume_on;
    h_hist.btn_plot.Enable = resume_on;
    btn_run.Enable = ~is_copy || ~isempty(original_output_file);
    btn_batch.Enable = ~is_copy && bat_enable;
    btn_mscript.Enable = ~is_copy;

    return
  end

  function on_input_browse(~, ~)
  %on_input_browse - 入力CSVを選択する
  %
  %   on_input_browse(source, event) は、入力CSVと参照先を更新する。
  %
  %   入力引数:
  %     source, event - 未使用のUIイベント引数
  %
  %   出力引数:
  %     なし

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

    return
  end

  function on_output_browse(~, ~)
  %on_output_browse - 実行内容に応じてCSVを選択する
  %
  %   on_output_browse(source, event) は、COPYで既存CSVを選び、
  %   通常モードでは出力先を選ぶ。
  %
  %   入力引数:
  %     source, event - 未使用のUIイベント引数
  %
  %   出力引数:
  %     なし

    if strcmp(h_gen.dd_exemode.Value, 'COPY')
      [file, path] = uigetfile('*.csv', 'コピー元CSVを選択', ...
        h_gen.edt_output.Value);
    else
      [file, path] = uiputfile('*.csv', '出力先CSVを選択', ...
        h_gen.edt_output.Value);
    end
    if file ~= 0
      h_gen.edt_output.Value = fullfile(path, file);
    end

    return
  end

  function on_matfile_browse(~, ~)
  %on_matfile_browse - 履歴ファイルを選択する
  %
  %   on_matfile_browse(source, event) は、選択した履歴を表示する。
  %
  %   入力引数:
  %     source, event - 未使用のUIイベント引数
  %
  %   出力引数:
  %     なし

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

    return
  end

  function analyze_matfile_ui(filepath)
  %analyze_matfile_ui - 履歴の選択肢と説明を更新する
  %
  %   analyze_matfile_ui(filepath) は、履歴を調べて再開欄を設定する。
  %
  %   入力引数:
  %     filepath - 読み込む履歴ファイルのパス
  %
  %   出力引数:
  %     なし

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

    else
      h_hist.lbl_info.FontColor = [0.8 0 0];
      h_hist.dd_res_trial.Items = {'-'};
      h_hist.dd_res_phase.Items = {'-'};
    end
    on_exemode_changed(h_gen.dd_exemode, []);

    return
  end

  function on_history_plot(~, ~)
  %on_history_plot - 選択した履歴のグラフを開く
  %
  %   on_history_plot(source, event) は、試行とPhaseの履歴を描く。
  %
  %   入力引数:
  %     source, event - 未使用のUIイベント引数
  %
  %   出力引数:
  %     なし

    mat_file = h_hist.edt_matfile.Value;
    if isempty(mat_file), return; end

    t_str = h_hist.dd_res_trial.Value;
    if isempty(t_str), return; end
    id_t = sscanf(t_str, 'Trial %d');

    p_str = h_hist.dd_res_phase.Value;
    if isempty(p_str), return; end
    id_p = sscanf(p_str, 'Phase %d');

    plot_history(mat_file, id_t, id_p, @update_iter_from_plot);

    return
  end

  function update_iter_from_plot(new_iter)
  %update_iter_from_plot - グラフで選んだ反復を設定する
  %
  %   update_iter_from_plot(new_iter) は、再開反復を更新する。
  %
  %   入力引数:
  %     new_iter - グラフで選択した反復番号
  %
  %   出力引数:
  %     なし

    h_hist.sef_res_iter.Value = new_iter;

    return
  end

  function on_run_current(~, ~)
  %on_run_current - 指定操作を実行して画面を終了する
  %
  %   on_run_current(source, event) は、COPYでは既存CSVをコピーし、
  %   計算用の設定更新を行わずに戻る。失敗時は画面に留まる。
  %
  %   入力引数:
  %     source, event - 未使用のUIイベント引数
  %
  %   出力引数:
  %     なし

    if strcmp(h_gen.dd_exemode.Value, 'COPY')
      % 単一ファイルの返却を保証し、フォルダへのコピーを防ぐ。
      if ~isfile(h_gen.edt_output.Value) || ...
          contains(h_gen.edt_output.Value, {'*', '?'})
        uialert(fig, '既存のコピー元CSVを指定してください', ...
          'コピーできません');
        return
      end
      if isfolder(original_output_file) || ...
          endsWith(original_output_file, {'/', '\'}) || ...
          contains(original_output_file, {'*', '?'})
        uialert(fig, '起動時の返却先がファイルパスではありません', ...
          'コピーできません');
        return
      end

      % 同一ファイルや書込不可もcopyfileの成否で判断する。
      [status, msg] = copyfile(h_gen.edt_output.Value, ...
        original_output_file);
      if ~status
        uialert(fig, msg, 'コピーに失敗しました');
        return
      end
    else
      if ~update_options()
        return
      end
      action = 'continue';
    end
    delete(fig);

    return
  end

  function on_create_mscript(~, ~)
  %on_create_mscript - 現在の設定でスクリプトを生成する
  %
  %   on_create_mscript(source, event) は、計算用のmファイルを作る。
  %
  %   入力引数:
  %     source, event - 未使用のUIイベント引数
  %
  %   出力引数:
  %     なし

    if ~update_options()
      return
    end

    try
      [p, ~, ~] = fileparts(mod_options.inputfile);

      if isempty(p), p = pwd; end

      current_path = '';
      if ispref('YLAB', 'DevRootPath')
        current_path = getpref('YLAB', 'DevRootPath');
      end
      if isempty(current_path) || ~exist(fullfile(current_path, ...
          'YLAB.m'), 'file')
        p_ylab = get_ylab_mfile_path();
        if ~isempty(p_ylab)
          current_path = fileparts(p_ylab);
        else
          current_path = pwd;
        end
      end

      msg = sprintf('YLAB Source Path:\n%s', current_path);
      selection = uiconfirm(fig, msg, 'YLABの場所の確認', ...
        'Options', {'OK', 'Change', 'Cancel'}, 'DefaultOption', ...
        'OK', 'CancelOption', 'Cancel');

      switch selection
        case 'OK'
          approot = current_path;
        case 'Cancel'
          return;
      end
      if strcmp(selection, 'Change')
        sel_path = uigetdir(current_path, ...
          'Select YLAB "main" source directory');
        if sel_path == 0, return; end
        approot = sel_path;
        setpref('YLAB', 'DevRootPath', approot);
      end
      if ~exist(fullfile(approot, 'YLAB.m'), 'file')
        uialert(fig, ['YLAB.m not found in: ' approot], 'エラー'); return;
      end

      script_path = create_mscript(mod_options, approot, p);

      selection = uiconfirm(fig, ['M-Script created: ' script_path], ...
        '作成完了', 'Options', {'フォルダを開く', 'OK'}, ...
        'Icon', 'success');
      if strcmp(selection, 'フォルダを開く')
        system(['explorer "' strrep(p, '/', '\') '"']);
      end
    catch ME
      uialert(fig, ['Failed to create M-Script: ' ME.message], 'エラー');
    end

    return
  end

  function on_create_batch(~, ~)
  %on_create_batch - 現在の設定でバッチを生成する
  %
  %   on_create_batch(source, event) は、EXE実行用バッチを作る。
  %
  %   入力引数:
  %     source, event - 未使用のUIイベント引数
  %
  %   出力引数:
  %     なし

    if ~update_options()
      return
    end
    try
      [input_dir, ~, ~] = fileparts(mod_options.inputfile);
      if isempty(input_dir), input_dir = pwd; end
      bat_path = create_batfile(mod_options, input_dir);
      uiconfirm(fig, ['Batch file created: ' bat_path], '作成完了', ...
        'Icon', 'success', 'Options', {'OK'});
    catch ME
      uialert(fig, ['Failed to create batch file: ' ME.message], 'エラー');
    end

    return
  end

  function on_open_folder(~, ~)
  %on_open_folder - 入力CSVのフォルダを開く
  %
  %   on_open_folder(source, event) は、入力先をExplorerで開く。
  %
  %   入力引数:
  %     source, event - 未使用のUIイベント引数
  %
  %   出力引数:
  %     なし

    input_path = h_gen.edt_input.Value;
    if isempty(input_path)
      uialert(fig, 'Input Fileが指定されていません', 'エラー');
      return;
    end
    folder_path = fileparts(input_path);
    if isempty(folder_path) || ~exist(folder_path, 'dir')
      uialert(fig, 'フォルダが見つかりません', 'エラー');
      return;
    end
    system(['explorer "' strrep(folder_path, '/', '\') '"']);

    return
  end

  function on_cancel(~, ~)
  %on_cancel - コピーや計算をせずに終了する
  %
  %   on_cancel(source, event) は、終了を通知して画面を閉じる。
  %
  %   入力引数:
  %     source, event - 未使用のUIイベント引数
  %
  %   出力引数:
  %     なし

    action = 'exit';
    delete(fig);

    return
  end

  function is_valid = update_options()
  %update_options - 画面から計算設定を取り込む
  %
  %   is_valid = update_options() は、設定を検証して取り込む。
  %   不正入力は画面で通知し、設定を更新せずにfalseを返す。
  %
  %   入力引数:
  %     なし
  %
  %   出力引数:
  %     is_valid - 設定を取り込めた場合はtrue
  %                （外側のmod_optionsを更新）

    % 空欄は並列プール起動時の既定値に従う
    is_valid = true;
    num_workers = strtrim(h_gen.edt_num_workers.Value);
    if strcmp(h_gen.dd_exemode.Value, 'OPT') && options.do_parallel ...
        && ~isempty(num_workers)
      [~, ~, is_valid] = parse_num_workers(num_workers);
      if ~is_valid
        uialert(fig, '並列数は正の整数または N% で指定してください', ...
          'エラー');
        return
      end
    end

    % 基本設定
    mod_options.inputfile = h_gen.edt_input.Value;
    mod_options.outputfile = h_gen.edt_output.Value;
    mod_options.exemode = h_gen.dd_exemode.Value;
    mod_options.algorithm = h_gen.dd_algorithm.Value;
    mod_options.num_workers = num_workers;
    mod_options.do_writeout_pdf = h_gen.cb_pdf.Value;
    mod_options.do_preprocess_section_list = ~h_gen.cb_nopreprocess.Value;

    % 履歴からの再開位置
    mod_options.matfile = h_hist.edt_matfile.Value;
    if strcmp(h_hist.dd_res_trial.Enable, 'on')
      t_str = h_hist.dd_res_trial.Value;
      if ~isempty(t_str)
        mod_options.idtrial_resume = sscanf(t_str, 'Trial %d');
      end
      p_str = h_hist.dd_res_phase.Value;
      if ~isempty(p_str)
        mod_options.idphase_resume = sscanf(p_str, 'Phase %d');
      end
      mod_options.iter_resume = h_hist.sef_res_iter.Value;
    end

    % 終了条件
    mod_options.maxphase = h_lim.sef_maxphase.Value;
    mod_options.maxiter_in_LS = h_lim.sef_maxiter.Value;
    mod_options.idtrial = h_lim.sef_trialid.Value;

    setpref('YLAB', 'LastInputFile', mod_options.inputfile);

    return
  end

  function out_path = generate_output_path(in_path)
  %generate_output_path - 入力CSVから既定の出力先を作る
  %
  %   out_path = generate_output_path(in_path) は、入力フォルダの
  %   out内に置く出力CSVのパスを返す。
  %
  %   入力引数:
  %     in_path - 入力CSVのパス
  %
  %   出力引数:
  %     out_path - 既定の出力CSVパス

    if isempty(in_path), out_path = ''; return; end
    [p, n, ~] = fileparts(in_path);
    out_dir = fullfile(p, 'out');
    out_path = fullfile(out_dir, [n '_output.csv']);

    return
  end
end
