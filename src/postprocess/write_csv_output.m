function result = write_csv_output(xvar, com, options)
%write_csv_output - 計算結果をCSVファイルに出力する
%
%   result = write_csv_output(xvar, com, options) は、
%   解析・断面算定の結果を Shift_JIS の CSV ファイルに
%   書き出す。出力先は options.outputfile で指定する。
%
%   入力引数:
%     xvar    - 設計変数ベクトル
%     com     - 共通オブジェクト
%     options - オプション構造体
%
%   出力引数:
%     result  - 解析結果構造体

%% 計算の準備
nlc = com.nlc;
loadcase = com.loadcase;
output = options.outputfile;
% lm = com.member.property.lm;
secmgr = com.secmgr;
section = com.section;
member = com.member;
baseline = com.baseline;
node = com.node;
story = com.story;
floor = com.floor;
% material = com.material;

% 断面関連
secb = com.section.brace;
stype = com.section.property.type;

%% 解析
[cvec, result] = analysis_constraint(xvar, com, options);
[fval, fdetail, cost] = objective_lsr(xvar, secmgr, ...
  baseline, node, section, member, story, floor, options);

% 最適解
secdim = result.secdim;

% 初期解
if ~isempty(options.x0)
  secdim0 = secmgr.findNearestSection(options.x0, options);
else
  secdim0 = [];
end

[fout, msg] = fopen(output, 'w+', 'native', 'Shift_JIS');
if fout == -1
  error('write_csv_output:FileOpenError', ...
    ['出力ファイルを開けませんでした。' ...
    '\n詳細: %s\nパス: %s\nExcel等でファイルを' ...
    '開いている場合は閉じてください。'], msg, output);
end

%% 一般
fprintf(fout, 'ApName,%s\n','YLAB/LSR');
fprintf(fout, 'Version,%s\n',options.version);
fprintf(fout, '計算日,%s\n',datetime("today"));

%% 最適化問題
write_csv_optimization_problem(com, result, options, fval, cvec, fout);

%% 設計変数
fprintf(fout, '\n\nname=設計変数,\n');
fprintf(fout, '%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,\n', xvar);
if mod(numel(xvar), 10) ~= 0
  fprintf(fout, '\n');
end

%% 設計変数
fprintf(fout, '\n\nname=設計変数(初期解),\n');
fprintf(fout, '%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,\n', options.x0);
if mod(numel(options.x0), 10) ~= 0
  fprintf(fout, '\n');
end

%% 制約違反量
write_csv_constraint_problem(result, options, cvec, fout);

%% 目的関数
fprintf(fout, '\n\nname=鋼材量,\n');
fprintf(fout, '種類,重量(ton),コスト\n');
fprintf(fout, 'S柱梁,%.2f,%.2f\n', fdetail.weight, fdetail.cost);
fprintf(fout, 'S梁,%.2f,%.2f\n', fdetail.weight_girder, ...
  fdetail.cost_girder);
fprintf(fout, 'S柱,%.2f,%.2f\n', fdetail.weight_column, ...
  fdetail.cost_column);
fprintf(fout, '断面リスト番号,重量(ton),コスト\n');
for id=1:secmgr.getNumSectionSubList
  weight_sublist = fdetail.weight_sublist(id);
  cost_sublist = fdetail.cost_sublist(id);
  fprintf(fout, '%d,%.2f,%.2f\n', id, weight_sublist, cost_sublist);
end

%% 構造階高
[fhhead, fhbody] = write_cell_floor_height(xvar, com, result, options);
write_table(fout, '構造階高', fhhead, fhbody);

%% 柱梁断面リスト
[gshead, gsbody, cshead, csbody] = write_cell_section_list(...
  xvar, com, options);
write_table(fout, '柱断面リスト', cshead, csbody);
write_table(fout, '梁断面リスト', gshead, gsbody);

