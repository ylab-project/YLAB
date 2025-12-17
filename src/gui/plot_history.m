function plot_history(filepath, idtrial, idphase, iter_callback)
% PLOT_HISTORY 指定された履歴データの収束状況をプロットする

    if nargin < 4, iter_callback = []; end

    if isempty(filepath) || ~exist(filepath, 'file')
        uialert(uifigure, 'History file not found.', 'Error');
        return;
    end

    try
        %% データ読み込み
        m = matfile(filepath);
        vars = who(m);
        if ~ismember('history', vars)
            msgbox('History data not found.', 'Error', 'error');
            return;
        end
        
        %% 履歴取得
        try
            h_data = m.history(idtrial, idphase);
        catch
            msgbox('Specified Trial/Phase data does not exist.', 'Error', 'error');
            return;
        end
        
        if isempty(h_data) || ~isfield(h_data, 'iter')
            msgbox('Invalid history data.', 'Warning', 'warn');
            return;
        end
        
        %% データ抽出
        data.iter = h_data.iter;
        data.cost = [];
        
        if isfield(h_data, 'fval'), data.cost = h_data.fval;
        elseif isfield(h_data, 'cost'), data.cost = h_data.cost;
        elseif isfield(h_data, 'penalty'), data.cost = h_data.penalty;
        end
        
        % Violation Data
        data.vio = [];
        data.vio_dim = 2;
        
        if isfield(h_data, 'vio') && ~isempty(h_data.vio)
            v = h_data.vio;
            n_iter = length(data.iter);
            [r, c] = size(v);
            dim = 2;
            if c == n_iter && r ~= n_iter, dim = 1; end
            data.vio = v;
            data.vio_dim = dim;
        end
        
        %% グラフウィンドウ制御
        fig_tag = 'YLAB_History_Plot';
        fig = findobj('Type', 'figure', 'Tag', fig_tag);
        
        items = {'繰返し数', 'コスト関数値'};
        if ~isempty(data.vio)
            items{end+1} = '最大違反量';
        end
        
        if isempty(fig)
            % 新規作成
            fig_name = sprintf('History: Trial %d, Phase %d', idtrial, idphase);
            fig = figure('Name', fig_name, 'NumberTitle', 'off', 'Tag', fig_tag);
            
            ax = axes('Parent', fig, 'Position', [0.13 0.2 0.8 0.7]);
            
            % X-Axis Dropdown (Bottom-Right)
            uicontrol('Parent', fig, 'Style', 'text', 'String', 'X:', ...
                'Units', 'normalized', 'Position', [0.62 0.06 0.05 0.04], ...
                'HorizontalAlignment', 'right');
            dd_x = uicontrol('Parent', fig, 'Style', 'popupmenu', ...
                'String', items, 'Value', 1, ...
                'Units', 'normalized', 'Position', [0.68 0.06 0.25 0.05]);
                
            % Y-Axis Dropdown (Top-Left)
            uicontrol('Parent', fig, 'Style', 'text', 'String', 'Y:', ...
                'Units', 'normalized', 'Position', [0.07 0.93 0.05 0.04], ...
                'HorizontalAlignment', 'right');
            dd_y = uicontrol('Parent', fig, 'Style', 'popupmenu', ...
                'String', items, 'Value', 2, ...
                'Units', 'normalized', 'Position', [0.13 0.93 0.25 0.05]);
            
            handles.ax = ax;
            handles.dd_x = dd_x;
            handles.dd_y = dd_y;
            fig.UserData = handles;
            
        else
            % 既存再利用
            figure(fig);
            fig.Name = sprintf('History: Trial %d, Phase %d', idtrial, idphase);
            handles = fig.UserData;
            ax = handles.ax;
            dd_x = handles.dd_x;
            dd_y = handles.dd_y;
            
            % 選択維持ロジック
            old_items_x = dd_x.String;
            if ~iscell(old_items_x), old_items_x = {old_items_x}; end
            old_val_x = dd_x.Value;
            target_x = '繰返し数';
            if old_val_x <= length(old_items_x), target_x = old_items_x{old_val_x}; end
            
            old_items_y = dd_y.String;
            if ~iscell(old_items_y), old_items_y = {old_items_y}; end
            old_val_y = dd_y.Value;
            target_y = 'コスト関数値';
            if old_val_y <= length(old_items_y), target_y = old_items_y{old_val_y}; end
            
            % Items更新
            dd_x.String = items;
            dd_y.String = items;
            
            % Value復元
            idx_x = find(strcmp(items, target_x), 1);
            if isempty(idx_x), idx_x = 1; end
            dd_x.Value = idx_x;
            
            idx_y = find(strcmp(items, target_y), 1);
            if isempty(idx_y), idx_y = min(2, length(items)); end
            dd_y.Value = idx_y;
        end
        
        % Callback closure
        update_func = @(s,e) update_plot_xy(dd_x, dd_y, ax, data, items, iter_callback);
        dd_x.Callback = update_func;
        dd_y.Callback = update_func;
        
        % Initial Plot
        update_func([], []);
        
    catch ME
        errordlg(['Plotting failed: ' ME.message], 'Error');
    end
end

function update_plot_xy(dd_x, dd_y, ax, data, items, iter_callback)
    idx_x = dd_x.Value;
    idx_y = dd_y.Value;
    
    if idx_x > length(items), idx_x = 1; end
    if idx_y > length(items), idx_y = 1; end
    
    item_x = items{idx_x};
    item_y = items{idx_y};
    
    x = get_data_by_name(data, item_x);
    y = get_data_by_name(data, item_y);
    
    if isempty(x) || isempty(y)
        cla(ax); title(ax, 'No Data'); return;
    end
    
    % Plot style
    if strcmp(item_x, '繰返し数')
        line_style = '-o';
    else
        line_style = 'o';
    end
    
    plot(ax, x, y, line_style, 'LineWidth', 1.5, 'MarkerSize', 4);
    grid(ax, 'on');
    xlabel(ax, item_x);
    ylabel(ax, item_y);
    title(ax, '履歴プロット');
    
    % Data Cursor
    dcm = datacursormode(ax.Parent);
    set(dcm, 'Enable', 'on', 'UpdateFcn', @(obj,evt) my_datatip(obj,evt,iter_callback,data));
    
    % Ensure figure stays on top
    figure(ax.Parent);
end

function txt = my_datatip(~, event, callback, data)
    pos = event.Position;
    x_val = pos(1);
    y_val = pos(2);
    
    % Get Iteration from DataIndex
    if isprop(event, 'DataIndex')
        idx = event.DataIndex;
        if idx > 0 && idx <= length(data.iter)
            iter = data.iter(idx);
            
            if ~isempty(callback)
                try
                    callback(iter);
                catch
                end
            end
            
            txt = {sprintf('Iter: %d', iter), sprintf('X: %g', x_val), sprintf('Y: %g', y_val)};
            return;
        end
    end
    
    txt = {sprintf('X: %g', x_val), sprintf('Y: %g', y_val)};
end

function val = get_data_by_name(data, name)
    switch name
        case '繰返し数'
            val = data.iter;
        case 'コスト関数値'
            val = data.cost;
        case '最大違反量'
            if ~isempty(data.vio)
                val = max(max(data.vio, 0), [], data.vio_dim);
                if isrow(val)
                    val = val';
                end
            else
                val = [];
            end
        otherwise
            val = [];
    end
end
