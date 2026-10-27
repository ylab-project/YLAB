function check_max_section_violation(cvec, result, com, options)
%check_max_section_violation - 上限断面の違反箇所と評価内容を警告する
%
%   check_max_section_violation(cvec, result, com, options) は、
%   設計変数上限から選択した断面の違反を部材・位置・材料付きで示す。
%   荷重ケースと検定位置は、その制約を支配する解析結果から選ぶ。
%
%   入力引数:
%     cvec    - 上限断面の制約値 [1×ncon]（正の値が違反）
%     result  - 同じ評価点の完全な解析結果
%     com     - 部材・断面・荷重ケースの対応
%     options - 制約の余裕率と評価対象の指定
%
%   出力引数:
%     なし

ncon = result.ncon;
label = result.conlabel;
% 上限断面でも充足を保証できない耐力比・種別割合・幾何制約を除く。
excluded_label = {'柱梁耐力比', '断面規格', '梁せい差-呼称', ...
  '梁せい差-寸法', '柱外径', '梁せい分布', 'FA割合', 'FC割合'};
category_end = cumsum(ncon);
category_start = category_end - ncon + 1;
parts = {};
[~, ~, ~, idg, idc] = get_wtratio_requirements(com, options);
for k = find(~ismember(label, excluded_label))
  vio = cvec(category_start(k):category_end(k));
  for index = reshape(find(vio > 0), 1, [])
    [idme, point, alfa] = get_violation_target(label{k}, index, ...
      com, result, options, idg, idc);
    ratio = 1 + vio(index) - alfa;
    if strcmp(label{k}, '保有耐力横補剛')
      % 横補剛の制約は1-許容間隔/実間隔。表示は実間隔/許容間隔。
      ratio = 1 / (1 - vio(index) + alfa);
    end
    for im = reshape(idme, 1, [])
      detail = format_member_detail(im, com, result);
      parts{end+1} = sprintf([ ...
        '  制約     : %s\n%s\n  検定位置 : %s\n' ...
        '  検定比   : %.6f\n  余裕率   : %g'], label{k}, detail, ...
        point, ratio, alfa); %#ok<AGROW>
    end
  end
end
if ~isempty(parts)
  detail = strjoin(parts, sprintf('\n\n'));
  throw_warn('List', 'MaxSectionViolation', detail);
end

return
end

%--------------------------------------------------------------------------
function [idme, point, alfa] = get_violation_target(label, index, ...
  com, result, options, idg, idc)
%get_violation_target - 制約番号から対象部材と支配位置を取得する
%
%   [idme, point, alfa] = ...
%     get_violation_target(label, index, com, result, options, ...
%     idg, idc) は、
%   分類内の番号を名目部材・代表断面・階の対応に従って部材へ変換する。
%
%   入力引数:
%     label   - 制約分類名
%     index   - 分類内の制約番号
%     com     - 部材・断面・荷重ケースの対応
%     result  - 位置・ケース別の解析結果
%     options - 制約の余裕率と評価対象の指定
%     idg, idc - 幅厚比対象の代表断面行番号 [ngwt×1], [ncwt×1]
%
%   出力引数:
%     idme  - 対象部材番号（幅厚比は同じ代表断面を使う各名目部材）
%     point - 荷重ケースと検定位置の表示文字列
%     alfa  - 該当制約の余裕率