%% 柱梁断面リスト(SS7用)
[gshead, gsbody, cshead, csbody, cbshead, cbsbody] = ...
  write_cell_section_list_ss7(secdim, com, result, options);

%% ブレース断面リストの出力
[bshead, bsbody] = write_cell_brace_manufacturer_section_list_ss7(...
  secb, stype, secdim, com.secmgr);
[blhead, blbody] = write_cell_brace_section_list_ss7(...
  secb, stype, secdim, com.secmgr);

write_table(fout, 'S柱断面', cshead, csbody);
write_table(fout, 'メーカー製柱脚断面', cbshead, cbsbody);
write_table(fout, 'S梁断面', gshead, gsbody);
write_table(fout, '鉛直ブレース断面リスト', blhead, blbody);
write_table(fout, '鉛直ブレース断面リスト(メーカー製品)', bshead, bsbody);

%% 仮定断面出力
[gshead, gsbody, cshead, csbody, cbshead, cbsbody] = ...
  write_cell_section_list_ss7(secdim0, com, result, options);

% ブレース断面リストの出力（仮定）
[slhead, slbody] = write_cell_brace_steel_section_list(...
  secb, stype, secdim0, com.secmgr);
[tbhead, tbbody] = write_cell_brace_tb_section_list(...
  secb, stype, secdim0, com.secmgr);
[bshead, bsbody] = write_cell_brace_manufacturer_section_list(...
  secb, stype, secdim0, com.secmgr);

write_table(fout, 'S柱断面(仮定)', cshead, csbody);
write_table(fout, 'メーカー製柱脚断面(仮定)', cbshead, cbsbody);
write_table(fout, 'S梁断面(仮定)', gshead, gsbody);
write_table(fout, '鉛直ブレース断面(鋼材)(仮定)', slhead, slbody);
write_table(fout, '鉛直ブレース断面(引張ブレース)(仮定)', tbhead, tbbody);
write_table(fout, '鉛直ブレース断面(メーカー製品)(仮定)', bshead, bsbody);

%% 断面剛性表
[gphead, gpbody] = write_cell_girder_property(com, result);
[bphead, bpbody] = write_cell_brace_property(com, result);
write_table(fout, '梁剛性表,case=標準', gphead, gpbody);

[cphead, cpbody] = write_cell_column_property(com, result);
write_table(fout, '柱剛性表,case=標準', cphead, cpbody);
write_table(fout, '鉛直ブレース剛性表,case=標準', bphead, bpbody);

%% 柱座屈長さ
[cblhead, cblbody] = write_cell_column_buckling_length(com, result);
write_table(fout, '柱座屈長さ,case=標準', cblhead, cblbody);

%% 柱座屈長さ係数の自動計算
if ~isempty(result.bkinfo) ...
    && options.consider_column_buckling_length_factor
  [bkh, bkb] = write_cell_column_buckling_length_factor(com, result);
  write_table(fout, '柱座屈長さ係数の自動計算,case=標準', bkh, bkb);
end

%% 水平力分担表
if com.nmeb > 0
  for ilc = [PRM.EXP PRM.EXN PRM.EYP PRM.EYN]
    [fsrh, fsrb] = write_cell_force_share_ratio(com, result, ilc);
    write_table(fout, sprintf('水平力分担表,case=%s', ...
      loadcase.name{ilc}), fsrh, fsrb);
  end
end

%% 保有耐力横補剛
stgcell = write_cell_girder_stiffening(com, result);
write_table(fout, '保有耐力横補剛', stgcell.head, stgcell.body);

%% 節点重量表
[nwhead, nwbody] = write_cell_nodal_weight(com, result);
write_table(fout, '節点重量表(固定+積載)', nwhead, nwbody);

%% 等価節点荷重
[nlhead, nlbody] = write_cell_nodal_equiv_load(com, result, false);
write_table(fout, '等価節点荷重,case=G+P', nlhead, nlbody);

