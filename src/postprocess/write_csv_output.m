function result = write_csv_output(xvar, com, options)

% 計算の準備
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

%% 解析
[cvec, result] = analysis_constraint(xvar, com, options);
% lm = result.lm;
[fval, fdetail] = objective_lsr(...
  xvar, secmgr, baseline, node, section, member, story, floor, options);

% plot(sort(max([reshape([result.gri; result.grj; result.grc],com.nmeg,[])],[],2)+1))
% plot(max(result.drift.angle,[],2))
[fout, msg] = fopen(output, 'w+', 'native', 'Shift_JIS');
if fout == -1
  error('write_csv_output:FileOpenError', '出力ファイルを開けませんでした。\n詳細: %s\nパス: %s\nExcel等でファイルを開いている場合は閉じてください。', msg, output);
end

%% 一般
fprintf(fout, 'ApName,%s\n','YLAB/LSR');
fprintf(fout, 'Version,%s\n',options.version);
fprintf(fout, '計算日,%s\n',datetime("today"));
fprintf(fout, '\n,\n');

%% 最適化問題
write_csv_optimization_problem(com, result, options, fval, cvec, fout);

%% 設計変数
fprintf(fout, 'name=設計変数,\n');
fprintf(fout, '%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,\n', xvar);
fprintf(fout, '\n,\n,\n');

%% 設計変数
fprintf(fout, 'name=設計変数(初期解),\n');
fprintf(fout, '%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,\n', options.x0);
fprintf(fout, '\n,\n,\n');

%% 制約違反量
write_csv_constraint_problem(result, options, cvec, fout)

%% 目的関数
fprintf(fout, 'name=鋼材量,\n');
fprintf(fout, '種類,重量(ton),コスト\n');
fprintf(fout, 'S柱梁,%.1f,%.1f\n', fdetail.weight, fdetail.cost);
fprintf(fout, 'S梁,%.1f,%.1f\n', fdetail.weight_girder, fdetail.cost_girder);
fprintf(fout, 'S柱,%.1f,%.1f\n', fdetail.weight_column,fdetail.cost_column);
fprintf(fout, '断面リスト番号,重量(ton),コスト\n');
for id=1:secmgr.getNumSectionSubList
  weight_sublist = fdetail.weight_sublist(id);
  cost_sublist = fdetail.cost_sublist(id);
  fprintf(fout, '%d,%.1f,%.1f\n', id, weight_sublist, cost_sublist);
end
fprintf(fout, ',\n,\n');

%% 構造階高
[fhhead, fhbody] = write_cell_floor_height(xvar, com, result, options);
fprintf(fout, 'name=構造階高\n');
write_csv_from_cell(fout, fhhead, fhbody);
fprintf(fout, ',\n,\n');

%% 柱梁断面リスト 
[gshead, gsbody, cshead, csbody] = ...
  write_cell_section_list(xvar, com, options);

fprintf(fout, 'name=柱断面リスト\n');
write_csv_from_cell(fout, cshead, csbody);
fprintf(fout, ',\n,\n');

fprintf(fout, 'name=梁断面リスト\n');
write_csv_from_cell(fout, gshead, gsbody);
fprintf(fout, ',\n,\n');

%% 柱梁断面リスト(SS7用)
[gshead, gsbody, cshead, csbody, cbshead, cbsbody] = ...
  write_cell_section_list_ss7(xvar, com, result, options);

%% ブレース断面リストの出力
secb = com.section.brace;
stype = com.section.property.type;
secmgr = com.secmgr;
if ~isempty(xvar)
  secdim = secmgr.findNearestSection(xvar, options);
else
  secdim = [];
end
[bshead, bsbody] = write_cell_brace_manufacturer_section_list_ss7(...
  secb, stype, secdim, secmgr);

fprintf(fout, 'name=S柱断面\n');
write_csv_from_cell(fout, cshead, csbody);
fprintf(fout, ',\n,\n');

if (com.nseccb>0)
  fprintf(fout, 'name=メーカー製柱脚断面\n');
  write_csv_from_cell(fout, cbshead, cbsbody);
  fprintf(fout, ',\n,\n');
end

fprintf(fout, 'name=S梁断面\n');
write_csv_from_cell(fout, gshead, gsbody);
fprintf(fout, ',\n,\n');

fprintf(fout, 'name=鉛直ブレース断面リスト(メーカー製品)\n');
write_csv_from_cell(fout, bshead, bsbody);
fprintf(fout, ',\n,\n');

%% 仮定断面出力
[gshead, gsbody, cshead, csbody, cbshead, cbsbody] = ...
  write_cell_section_list_ss7(options.x0, com, result, options);

% ブレース断面リストの出力（仮定）
if ~isempty(options.x0)
  secdim = secmgr.findNearestSection(options.x0, options);
else
  secdim = [];
