function validateDataConsistency(obj)
%validateDataConsistency 初期化時のデータ整合性検証
%   validateDataConsistency(obj) は、IdMapper初期化時に
%   各マッピング配列のサイズが整合しているか検証します。
%   これは初期化時のデータ検証であり、実行時の引数検証とは異なります。
%
%   エラー条件:
%     IdMapper:EmptyData - 必須データが空
%     IdMapper:InconsistentData - 配列サイズ不整合
%
%   参考:
%     IdMapper

% 基準となる断面数
nsec = length(obj.idsec2stype_);

if nsec == 0
  error('IdMapper:EmptyData', ...
    'idsec2stypeが空です');
end

% idSectionListのサイズ確認
if length(obj.idSectionList_) ~= nsec
  error('IdMapper:InconsistentData', ...
    'idSectionListのサイズ(%d)がnsec(%d)と一致しません', ...
    length(obj.idSectionList_), nsec);
end

% idsec2srepのサイズ確認  
if length(obj.idsec2srep_) ~= nsec
  error('IdMapper:InconsistentData', ...
    'idsec2srepのサイズ(%d)がnsec(%d)と一致しません', ...
    length(obj.idsec2srep_), nsec);
end

% idme2secは部材数に依存するので、空でないことだけ確認
if isempty(obj.idme2sec_)
  warning('IdMapper:EmptyData', ...
    'idme2secが空です');
end

% idvar2vtypeは変数数に依存するので、空でないことだけ確認
if isempty(obj.idvar2vtype_)
  warning('IdMapper:EmptyData', ...
    'idvar2vtypeが空です');
end

return
end