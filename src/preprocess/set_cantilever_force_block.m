function [cantilever_force, placements, issues] = ...
  set_cantilever_force_block(dbc, com)
%set_cantilever_force_block - 片持梁荷重と配置指定を正規化する
%
%   [cantilever_force, placements, issues] = ...
%     set_cantilever_force_block(dbc, com) は、C・Qoと配置指定を読む。
%   元端の節点・基準柱の検索と荷重の縮約はparse側で行う。
%
%   入力引数:
%     dbc - 入力データブロックの読込オブジェクト
%     com - 荷重ケースを持つ共通データ
%
%   出力引数:
%     cantilever_force - 配置指定・C・Qo・重量分類・入力位置の表
%     placements       - 未解決の配置指定と長さ・先端移動量の表
%     issues           - 入力値の検証で収集した警告

placements = set_cantilever_placement_block(dbc);
blocks = dbc.get_data_blocks('要素荷重(片持梁)');
n = sum(arrayfun(@(block) size(block.data, 1), blocks));
selector = cell(n, 5);
ilc = zeros(n, 1);
c_base = zeros(n, 1);
c_tip = zeros(n, 1);
q_base = zeros(n, 1);
q_tip = zeros(n, 1);
wclass = zeros(n, 1);
wusage = zeros(n, 1);
wtype = zeros(n, 1);
block_name = repmat({'要素荷重(片持梁)'}, n, 1);
iblock = zeros(n, 1);
irow = zeros(n, 1);
csv_row = zeros(n, 1);
nforce = 0;
issues = empty_input_issues();
ilc_gp = find_ilc_long_term(com.loadcase);
for ib = 1:length(blocks)
  data = blocks(ib).data;
  for ir = 1:size(data, 1)
    csv_line = blocks(ib).origrows(ir);
    names = cellfun(@tochar, data(ir, 1:3), 'UniformOutput', false);
    [head, lc, issues] = read_weight_head(names, ilc_gp, ...
      '要素荷重(片持梁)', ib, csv_line, issues);
    target = cellfun(@tochar, data(ir, 4:8), 'UniformOutput', false);
    if head.is_valid && any(cellfun(@is_all_token, target(1:3)))
      issues = add_input_issue(issues, 'ElementLoadAllNotSupported', ...
        '', '要素荷重(片持梁)', ib, csv_line, strjoin(target, '/'), ...
        1, 0, 1, '');
      head.is_valid = false;
    end
    if ~head.is_valid
      continue
    end
    nforce = nforce + 1;
    selector(nforce, :) = target;
    ilc(nforce) = lc;
    c_base(nforce) = normalize_missing_zero(data{ir, 9});
    c_tip(nforce) = normalize_missing_zero(data{ir, 10});
    q_base(nforce) = normalize_missing_zero(data{ir, 11});
    q_tip(nforce) = normalize_missing_zero(data{ir, 12});
    wclass(nforce) = head.wclass;
    wusage(nforce) = head.wusage;
    wtype(nforce) = head.wtype;
    iblock(nforce) = ib;
    irow(nforce) = ir;
    csv_row(nforce) = csv_line;
  end
end
cantilever_force = table(selector, ilc, c_base, c_tip, ...
  q_base, q_tip, wclass, wusage, wtype, block_name, iblock, irow, csv_row);
cantilever_force = cantilever_force(1:nforce, :);

return
end


function placements = set_cantilever_placement_block(dbc)
%set_cantilever_placement_block - 片持梁配置の文字列と幾何入力を正規化する
%
%   placements = set_cantilever_placement_block(dbc) は、
%   層・軸・方向・符号と長さ、先端移動量を入力順に保持する。
%   基準柱の回転はまだ適用しない。
%
%   入力引数:
%     dbc - 入力データブロックの読込オブジェクト
%
%   出力引数:
%     placements - 配置指定、幾何入力と元CSV行を持つテーブル

blocks = dbc.get_data_blocks('片持梁配置');
n = sum(arrayfun(@(block) size(block.data, 1), blocks));
selector = cell(n, 5);
len = zeros(n, 1);
tip_lr = zeros(n, 1);
tip_ud = zeros(n, 1);
iblock = zeros(n, 1);
csv_row = zeros(n, 1);
k = 0;
for ib = 1:length(blocks)
  data = blocks(ib).data;
  for ir = 1:size(data, 1)
    k = k + 1;
    selector(k, :) = cellfun(@tochar, data(ir, 1:5), ...
      'UniformOutput', false);
    len(k) = data{ir, 6};
    tip_lr(k) = normalize_missing_zero(data{ir, 7});
    tip_ud(k) = normalize_missing_zero(data{ir, 8});
    iblock(k) = ib;
    csv_row(k) = blocks(ib).origrows(ir);
  end
end
placements = table(selector, len, tip_lr, tip_ud, iblock, csv_row);

return
end
