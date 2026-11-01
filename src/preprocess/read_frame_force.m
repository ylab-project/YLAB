function com = read_frame_force(com, dbc)
%read_frame_force - 荷重の値と配置指定を検証・正規化する
%
%   com = read_frame_force(com, dbc) は、荷重に必要な入力だけを
%   com.force.inputへ格納する。部材・節点番号の解決と幾何に依存する
%   計算はparse_frame_forceで行い、入力全体やdbcは保持しない。
%
%   入力引数:
%     com - 荷重ケースを持つ共通データ
%     dbc - 架構読込時に生成した入力データブロックの読込オブジェクト
%
%   出力引数:
%     com - parseまでの一時的な荷重入力を持つ共通データ

blocks = dbc.get_data_blocks('節点荷重');
is_legacy = arrayfun(@is_legacy_nodal_force_block, blocks);
[force_input.legacy_nodal, force_input.issues] = ...
  set_legacy_nodal_force_block(blocks(is_legacy), com);
force_input.earthquake_position = set_earthquake_force_position_block(dbc);
force_input.additive_nodal = set_additive_nodal_force_block(dbc, com);
force_input.legacy_element = set_legacy_girder_force_block(dbc, com);
[force_input.element, issues] = set_element_force_block(dbc, com);
force_input.issues = [force_input.issues; issues];
[force_input.nodal, issues] = set_nodal_force_block(blocks(~is_legacy), ...
  dbc, com);
force_input.issues = [force_input.issues; issues];
[force_input.cantilever, force_input.cantilever_placement, issues] = ...
  set_cantilever_force_block(dbc, com);
force_input.issues = [force_input.issues; issues];
com.force.input = force_input;

return
end


function nodal_force = set_additive_nodal_force_block(dbc, com)
%set_additive_nodal_force_block - 追加節点荷重の値と配置指定を読む
%
%   nodal_force = set_additive_nodal_force_block(dbc, com) は、
%   追加節点荷重のケース・配置指定・6成分を入力順に保持する。
%   帳票非計上分の判定は作用先を解決するparse側で行う。
%
%   入力引数:
%     dbc - 入力データブロックの読込オブジェクト
%     com - 荷重ケースを持つ共通データ
%
%   出力引数:
%     nodal_force - 未解決の追加節点荷重テーブル

data = dbc.get_data_block('追加節点荷重');
n = size(data, 1);
selector = cell(n, 3);
ilc = zeros(n, 1);
f = zeros(n, 6);
irow = (1:n)';
for ir = 1:n
  ilc(ir) = find(matches(com.loadcase.name, tochar(data{ir, 1})));
  selector(ir, :) = cellfun(@tochar, data(ir, 2:4), ...
    'UniformOutput', false);
  f(ir, :) = cell2mat(data(ir, 5:10));
end
nodal_force = table(selector, ilc, f, irow);

return
end


function position = set_earthquake_force_position_block(dbc)
%set_earthquake_force_position_block - 地震力作用位置の入力を検証する
%
%   position = set_earthquake_force_position_block(dbc) は、
%   指定方法と座標の欠損を検証し、階の指定と絶対座標を返す。
%
%   入力引数:
%     dbc - 入力データブロックの読込オブジェクト
%
%   出力引数:
%     position - 階の指定、X・Y座標と入力位置のテーブル

data = dbc.get_data_block('地震力作用位置の直接入力');
n = size(data, 1);
selector = cell(n, 1);
x = zeros(n, 1);
y = zeros(n, 1);
irow = (1:n)';
k = 0;
for ir = 1:n
  rigid_name = tochar(data{ir, 2});
  method = tochar(data{ir, 3});
  if matches(method, '指定なし')
    continue
  end
  if ~matches(rigid_name, '主剛床')
    error('YLAB:Input:UnsupportedEarthquakeForcePosition', ...
      '地震力作用位置は主剛床のみ対応しています（行 %d）', ir);
  end
  if ~matches(method, '絶対座標')
    error('YLAB:Input:UnsupportedEarthquakeForcePosition', ...
      '地震力作用位置は絶対座標のみ対応しています（行 %d）', ir);
  end
  if ismissing(data{ir, 6}) || ismissing(data{ir, 7})
    error('YLAB:Input:InvalidEarthquakeForcePosition', ...
      '地震力作用位置のX座標またはY座標が空欄です（行 %d）', ir);
  end
  k = k + 1;
  selector{k} = tochar(data{ir, 1});
  x(k) = data{ir, 6};
  y(k) = data{ir, 7};
  irow(k) = ir;
end
position = table(selector, x, y, irow);
position = position(1:k, :);

return
end
