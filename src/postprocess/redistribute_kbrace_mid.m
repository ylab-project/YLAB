function varargout = redistribute_kbrace_mid(com, varargin)
%redistribute_kbrace_mid - KBRACE-MID節点の荷重をグリッド節点に再配分
%
% 出力表示用に、KBRACE-MID（type=98）の荷重を
% 隣接する左右グリッド節点に50-50で再配分する。
% 入力配列のコピーを変更して返す（元データは変更しない）。
%
% 配列形状: (nnode, 6) または (nnode, 6, nlc)
%
% 使用例:
%   [f, fg, fw, fc] = redistribute_kbrace_mid(com, f, sw.fg, sw.fw, sw.fc);
%   fvec = redistribute_kbrace_mid(com, fvec);

node = com.node;
member_girder = com.member.girder;

% KBRACE-MID節点の検索
idnode_mid = find(node.type == PRM.NODE_BRACE_FOR_GIRDER);
if isempty(idnode_mid)
  varargout = varargin;
  return
end

% 入力配列のコピー
narg = length(varargin);
varargout = varargin;

% KBRACE-MID節点ごとに再配分
for k = 1:length(idnode_mid)
  idnode = idnode_mid(k);
  % KBRACE1（左側梁）: idnode2 == MID
  ig1 = find(member_girder.type == PRM.GIRDER_FOR_KBRACE1 ...
    & member_girder.idnode2 == idnode, 1);
  % KBRACE2（右側梁）: idnode1 == MID
  ig2 = find(member_girder.type == PRM.GIRDER_FOR_KBRACE2 ...
    & member_girder.idnode1 == idnode, 1);
  if isempty(ig1) || isempty(ig2)
    continue
  end
  in_left = member_girder.idnode1(ig1);
  in_right = member_girder.idnode2(ig2);

  % 節点単位で全6成分・全荷重ケースを一括再配分
  for ia = 1:narg
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
