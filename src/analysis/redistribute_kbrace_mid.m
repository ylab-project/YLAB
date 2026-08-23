function varargout = redistribute_kbrace_mid(com, varargin)
%redistribute_kbrace_mid - K形ブレース中間節点の値を両端へ配る
%
%   varargout = redistribute_kbrace_mid(com, varargin) は、K形ブレース
%   用梁の中間節点（NODE_BRACE_FOR_GIRDER）にある節点別の値を、左右の
%   グリッド節点へ半分ずつ加算し、中間節点を0にする。入力配列は変更
%   せず複製を返す。等価節点荷重の表示と節点重量の分類はこの再配分
%   規則を共有する。
%
%   入力引数:
%     com      - 節点・梁情報
%     varargin - 第1次元が節点の数値配列。2次元以降の形状は問わない
%                （例: [nnode×6]、[nnode×6×nlc]、[nnode×3×3×7]）
%
%   出力引数:
%     varargout - 再配分後の数値配列。入力と同じ順序・形状で返す
node = com.node;
member_girder = com.member.girder;

varargout = varargin;
idnode_mid = find(node.type == PRM.NODE_BRACE_FOR_GIRDER);
if isempty(idnode_mid)
  return
end

for k = 1:length(idnode_mid)
  idnode = idnode_mid(k);
  % KBRACE1（左側梁）: idnode2 == MID、KBRACE2（右側梁）: idnode1 == MID
  ig1 = find(member_girder.type == PRM.GIRDER_FOR_KBRACE1 ...
    & member_girder.idnode2 == idnode, 1);
  ig2 = find(member_girder.type == PRM.GIRDER_FOR_KBRACE2 ...
    & member_girder.idnode1 == idnode, 1);
  if isempty(ig1) || isempty(ig2)
    continue
  end
  in_left = member_girder.idnode1(ig1);
  in_right = member_girder.idnode2(ig2);

  % 節点単位で残りの全次元を一括再配分する
  for ia = 1:length(varargout)
    arr = varargout{ia};
    mid_vals = arr(idnode, :, :);
    arr(in_left, :, :) = arr(in_left, :, :) + mid_vals / 2;
    arr(in_right, :, :) = arr(in_right, :, :) + mid_vals / 2;
    arr(idnode, :, :) = 0;
    varargout{ia} = arr;
  end
end

return
end
