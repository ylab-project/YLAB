function key = logger_appdata_key()
%logger_appdata_key - ロガー保持用 appdata キーを返す
%
%   key = logger_appdata_key() は、groot appdata でロガーを識別する
%   一意なキー文字列を返す。取得・生成・破棄で共通に参照する。
%
%   出力引数:
%     key - appdata キー文字列 (char)

key = 'YLAB_Logger';

return
end
