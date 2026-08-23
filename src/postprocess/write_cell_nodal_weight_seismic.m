function [head, body] = write_cell_nodal_weight_seismic(com, result)
%write_cell_nodal_weight_seismic - 計算済み地震時節点重量を配置する
%
%   [head, body] = write_cell_nodal_weight_seismic(com, result) は、
%   分析層で確定した地震用節点重量を、入力行、部材数および計算済み
%   表示値に応じた列構成でセル配列へ配置する。
%
%   入力引数:
%     com    - 節点、グリッドおよび層情報
%     result - .nodal_weight.seismicに計算済み物理量を持つ解析結果
%
%   出力引数:
%     head - 3行の帳票ヘッダー
%     body - 節点別重量行
weight = result.nodal_weight.seismic;
element = com.force.element;
nodal = com.force.nodal;
usage = [PRM.WUSAGE_COMMON, PRM.WUSAGE_SEISMIC];
selected = ismember(element.wusage, usage) ...
  & element.wclass > 0 & element.wtype > 0;
wtype = element.wtype(selected);
selected = ismember(nodal.wusage, usage) ...
  & nodal.wclass > 0 & nodal.wtype > 0;
wtype = [wtype; nodal.wtype(selected)];

top = {'X軸', 'Y軸', '層'};
sub = {'', '', ''};
fields = {};
member_top = '各部材重量';
if com.nmec > 0
  [top, sub, fields] = add_column(top, sub, fields, member_top, ...
    '柱', 'column');
  member_top = '';
end
if com.nmeg > 0
  [top, sub, fields] = add_column(top, sub, fields, member_top, ...
    '大梁', 'girder');
  member_top = '';
end
if any(nodal.wtype(selected & nodal.is_cantilever) == PRM.WTYPE_GIRDER)
  [top, sub, fields] = add_column(top, sub, fields, member_top, ...
    '片持梁', 'cantilever_girder');
  member_top = '';
end
if any(wtype == PRM.WTYPE_FLOOR) || any(weight.floor ~= 0)
  [top, sub, fields] = add_column(top, sub, fields, member_top, ...
    '床', 'floor');
  member_top = '';
end
if any(wtype == PRM.WTYPE_WALL) || any(weight.wall ~= 0)
  [top, sub, fields] = add_column(top, sub, fields, member_top, ...
    '壁', 'wall');
end
if any(wtype == PRM.WTYPE_SPECIAL)
  [top, sub, fields] = add_column(top, sub, fields, ...
    '特殊荷重', '大梁', 'special');
end
if any(wtype == PRM.WTYPE_CORRECTION)
  [top, sub, fields] = add_column(top, sub, fields, ...
    '補正重量', '', 'correction');
end
if any(wtype == PRM.WTYPE_FRAME_OUT)
  [top, sub, fields] = add_column(top, sub, fields, ...
    'ﾌﾚｰﾑ外', '', 'frame_out');
end
if any(wtype == PRM.WTYPE_FOUNDATION) || any(weight.foundation ~= 0)
  [top, sub, fields] = add_column(top, sub, fields, ...
    '基礎重量', '', 'foundation');
end
[top, sub, fields] = add_column(top, sub, fields, '合計', '', 'total');
[top, sub, fields] = add_column(top, sub, fields, '概算軸力', '', 'axial');
unit = [{'', '', ''}, repmat({'kN'}, 1, length(fields))];
head = [top; sub; unit];

body = cell(com.nnode, length(top));
node = com.node;
irow = 0;
for iy = 1:com.nbly
  for ix = 1:com.nblx
    for offset = 1:com.nstory
      istory = com.nstory - offset + 1;
      idnode = find_idnode_from_grid(com, ix, iy, istory);
      if isempty(idnode)
        continue
      end
      in = idnode(1);
      irow = irow + 1;
      body(irow, 1:3) = {node.xname{in}, node.yname{in}, node.zname{in}};
      for icol = 1:length(fields)
        body{irow, icol + 3} = fmt_weight_kn(weight.(fields{icol})(in), 0);
      end
    end
  end
end
body = body(1:irow, :);

return
end


function [top, sub, fields] = add_column(top, sub, fields, ...
  top_name, sub_name, field_name)
%add_column - 地震時節点重量表へ1分類列を追加する
%
%   [top, sub, fields] = add_column(top, sub, fields, top_name,
%   sub_name, field_name) は、上下2段の見出しと対応する結果フィールド
%   名へ1列を追加する。単位行は列数が確定した後にまとめて作る。
%
%   入力引数:
%     top,sub    - 作成中の見出し2段
%     fields     - 作成中の結果フィールド名
%     top_name   - 1段目の見出し
%     sub_name   - 2段目の見出し
%     field_name - 数値を取得する結果フィールド名
%
%   出力引数:
%     top,sub - 追加後の見出し2段
%     fields  - 追加後の結果フィールド名
top{end + 1} = top_name;
sub{end + 1} = sub_name;
fields{end + 1} = field_name;

return
end
