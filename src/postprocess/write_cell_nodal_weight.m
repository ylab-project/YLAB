function [nwhead, nwbody] = write_cell_nodal_weight(com, result)
%writeSectionProperties - Write section properties

% 定数
nn = com.nnode;
nblx = com.nblx;
nbly = com.nbly;
nstory = com.nstory;

% 共通配列
% feqvec = result.feqvec(:,1);
feqvec = result.felement(:,1);
node = com.node;
n2df = com.node.dof;
sw = result.sw;

% --- 節点重量表 ---
nwhead = {...
  'X軸', 'Y軸', '層', '床自重', '梁自重', '壁自重', ...
  '特殊荷重', '柱自重', '補正', 'ﾌﾚｰﾑ外', '基礎重量', '合計', ...
  '概算軸力', '概算軸力TL';
	'', '', '', 'kN', 'kN', 'kN', ...
  'kN', 'kN', 'kN', 'kN', 'kN', 'kN', ...
  'kN', 'kN'};
nwbody = cell(nn*2,14);
innn = 1:nn;
irow = 0;
for iy = 1:nbly
  for ix = 1:nblx
    for i = 1:nstory
      ist = nstory-i+1;
      in = innn(node.idx==ix & node.idy==iy & node.idstory==ist);
      if isempty(in)
        continue
      end
      % 同一化された節点はスキップ（代表節点に統合済み）
      if node.idrep(in) > 0
        continue
      end
      irow = irow+1;
      nwbody{irow*2-1,1} = node.xname{in};
      nwbody{irow*2-1,2} = node.yname{in};
      nwbody{irow*2-1,3} = node.zname{in};
      idf = n2df(in,3);
      nwbody{irow*2-1,4} = sprintf('%.1f', feqvec(idf)*1.d-3);
      nwbody{irow*2,5} = sprintf('%.1f', sw.fg(idf)*1.d-3);
      nwbody{irow*2,8} = sprintf('%.1f', sw.fc(idf)*1.d-3);
      nwbody{irow*2,12} = sprintf('%.1f', (feqvec(idf)+sw.f(idf))*1.d-3);
      % nwbody{irow*2-1,13} = sprintf('%.1f', feqvec(idf)*1.d-3);
      % nwbody{irow*2,13} = sprintf('%.1f', (sw.f(idf))*1.d-3);
      % nwbody{irow*2,14} = sprintf('%.1f', (feqvec(idf)+sw.f(idf))*1.d-3);
    end
  end
end
return
end