coptions = options.coptions;
switch label
  case {'梁曲げ応力', '梁せん断応力', '梁たわみ', '保有耐力接合(仕口)'}
    ing = index;
    if strcmp(label, '保有耐力接合(仕口)')
      % 仕口制約は対象梁へ圧縮されているため名目梁番号へ戻す。
      ing = result.idjbs(index);
    end
    ig = com.nominal.girder.idmeg(ing, 1);
    idme = com.member.girder.idme(ig);
    switch label
      case '梁曲げ応力'
        values = [result.gri(ing, :); result.grc(ing, :); ...
          result.grj(ing, :)];
        point = format_stress_position(values, {'左端', '中央', ...
          '右端'}, com.loadcase);
        alfa = coptions.alfa_stress_ratio;
      case '梁せん断応力'
        values = [result.gsi(ing, :); result.gsj(ing, :)];
        point = format_stress_position(values, {'左端', '右端'}, ...
          com.loadcase);
        alfa = coptions.alfa_stress_ratio;
      case '梁たわみ'
        point = format_loadcase(PRM.LT, com.loadcase);
        point = [point '・中央'];
        alfa = coptions.alfa_girder_deflection;
      case '保有耐力接合(仕口)'
        [~, iend] = max(result.jbsratio(ing, :));
        names = {'左端仕口', '右端仕口'};
        point = names{iend};
        alfa = coptions.alfa_joint_bearing_strength;
    end
  case {'柱曲げ応力', '柱せん断応力'}
    ic = com.nominal.column.idmec(index, 1);
    idme = com.member.column.idme(ic);
    if strcmp(label, '柱曲げ応力')
      values = [result.cri(index, :); result.crj(index, :)];
    else
      values = [result.csi(index, :); result.csj(index, :)];
    end
    point = format_stress_position(values, {'柱脚', '柱頭'}, com.loadcase);
    alfa = coptions.alfa_stress_ratio;
  case 'ブレース応力'
    % ブレース応力は分割された各ブレースの番号で保持される。
    idme = com.member.brace.idme(index);
    point = format_stress_position(result.bnij(index, :), ...
      {'軸力'}, com.loadcase);
    alfa = coptions.alfa_stress_ratio;
  case {'梁幅厚比', '柱幅厚比'}
    if strcmp(label, '梁幅厚比')
      isrep = idg(index);
    else
      isrep = idc(index);
    end
    mp = com.member.property;
    idme = find(com.section.property.idsrep(mp.idsec) == isrep);
    % 同一名目部材の分割区間を重複表示しない。
    [~, ia] = unique(mp.idnominal(idme), 'stable');
    idme = idme(ia);
    point = '断面（幅厚比）';
    alfa = coptions.alfa_section_wt_ratio;
  case '保有耐力横補剛'
    girder = com.member.girder;
    idme = girder.idme(girder.section_type == PRM.WFS);
    idme = idme(index);
    point = '横補剛間隔';
    alfa = coptions.alfa_slenderness_ratio;
  case '層間変形'
    % 階×水平荷重ケースを列順に並べた制約から支配柱を取得する。
    ilc = find(com.loadcase.dir > 1);
    [ifl, icase] = ind2sub([size(result.drift.angle, 1), numel(ilc)], ...
      index);
    ilc = ilc(icase);
    ic = result.drift.idcolumn(ifl, ilc);
    idme = com.member.column.idme(ic);
    point = sprintf('%s・%s層間', format_loadcase(ilc, com.loadcase), ...
      com.floor.name{ifl});
    alfa = coptions.alfa_inter_story;
end

return
end

%--------------------------------------------------------------------------
function point = format_stress_position(values, names, loadcase)
%format_stress_position - 最大応力度比の荷重ケースと位置を整形する
%
%   point = format_stress_position(values, names, loadcase) は、
%   同値なら配列順で最初のケース・位置を選ぶ。
%
%   入力引数:
%     values   - 位置・荷重ケース別の制約値 [npoint×nlc]
%     names    - 位置の表示名 [1×npoint] cell
%     loadcase - 荷重ケース名と種別
%
%   出力引数:
%     point - 荷重ケースと位置の表示文字列

[~, index] = max(values(:));
[ipoint, ilc] = ind2sub(size(values), index);
point = sprintf('%s・%s', format_loadcase(ilc, loadcase), names{ipoint});

return
end