end
[bshead, bsbody] = write_cell_brace_manufacturer_section_list_ss7(secb, stype, secdim, secmgr);

fprintf(fout, 'name=S柱断面(仮定)\n');
write_csv_from_cell(fout, cshead, csbody);
fprintf(fout, ',\n,\n');

if (com.nseccb>0)
  fprintf(fout, 'name=メーカー製柱脚断面(仮定)\n');
  write_csv_from_cell(fout, cbshead, cbsbody);
  fprintf(fout, ',\n,\n');
end

fprintf(fout, 'name=S梁断面(仮定)\n');
write_csv_from_cell(fout, gshead, gsbody);
fprintf(fout, ',\n,\n');

fprintf(fout, 'name=鉛直ブレース断面リスト(メーカー製品)(仮定)\n');
write_csv_from_cell(fout, bshead, bsbody);
fprintf(fout, ',\n,\n');

%% 断面剛性表
[gphead, gpbody] = write_cell_girder_property(com, result);
[bphead, bpbody] = write_cell_brace_property(com, result);

fprintf(fout, 'name=梁剛性表,case=標準\n');
write_csv_from_cell(fout, gphead, gpbody);
fprintf(fout, ',\n,\n');

[cphead, cpbody] = write_cell_column_property(com, result);
fprintf(fout, 'name=柱剛性表,case=標準\n');
write_csv_from_cell(fout, cphead, cpbody);
fprintf(fout, ',\n,\n');

fprintf(fout, 'name=鉛直ブレース剛性表,case=標準\n');
write_csv_from_cell(fout, bphead, bpbody);
fprintf(fout, ',\n,\n');

%% 柱座屈長さ
[cblhead, cblbody] = write_cell_column_buckling_length(com, result);
fprintf(fout, 'name=柱座屈長さ,case=標準\n');
write_csv_from_cell(fout, cblhead, cblbody);
fprintf(fout, ',\n,\n');

%% 保有耐力横補剛
fprintf(fout, 'name=保有耐力横補剛\n');
stgcell = write_cell_girder_stiffening(com, result);
write_csv_from_cell(fout, stgcell.head, stgcell.body);
fprintf(fout, ',\n,\n');

%% 節点重量表
[nwhead, nwbody] = write_cell_nodal_weight(com, result);
fprintf(fout, 'name=節点重量表(固定+積載)\n');
write_csv_from_cell(fout, nwhead, nwbody);
fprintf(fout, ',\n,\n');

%% 等価節点荷重
[nlhead, nlbody] = write_cell_nodal_equiv_load(com, result);
fprintf(fout, 'name=等価節点荷重,case=G+P\n');
write_csv_from_cell(fout, nlhead, nlbody);
fprintf(fout, ',\n,\n');

%% 変位量（重心位置）
for icase = 1:nlc
  [cdhead, cdbody] = write_cell_center_displacement(com, result, icase);
  fprintf(fout, 'name=変位量(重心位置)(一次),case=%s\n', ...
    loadcase.name{icase});
  write_csv_from_cell(fout, cdhead, cdbody);
  fprintf(fout, ',\n,\n');
end

%% 変位量（節点）
for icase = 1:nlc
  [ndhead, ndbody] = write_cell_nodal_displacement(com, result, icase);
  fprintf(fout, 'name=変位量(節点)(一次),case=%s\n', ...
    loadcase.name{icase});
  write_csv_from_cell(fout, ndhead, ndbody);
  fprintf(fout, ',\n,\n');
end

%% 梁応力表
for icase = 1:nlc
  [gflhead, gflbody] = write_cell_girder_force_list(com, result, icase);
  fprintf(fout, 'name=梁応力表(一次),case=%s\n', ...
    loadcase.name{icase});
  write_csv_from_cell(fout, gflhead, gflbody);
  fprintf(fout, ',\n,\n');
end

%% 柱応力表
for icase = 1:nlc
  [cflhead, cflbody] = write_cell_column_force_list(com, result, icase);
  fprintf(fout, 'name=柱応力表(一次),case=%s\n', ...
    loadcase.name{icase});
  write_csv_from_cell(fout, cflhead, cflbody);
  fprintf(fout, ',\n,\n');
end

%% 鉛直ブレース応力表
for icase = 1:nlc
  [bflhead, bflbody] = write_cell_brace_force_list(com, result, icase);
  fprintf(fout, 'name=鉛直ブレース応力表(一次),case=%s\n', ...
    loadcase.name{icase});
  write_csv_from_cell(fout, bflhead, bflbody);
  fprintf(fout, ',\n,\n');
end

%% 水平ブレース応力表
for icase = 1:nlc
  [hbflhead, hbflbody] = ...
    write_cell_horizontal_brace_force_list(com, result, icase);
  fprintf(fout, 'name=水平ブレース応力表(一次),case=%s\n', ...
    loadcase.name{icase});
  write_csv_from_cell(fout, hbflhead, hbflbody);
  fprintf(fout, ',\n,\n');