%% 変位量（重心位置）
for icase = 1:nlc
  [cdhead, cdbody] = write_cell_center_displacement(com, result, icase);
  write_table(fout, sprintf('変位量(重心位置)(一次),case=%s', ...
    loadcase.name{icase}), cdhead, cdbody);
end

%% 変位量（節点）
for icase = 1:nlc
  [ndhead, ndbody] = write_cell_nodal_displacement(com, result, icase);
  write_table(fout, sprintf('変位量(節点)(一次),case=%s', ...
    loadcase.name{icase}), ndhead, ndbody);
end

%% 梁応力表
for icase = 1:nlc
  [gflhead, gflbody] = write_cell_girder_force_list(com, result, icase);
  write_table(fout, sprintf('梁応力表(一次),case=%s', ...
    loadcase.name{icase}), gflhead, gflbody);
end

%% 柱応力表
for icase = 1:nlc
  [cflhead, cflbody] = write_cell_column_force_list(com, result, icase);
  write_table(fout, sprintf('柱応力表(一次),case=%s', ...
    loadcase.name{icase}), cflhead, cflbody);
end

%% 鉛直ブレース応力表
for icase = 1:nlc
  [bflhead, bflbody] = write_cell_brace_force_list(com, result, icase);
  write_table(fout, sprintf('鉛直ブレース応力表(一次),case=%s', ...
    loadcase.name{icase}), bflhead, bflbody);
end

%% 水平ブレース応力表
for icase = 1:nlc
  [hbflhead, hbflbody] = write_cell_horizontal_brace_force_list(...
    com, result, icase);
  write_table(fout, sprintf('水平ブレース応力表(一次),case=%s', ...
    loadcase.name{icase}), hbflhead, hbflbody);
end

%% 支点応力表
for icase = 1:nlc
  [rflhead, rflbody] = write_cell_reaction_force_list(com, result, icase);
  write_table(fout, sprintf('支点応力表(一次),case=%s', ...
    loadcase.name{icase}), rflhead, rflbody);
end

%% 梁設計応力表
for icase = 1:2
  [dgflhead, dgflbody] = write_cell_design_girder_force_list(...
    com, result, icase);
  switch icase
    case 1
      label = '長期';
    case 2
      label = '地震時';
  end
  write_table(fout, sprintf('梁設計応力表,case=%s', ...
    label), dgflhead, dgflbody);
end

%% 柱設計応力表
for icase = 1:2
  [dcflhead, dcflbody] = write_cell_design_column_force_list(...
    com, result, icase);
  switch icase
    case 1
      label = '長期';
    case 2
      label = '地震時';
  end
  write_table(fout, sprintf('柱設計応力表,case=%s', ...
    label), dcflhead, dcflbody);
end

%% ブレース応力表
for icase = 1:2
  [dbflhead, dbflbody] = write_cell_design_brace_force_list(...
    com, result, icase);
  switch icase
    case 1
      label = '長期';
    case 2
      label = '地震時';
  end
  write_table(fout, sprintf('鉛直ブレース設計応力表,case=%s', ...
    label), dbflhead, dbflbody);
end

%% 鉛直ブレース設計応力表(組合せ前)
[dbiflhead, dbiflbody] = write_cell_design_brace_init_force_list(...
  com, result);
write_table(fout, '鉛直ブレース設計応力表(組合せ前)', ...
  dbiflhead, dbiflbody);

%% 梁設計応力表(組合せ前)
[dgiflhead, dgiflbody] = write_cell_design_girder_init_force_list(...
  com, result);
write_table(fout, '梁設計応力表(組合せ前)', dgiflhead, dgiflbody);

%% 柱設計応力表(組合せ前)
[dciflhead, dciflbody] = write_cell_design_column_init_force_list(...
  com, result);
write_table(fout, '柱設計応力表(組合せ前)', dciflhead, dciflbody);