%--------------------------------------------------------------------------
function name = format_loadcase(ilc, loadcase)
%format_loadcase - 長期・短期の区分と荷重ケース名を整形する
%
%   name = format_loadcase(ilc, loadcase) は、解析に使った荷重ケースを
%   長期・短期の区分とともに返す。
%
%   入力引数:
%     ilc      - 荷重ケース番号
%     loadcase - 荷重ケース名と種別
%
%   出力引数:
%     name - 荷重ケースの表示文字列

if ilc == PRM.LT
  name = sprintf('長期（%s）', loadcase.name{ilc});
else
  name = sprintf('短期（%s）', loadcase.name{ilc});
end

return
end

%--------------------------------------------------------------------------
function detail = format_member_detail(im, com, result)
%format_member_detail - 部材の符号・位置・評価断面・材料を整形する
%
%   detail = format_member_detail(im, com, result) は、断面算定表と
%   同じ部材対応を使い、解析時の断面と材料を表示する。
%
%   入力引数:
%     im     - 全部材共通の部材番号
%     com    - 部材と断面の対応
%     result - 評価断面と材料を含む解析結果
%
%   出力引数:
%     detail - 部材・位置・評価断面・材料の4行の表示文字列

mp = com.member.property;
switch mp.type(im)
  case PRM.GIRDER
    ig = mp.idmeg(im);
    ing = com.member.girder.idnominal(ig);
    ng = com.nominal.girder;
    name = com.section.girder.name{mp.idsecg(im)};
    location = sprintf('%s・%s通り・%s–%s', ng.story_name{ing}, ...
      ng.frame_name{ing}, ng.coord_name{ing, 1}, ng.coord_name{ing, 2});
  case PRM.COLUMN
    ic = mp.idmec(im);
    column = com.member.column;
    name = com.section.column.name{mp.idsecc(im)};
    location = sprintf('%s・%s通り・%s通り', column.floor_name{ic}, ...
      column.coord_name{ic, 1}, column.coord_name{ic, 2});
  case PRM.BRACE
    ib = mp.idmeb(im);
    brace = com.member.brace;
    name = com.section.brace.name{mp.idsecb(im)};
    location = sprintf('%s・%s通り・%s–%s', brace.floor_name{ib}, ...
      brace.frame_name{ib}, brace.coord_name{ib, 1}, ...
      brace.coord_name{ib, 2});
end
sdim = format_section_dimension(mp.idsec(im), com, result.secdim);
detail = sprintf(['  部材     : %s\n  位置     : %s\n' ...
  '  評価断面 : %s\n  材料     : %s'], name, location, sdim, ...
  result.msprop.material_name{im});

return
end

%--------------------------------------------------------------------------
function name = format_section_dimension(is, com, secdim)
%format_section_dimension - 警告に表示する評価断面寸法を整形する
%
%   name = format_section_dimension(is, com, secdim) は、選択された
%   断面の記号と主要寸法を返す。製品ブレースは登録記号で表示する。
%
%   入力引数:
%     is     - 断面番号
%     com    - 断面種別と断面リスト
%     secdim - 評価した断面寸法 [nsec×7] (mm)
%
%   出力引数:
%     name - 主要寸法または登録記号の表示文字列

dim = secdim(is, :);
% RC固定断面は断面リストを持たず、形状用と荷重剛性用の寸法を保持する。
if com.section.property.type(is) == PRM.RCRS
  name = sprintf('RC-%g×%g（荷重剛性用 %g×%g）', dim(1:4));
  return
end
record = com.secmgr.getListRecord(dim);
symbol = record.symbol{1};
switch PRM.list_type_of_section_type(com.section.property.type(is))
  case PRM.WFS
    name = sprintf('%s-%g×%g×%g×%g', symbol, dim(1:4));
  case PRM.HSS
    name = sprintf('%s-%g×%g×%g', symbol, dim([1 1 2]));
  case PRM.HSR
    name = sprintf('%s-%g×%g', symbol, dim(1:2));
  otherwise
    name = symbol;
end

return
end