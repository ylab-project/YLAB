function pool = start_parpool(maxRetries)
%start_parpool - リトライ付きで並列プールを起動
%
%   pool = start_parpool(maxRetries) は、
%   並列プール（parpool）の起動を試行し、失敗時は
%   残存プールを削除して再試行する。
%
%   入力引数:
%     maxRetries - 最大リトライ回数 (既定値: 3)
%
%   出力引数:
%     pool - 起動した並列プールオブジェクト
%
%   備考:
%     - 既にプールが存在する場合はそのまま返す
%     - 全リトライ失敗時は throw_err で
%       YLAB:Parallel:ParpoolFailed エラーを発行

  if nargin < 1
    maxRetries = 3;
  end

  pool = gcp('nocreate');
  if ~isempty(pool)
    return;
  end

  for attempt = 1:maxRetries
    try
      pool = parpool;
      return;
    catch ME
      if attempt < maxRetries
        delete(gcp('nocreate'));
        pause(2);
        fprintf( ...
          'Parpool failed. Retrying (%d/%d)\n', ...
          attempt, maxRetries);
      else
        throw_err('Env', 'ParpoolFailed', ...
          ME.message);
      end
    end
  end

  return;
end
