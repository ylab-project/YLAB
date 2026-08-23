function [nwhead, nwbody] = write_cell_nodal_weight(com, result)
%write_cell_nodal_weight - 計算済み長期節点重量をセル配列へ配置する
%
%   [nwhead, nwbody] = write_cell_nodal_weight(com, result) は、分析層で
%   確定した長期節点重量を、SS7互換の固定+積載表へ配置する。
%
%   入力引数:
%     com    - 節点、グリッドおよび層情報
%     result - .nodal_weight.longに計算済み物理量を持つ解析結果
%
%   出力引数:
%     nwhead - 帳票ヘッダー
%     nwbody - 節点別重量行
%
%   備考:
%     - 数値の分類、再配分、基礎判定および累計は分析層で完了済み。
%     - 表示行数は計算済み表示値と表示下限からwriter内で決定する。
weight = result.nodal_weight.long;
blank_kn = PRM.NODAL_WEIGHT_BLANK_KN;
upper = [weight.upper_floor, weight.upper_special, weight.upper_axial];
nrow = 1 + any(abs(upper) >= blank_kn * 1000, 'all');
if nrow == 2
  nwhead = {'X軸', 'Y軸', '層', '床自重', '梁自重', '壁自重', ...
    '特殊荷重', '柱自重', '補正', 'ﾌﾚｰﾑ外', '基礎重量', '合計', ...
    '概算軸力', '概算軸力TL'; '', '', '', 'kN', 'kN', 'kN', 'kN', ...
    'kN', 'kN', 'kN', 'kN', 'kN', 'kN', 'kN'};
  ncol = 15;
else
  nwhead = {'X軸', 'Y軸', '層', '床自重', '梁自重', '壁自重', ...
    '特殊荷重', '柱自重', '補正', 'ﾌﾚｰﾑ外', '基礎重量', '合計', ...
    '概算軸力'; '', '', '', 'kN', 'kN', 'kN', 'kN', 'kN', 'kN', ...
    'kN', 'kN', 'kN', 'kN'};
  ncol = 14;
end
nwbody = cell(com.nnode * nrow, ncol);

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
      if nrow == 2
        irow = irow + 1;
        nwbody(irow, 1:3) = {node.xname{in}, node.yname{in}, ...
          node.zname{in}};
        nwbody{irow, 4} = fmt_weight_kn(weight.upper_floor(in), blank_kn);
        nwbody{irow, 7} = fmt_weight_kn(weight.upper_special(in), ...
          blank_kn);
        nwbody{irow, 13} = fmt_weight_kn(weight.upper_axial(in), blank_kn);
        nwbody{irow, ncol} = PRM.CONT_MARKER;

        irow = irow + 1;
        nwbody{irow, 4} = fmt_weight_kn(weight.lower_floor(in), blank_kn);
        nwbody{irow, 5} = fmt_weight_kn(weight.girder(in), blank_kn);
        nwbody{irow, 6} = fmt_weight_kn(weight.wall(in), blank_kn);
        nwbody{irow, 7} = fmt_weight_kn(weight.lower_special(in), ...
          blank_kn);
        nwbody{irow, 8} = fmt_weight_kn(weight.column(in), blank_kn);
        nwbody{irow, 9} = fmt_weight_kn(weight.correction(in), blank_kn);
        nwbody{irow, 10} = fmt_weight_kn(weight.frame_out(in), blank_kn);
        nwbody{irow, 11} = fmt_weight_kn(weight.foundation(in), blank_kn);
        nwbody{irow, 12} = fmt_weight_kn(weight.total(in), blank_kn);
        nwbody{irow, 13} = fmt_weight_kn(weight.axial(in), blank_kn);
        nwbody{irow, 14} = fmt_weight_kn(weight.axial_tl(in), blank_kn);
      else
        irow = irow + 1;
        nwbody(irow, 1:3) = {node.xname{in}, node.yname{in}, ...
          node.zname{in}};
        nwbody{irow, 4} = fmt_weight_kn(weight.floor(in), blank_kn);
        nwbody{irow, 5} = fmt_weight_kn(weight.girder(in), blank_kn);
        nwbody{irow, 6} = fmt_weight_kn(weight.wall(in), blank_kn);
        nwbody{irow, 7} = fmt_weight_kn(weight.special(in), blank_kn);
        nwbody{irow, 8} = fmt_weight_kn(weight.column(in), blank_kn);
        nwbody{irow, 9} = fmt_weight_kn(weight.correction(in), blank_kn);
        nwbody{irow, 10} = fmt_weight_kn(weight.frame_out(in), blank_kn);
        nwbody{irow, 11} = fmt_weight_kn(weight.foundation(in), blank_kn);
        nwbody{irow, 12} = fmt_weight_kn(weight.total(in), blank_kn);
      end
    end
  end
end
nwbody = nwbody(1:irow, :);

return
end