end

%% 支点応力表
for icase = 1:nlc
  [rflhead, rflbody] = write_cell_reaction_force_list(com, result, icase);
  fprintf(fout, 'name=支点応力表(一次),case=%s\n', ...
    loadcase.name{icase});
  write_csv_from_cell(fout, rflhead, rflbody);
  fprintf(fout, ',\n,\n');
end

%% 梁設計応力表
for icase = 1:2
  [dgflhead, dgflbody] = ...
    write_cell_design_girder_force_list(com, result, icase);
  switch icase
    case 1
      label = '長期';
    case 2
      label = '地震時';
  end
  fprintf(fout, 'name=梁設計応力表,case=%s\n', label);
  write_csv_from_cell(fout, dgflhead, dgflbody);
  fprintf(fout, ',\n,\n');
end

%% 柱設計応力表
for icase = 1:2
  [dcflhead, dcflbody] = ...
    write_cell_design_column_force_list(com, result, icase);
  switch icase
    case 1
      label = '長期';
    case 2
      label = '地震時';
  end
  fprintf(fout, 'name=柱設計応力表,case=%s\n', label);
  write_csv_from_cell(fout, dcflhead, dcflbody);
  fprintf(fout, ',\n,\n');
end

%% ブレース応力表
for icase = 1:2
  [dbflhead, dbflbody] = ...
    write_cell_design_brace_force_list(com, result, icase);
  switch icase
    case 1
      label = '長期';
    case 2
      label = '地震時';
  end
  fprintf(fout, 'name=ブレース設計応力表,case=%s\n', label);
  write_csv_from_cell(fout, dbflhead, dbflbody);
  fprintf(fout, ',\n,\n');
end

%% 梁設計応力表(組合せ前)
fprintf(fout, 'name=梁設計応力表(組合せ前)\n');
[dgiflhead, dgiflbody] = ...
  write_cell_design_girder_init_force_list(com, result);
write_csv_from_cell(fout, dgiflhead, dgiflbody);
fprintf(fout, ',\n,\n');

%% 柱設計応力表(組合せ前)
fprintf(fout, 'name=柱設計応力表(組合せ前)\n');
[dciflhead, dciflbody] = ...
  write_cell_design_column_init_force_list(com, result);
write_csv_from_cell(fout, dciflhead, dciflbody);
fprintf(fout, ',\n,\n');

%% S梁検定比一覧
fprintf(fout, 'name=S梁検定比一覧\n');
[asrghead, asrgbody] = ...
  write_cell_allowable_stress_ratio_girder(com, result);
write_csv_from_cell(fout, asrghead, asrgbody);
fprintf(fout, ',\n,\n');

%% S柱検定比一覧
fprintf(fout, 'name=S柱検定比一覧\n');
[asrchead, asrcbody] = ...
  write_cell_allowable_stress_ratio_column(com, result);
write_csv_from_cell(fout, asrchead, asrcbody);
fprintf(fout, ',\n,\n');

%% ブレース検定比一覧
fprintf(fout, 'name=ブレース検定比一覧\n');
[asrbhead, asrbbody] = ...
  write_cell_allowable_stress_ratio_brace(com, result);
write_csv_from_cell(fout, asrbhead, asrbbody);
fprintf(fout, ',\n,\n');

%% S梁断面算定表
scgbody = write_cell_section_calculation_girder(com, result, options);
fprintf(fout, 'name=S梁断面算定表\n');
write_csv_from_cell(fout, [], scgbody);
fprintf(fout, ',\n,\n');

%% S柱断面算定表
sccbody = write_cell_section_calculation_column(com, result);
fprintf(fout, 'name=S柱断面算定表\n');
write_csv_from_cell(fout, [], sccbody);
fprintf(fout, ',\n,\n');

%% 層間変形角
for icase = [PRM.EXP PRM.EXN PRM.EYP PRM.EYN]
  [sdrhead, sdrbody] = write_cell_interstory_drift(...
    com, result, options, icase);
  fprintf(fout, 'name=層間変形角	case=%s\n', ...
    loadcase.name{icase});
  write_csv_from_cell(fout, sdrhead, sdrbody);
  fprintf(fout, ',\n,\n');
end

%% 柱梁耐力比
for icase = [PRM.EXP PRM.EXN PRM.EYP PRM.EYN]
  if ~options.coptions.consider_joint_strength_ratio
    break
  end
  cgscell = write_cell_column_gider_strength(com, result, icase);
  fprintf(fout, 'name=柱梁耐力比	case=%s\n', ...
    loadcase.name{icase});
  write_csv_from_cell(fout, cgscell.head, cgscell.body);
  fprintf(fout, ',\n,\n');
end

fclose(fout);
fclose('all');
return
end

