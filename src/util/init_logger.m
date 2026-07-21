function init_logger(file_path)
%init_logger - ロガーを今回実行の設定へ再構成する
%
%   init_logger(file_path) は、groot appdata のロガーの収集・保存
%   フラグと保存先を今回実行の値へ再構成する。file_path が非空なら
%   収集＋保存を有効化し、空なら無効ロガーにする。蓄積済みの記録は
%   保持する。ロガー未生成なら新規生成する。毎回呼ぶ前提であり、
%   「未生成時のみ」にはしない（前実行の設定が残ると次実行で診断が
%   収集されないため）。
%
%   入力引数:
%     file_path - 診断保存先 MAT パス (char)。空なら無効化

logger = get_logger();
enabled = ~isempty(file_path);
logger.collect = enabled;
logger.persist = enabled;
logger.file_path = file_path;
setappdata(groot, logger_appdata_key(), logger);

return
end
