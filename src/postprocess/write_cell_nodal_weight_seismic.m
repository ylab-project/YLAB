function [head, body] = write_cell_nodal_weight_seismic(com, result)
%write_cell_nodal_weight_seismic - 地震時節点重量表を生成する
%
%   [head, body] = write_cell_nodal_weight_seismic(com, result) は、
%   case=EX/EY の完成済み重量を節点別に集計し、SS7の節点重量表
%   （地震時）に対応するセル配列を返す。
%
%   入力引数:
%     com    - 節点、グリッドおよび層情報
%     result - 分類済み要素重量を含む解析結果
%
%   出力引数:
%     head - 3行の帳票ヘッダー
%     body - 節点別重量行（最終列はmarker列）

head = {'X軸', 'Y軸', '層', '各部材重量', '', '', '', ...
  '特殊荷重', '合計', '概算軸力'; '', '', '', '柱', '大梁', ...
  '床', '壁', '大梁', '', ''; '', '', '', 'kN', 'kN', 'kN', ...
  'kN', 'kN', 'kN', 'kN'};
body = cell(0, 10);
if ~result.element_weight.has_seismic
  return
end

% KBRACE-MID節点の地震用重量をグリッド節点に再配分する
nodal = result.element_weight.nodal;
seismic = reshape(nodal(:, :, PRM.ELOAD_CASE_EXEY, :), com.nnode, 6, []);
seismic = redistribute_kbrace_mid(com, seismic);
node = com.node;
innn = 1:com.nnode;
rows = cell(com.nnode, 10);
irow = 0;
for iy = 1:com.nbly
  for ix = 1:com.nblx
    axial_sum = 0;
    for offset = 1:com.nstory
      istory = com.nstory - offset + 1;
      inode = innn(node.idx == ix & node.idy == iy ...
        & node.idstory == istory);
      inode = inode(node.type(inode) ~= PRM.NODE_BRACE_FOR_COLUMN);
      if isempty(inode) || node.idrep(inode) > 0
        continue
      end
      values = reshape(seismic(inode, 3, :), 1, []) * 1e-3;
      total = sum(values);
      axial_sum = axial_sum + total;
      irow = irow + 1;
      rows(irow, 1:3) = {node.xname{inode}, node.yname{inode}, ...
        node.zname{inode}};
      rows{irow, 4} = fmt_ceil_abs(0, 1);
      rows{irow, 5} = fmt_ceil_abs(0, 1);
      rows{irow, 6} = fmt_ceil_abs(values(PRM.ELOAD_TYPE_FLOOR), 1);
      rows{irow, 7} = fmt_ceil_abs(values(PRM.ELOAD_TYPE_WALL), 1);
      rows{irow, 8} = fmt_ceil_abs(values(PRM.ELOAD_TYPE_SPECIAL), 1);
      rows{irow, 9} = fmt_ceil_abs(total, 1);
      rows{irow, 10} = fmt_ceil_abs(axial_sum, 1);
    end
  end
end
body = rows(1:irow, :);

return
end
