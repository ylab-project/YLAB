function logger = get_logger()
%get_logger - groot appdata からロガーを取得する
%
%   logger = get_logger() は、groot の appdata に保持したロガーを
%   返す。未生成のときは無効ロガー(collect=false)を返すため、
%   呼び出し側は存在確認なしに record を呼べる。
%
%   出力引数:
%     logger - AppLogger インスタンス

key = logger_appdata_key();
if isappdata(groot, key)
  logger = getappdata(groot, key);
else
  logger = AppLogger();
end

return
end
