function [nlhead, nlbody] = write_cell_nodal_equiv_load(...
  com, result, doRedistribute)
%write_cell_nodal_equiv_load - 等価節点荷重の出力セル配列を生成
%
% 節点単位の等価節点荷重 (fnode+faddnode-felement-sw.f) を
% そのまま表示する。剛床集約や偏心モーメント加算は行わないため、
% 剛床上の各節点には純粋な節点荷重寄与が表示される。
%
% doRedistribute: KBRACE-MID荷重をグリッド節点に再配分するか
%   true（既定）: 再配分する（節点重量表と整合）
%   false: 再配分しない（SS7等価節点荷重と比較用）

if nargin < 3
  doRedistribute = true;
end

% 定数
nn = com.nnode;
nblx = com.nblx;
nbly = com.nbly;
nstory = com.nstory;
nlc = com.nlc;

% 共通配列（すべて (nnode, 6) / (nnode, 6, nlc)）
node = com.node;
sw = result.sw;
sw_f_lc = zeros(nn, 6, nlc);
sw_f_lc(:, :, 1) = sw.f;
fvec_nnode = com.fnode + com.faddnode - result.felement - sw_f_lc;

% KBRACE-MID節点の等価荷重をグリッド節点に再配分（出力表示用）
if doRedistribute
  fvec_nnode = redistribute_kbrace_mid(com, fvec_nnode);
end

% --- 等価節点荷重 ---
nlhead = {...
  '層','X軸','Y軸','PX','PY','PZ','MX','MY','MZ'; ...
  '', '', '', 'kN', 'kN', 'kN', 'kNm', 'kNm', 'kNm'};
nlbody = cell(nn,9);
innn = 1:nn;
irow = 0;
for i = 1:nstory
  ist = nstory-i+1;
  for iy = 1:nbly
    for ix = 1:nblx
      in = innn(node.idx==ix & node.idy==iy & node.idstory== ist ...
        & (node.type==PRM.NODE_STANDARD ...
        | node.type==PRM.NODE_FLEX_DIAPHRAGM));
      if isempty(in)
        continue
      end
      % 同一化された節点はスキップ（代表節点に統合済み）
      if node.idrep(in) > 0
        continue
      end
      irow = irow+1;
      nlbody{irow,1} = node.zname{in};
      nlbody{irow,2} = node.xname{in};
      nlbody{irow,3} = node.yname{in};
      fff = reshape(fvec_nnode(in, :, 1), 1, 6) ...
        .*[1.d-3 1.d-3 1.d-3 1.d-6 1.d-6 1.d-6];
      fff = [fff(1:3) -fff(5) fff(4) fff(6)];
      for j=1:6
        nlbody{irow,3+j} = sprintf('%.2f',fff(j));
      end
    end
  end
end
return
end
