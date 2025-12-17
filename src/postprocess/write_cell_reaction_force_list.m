function [rflhead, rflbody] = write_cell_reaction_force_list(com, result, icase)
%writeSectionProperties - Write section properties

% 定数
nsup = com.nsup;
nblx = com.nblx;
nbly = com.nbly;
nstory = com.nstory;

% 共通配列
node = com.node;
support = com.support;
% columm = com.member.column;
% secc = com.section.column;
% lm = com.member.property.lm;
% rvec = result.rvec0(:,icase);
rvec = reshape(result.rvec0(:,icase),6,[])';
% Mc = result.Mc0(:,icase);
% story = com.story;
% dnode = result.dnode;
% feqvec = com.feqvec;
% node = com.node;
% n2df = com.node.dof;
% sw = result.sw;


% --- 変位量（重心位置） ---
rflhead = { ...
'層', 'X軸', 'Y軸', '鉛直', 'X方向', '', 'Y方向', ''; ...
'', '', '', '', '曲げ', '水平', '曲げ', '水平'; ...
'', '', '', 'kN', 'kNm', 'kN', 'kNm', 'kN'};
rflbody = cell(nsup,8);
ids2df = node.dof(support.idnode,:);
isss = 1:nsup;
irow = 0;
for i = 1:nstory
  ist = nstory-i+1;
  for iy = 1:nbly
    for ix = 1:nblx
      is = isss(support.idstory==ist & support.idx(:,1)==ix & ...
        support.idy(:,1)==iy);
      if isempty(is)
        continue
      end
      % rrr = rvec(ids2df(is,:));
      rrr = rvec(is,:);
      if all(abs(rrr)<1.d-3)
        continue
      end
      irow = irow+1;
      rflbody{irow,1} = support.story_name{is};
      rflbody{irow,2} = support.xname{is};
      rflbody{irow,3} = support.yname{is};      
      rflbody{irow,4} = sprintf('%.1f', rrr(3)*1.d-3);
      rflbody{irow,5} = sprintf('%.1f', -rrr(5)*1.d-6);
      rflbody{irow,6} = sprintf('%.1f', rrr(1)*1.d-3);
      rflbody{irow,7} = sprintf('%.1f', rrr(4)*1.d-6);
      rflbody{irow,8} = sprintf('%.1f', rrr(2)*1.d-3);
    end
  end
end

return
end