%% S梁検定比一覧
if options.do_legacy_output
  [asrghead, asrgbody] = ...
    write_cell_allowable_stress_ratio_girder_legacy(com, result);
else
  [asrghead, asrgbody] = write_cell_allowable_stress_ratio_girder(...
    com, result);
end
write_table(fout, 'S梁検定比一覧', asrghead, asrgbody);

%% S柱検定比一覧
if options.do_legacy_output
  [asrchead, asrcbody] = ...
    write_cell_allowable_stress_ratio_column_legacy(com, result);
else
  [asrchead, asrcbody] = write_cell_allowable_stress_ratio_column(...
    com, result);
end
write_table(fout, 'S柱検定比一覧', asrchead, asrcbody);

%% 鉛直ブレース検定比一覧
[asrbhead, asrbbody] = write_cell_allowable_stress_ratio_brace(...
  com, result);
write_table(fout, '鉛直ブレース検定比一覧', asrbhead, asrbbody);

%% S梁断面算定表
scgbody = write_cell_section_calculation_girder(com, result, options);
write_table(fout, 'S梁断面算定表', [], scgbody);

%% S柱断面算定表
sccbody = write_cell_section_calculation_column(com, result, options);
write_table(fout, 'S柱断面算定表', [], sccbody);

%% 鉛直ブレース断面算定表
scbbody = write_cell_section_calculation_brace(com, result);
write_table(fout, '鉛直ブレース断面算定表', [], scbbody);

%% 層間変形角
for icase = [PRM.EXP PRM.EXN PRM.EYP PRM.EYN]
  [sdrhead, sdrbody] = write_cell_interstory_drift(com, ...
    result, options, icase);
  write_table(fout, sprintf('層間変形角\tcase=%s', ...
    loadcase.name{icase}), sdrhead, sdrbody);
end

%% 柱梁耐力比
for icase = [PRM.EXP PRM.EXN PRM.EYP PRM.EYN]
  if ~options.coptions.consider_joint_strength_ratio
    break
  end
  cgscell = write_cell_column_gider_strength(com, result, icase);
  write_table(fout, sprintf('柱梁耐力比\tcase=%s', ...
    loadcase.name{icase}), cgscell.head, cgscell.body);
end

%% 鉄骨数量
[sch, scb] = write_cell_steel_cost_column(com, result);
write_table(fout, '柱の部位ごと数量(鉄骨)', sch, scb);
[sgh, sgb] = write_cell_steel_cost_girder(com, result);
write_table(fout, '大梁の部位ごと数量(鉄骨)', sgh, sgb);
[sbh, sbb] = write_cell_steel_cost_brace(com, result, cost);
write_table(fout, '鉛直ブレースの部位ごと数量(鉄骨)', sbh, sbb);
[shh, shb] = write_cell_steel_cost_hbrace(com, result, cost);
write_table(fout, '水平ブレースの部位ごと数量(鉄骨)', shh, shb);

%% 部位別集計表(鉄骨)
[smh, smb] = write_cell_steel_cost_summary(com, options, cost, secdim);
write_table(fout, '部位別集計表(鉄骨)', smh, smb);

fclose(fout);
fclose('all');

return
end

function write_table(fout, name, head, body)
%write_table - テーブル出力（body空なら全体をスキップ）
%
%   write_table(fout, name, head, body) は、
%   body が空でない場合のみテーブルを出力する。
%
%   入力引数:
%     fout - ファイル識別子
%     name - テーブル名（name= に続く文字列）
%     head - ヘッダ部セル配列（空可）
%     body - データ部セル配列
if size(body, 1) == 0
  return
end
% 末尾の空行を除去
while size(body, 1) > 0 && all(cellfun(@isempty, body(end, :)))
  body(end, :) = [];
end
if size(body, 1) == 0
  return
end
fprintf(fout, '\n\n');
fprintf(fout, 'name=%s\n', name);
write_csv_from_cell(fout, head, body);

return
end
