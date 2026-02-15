function varargout = redistribute_kbrace_mid(...
  com, varargin)
%redistribute_kbrace_mid - KBRACE-MID節点の荷重をグリッド節点に再配分
%
% 出力表示用に、KBRACE-MID（type=98）の荷重を
% 隣接する左右グリッド節点に50-50で再配分する。
% 入力配列のコピーを変更して返す（元データは変更しない）。
%
% 使用例:
%   [feqvec, fg, fw, fc, f] = ...
%     redistribute_kbrace_mid(com, feqvec, sw.fg, sw.fw, sw.fc, sw.f);
%   fvec = redistribute_kbrace_mid(com, fvec);

node = com.node;
member_girder = com.member.girder;
n2df = com.node.dof;

% KBRACE-MID節点の検索
idnode_mid = find(...
  node.type == PRM.NODE_BRACE_FOR_GIRDER);
if isempty(idnode_mid)
  varargout = varargin;
  return
end

% 入力配列のコピー
narg = length(varargin);
varargout = cell(1, narg);
for ia = 1:narg
  varargout{ia} = varargin{ia};
end

% KBRACE-MID節点ごとに再配分
for k = 1:length(idnode_mid)
  idnode = idnode_mid(k);

  % KBRACE1（左側梁）: idnode2 == MID
  ig1 = find(...
    member_girder.type == PRM.GIRDER_FOR_KBRACE1 ...
    & member_girder.idnode2 == idnode, 1);

  % KBRACE2（右側梁）: idnode1 == MID
  ig2 = find(...
    member_girder.type == PRM.GIRDER_FOR_KBRACE2 ...
    & member_girder.idnode1 == idnode, 1);

  if isempty(ig1) || isempty(ig2)
    continue
  end

  % 隣接グリッド節点
  in_left = member_girder.idnode1(ig1);
  in_right = member_girder.idnode2(ig2);

  % 全6自由度について再配分
  for idof = 1:6
    idf_mid = n2df(idnode, idof);
    idf_left = n2df(in_left, idof);
    idf_right = n2df(in_right, idof);

    for ia = 1:narg
      val = varargout{ia}(idf_mid);
      if val ~= 0
        varargout{ia}(idf_left) = ...
          varargout{ia}(idf_left) + val / 2;
        varargout{ia}(idf_right) = ...
          varargout{ia}(idf_right) + val / 2;
        varargout{ia}(idf_mid) = 0;
      end
    end
  end
end

return
end
