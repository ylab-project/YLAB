function info = analyze_history(filepath)
% ANALYZE_HISTORY 履歴ファイル(.mat)を解析し、情報を返す
%
%   info = analyze_history(filepath)
%
%   Output:
%       info.isValid - 有効な履歴ファイルか
%       info.n_trial - 試行数
%       info.n_phase - フェーズ数
%       info.message - ステータスメッセージ

info = struct('isValid', false, 'n_trial', 0, 'n_phase', 0, 'message', '');

if isempty(filepath) || ~exist(filepath, 'file')
  info.message = 'File not found.';
  return;
end

try
  m = matfile(filepath);
  vars = who(m);

  if ismember('fval', vars)
    fv = m.fval;
    [nt, np] = size(fv);
    if nt > 0 && np > 0
      info.isValid = true;
      info.n_trial = nt;
      info.n_phase = np;

      % Get last iteration
      try
        h_last = m.history(nt, np);
        if isfield(h_last, 'iter') && ~isempty(h_last.iter)
          info.last_iter = h_last.iter(end);
        else
          info.last_iter = 0;
        end
      catch
        info.last_iter = 0;
      end

      info.message = sprintf('Detected: %d Trials, %d Phases', nt, np);
    end
  else
    info.message = 'Invalid history file (no fval).';
  end
catch ME
  info.message = ['Error: ' ME.message];
end
end
