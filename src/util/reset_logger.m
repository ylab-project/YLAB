function reset_logger()
%reset_logger - groot appdata のロガーを破棄して作り直す
%
%   reset_logger() は、groot appdata に保持したロガーを削除し、
%   無効ロガーを新規生成して設定する。新しい診断実行を白紙から
%   始めるとき、およびテストの setup で使う。
%
%   入力引数・出力引数はなし。

setappdata(groot, logger_appdata_key(), AppLogger());

return
end
