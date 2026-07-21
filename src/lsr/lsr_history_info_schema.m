function schema = lsr_history_info_schema()
%lsr_history_info_schema - LSR付加記録の反復列スキーマを返す
%
%   schema = lsr_history_info_schema() は、
%   history.info.<手法>.<カテゴリ>へ蓄積する反復列を返す。
%
%   出力引数:
%     schema - method、category、fieldsを持つ構造体配列

schema(1).method = 'lsr';
schema(1).category = 'timing';
schema(1).fields = {'neighborhood', 'correction', 'evaluation'};
schema(2).method = 'lsfr';
schema(2).category = 'selection';
schema(2).fields = {'algorithm', 'error_percent', 'depth'};

return
end
