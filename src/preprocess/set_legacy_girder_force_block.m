function element_force = set_legacy_girder_force_block(dbc, com)
%set_legacy_girder_force_block - 従来梁要素荷重の値と継続指定を読む
%
%   element_force = set_legacy_girder_force_block(dbc, com) は、
%   梁要素荷重の値、荷重ケース、配置指定と継続順を正規化する。
%   継続行の補完と検証を行い、部材の検索はparse側に任せる。
%
%   入力引数:
%     dbc - 入力データブロックの読込オブジェクト
%     com - 荷重ケースを持つ共通データ
%
%   出力引数:
%     element_force - 未解決の配置指定と荷重値を持つテーブル

data = dbc.get_data_block('梁要素荷重');
n = size(data, 1);
csv_row = dbc.origrows(dbc.get_data_block_rows('梁要素荷重'));
[is_continued, data] = read_continuation_flag(data, n);
selector = cell(n, 4);
ilc = zeros(n, 1);
ar = zeros(n, 12);
M0 = zeros(n, 1);
block_name = repmat({'梁要素荷重'}, n, 1);
iblock = ones(n, 1);
irow = (1:n)';
for ir = 1:n
  ilc(ir) = find(matches(com.loadcase.name, tochar(data{ir, 1})));
  selector(ir, :) = cellfun(@tochar, data(ir, 2:5), ...
    'UniformOutput', false);
  ar(ir, :) = cell2mat(data(ir, 6:17));
  M0(ir) = data{ir, 18};
end
element_force = table(selector, is_continued, ilc, ar, M0, ...
  block_name, iblock, irow, csv_row);

return
end

function [is_continued, data] = read_continuation_flag(data, n)
%read_continuation_flag - 継続フラグの読み取りと基本検証
%
%   [is_continued, data] = read_continuation_flag(data, n) は、
%   梁要素荷重データの19列目から継続フラグを読み取り、
%   基本検証と継続行の列1-5補完を行う。
%
%   入力引数:
%     data - 梁要素荷重のcell配列 [n×mc]
%     n    - データ行数
%
%   出力引数:
%     is_continued - 継続フラグ [n×1 logical]
%     data         - 列1-5補完後のcell配列

% 19列目の読み取り（省略時はfalse）
mc = size(data, 2);
is_continued = false(n, 1);
if mc >= 19
  is_continued = matches(string(data(:, 19)), 'T');
end

% 基本検証
for i = 1:n
  if ~is_continued(i), continue, end
  if i == n
    throw_warn('Input', 'GirderForceContLastRow', i);
    is_continued(i) = false;
    continue
  end
  % 継続行の列1-5は空欄が仕様。非空なら警告
  if any(~ismissing(string(data(i+1, 1:5))))
    throw_warn('Input', 'GirderForceContRowNotEmpty', i+1);
  end
end

% 継続行の列1-5を親行からコピー
for i = 1:n
  if is_continued(i)
    data(i+1, 1:5) = data(i, 1:5);
  end
end

return
end
