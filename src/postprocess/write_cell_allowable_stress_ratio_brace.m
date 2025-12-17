function [asrbhead, asrbbody] = ...
  write_cell_allowable_stress_ratio_brace(com, result)

% 定数
nmb = com.nmeb;
nsb = com.nsecb;
nlc = com.nlc;
nstory = com.nstory;
nnb = nmb;

% 共通配列
brace = com.member.brace;
secb = com.section.brace;

% 梁許容応力度比（部材単位の各ケース最大値）
bnij_all = result.bnij;

asrbhead = {'符号','N',''; ...
  '','左下り','右下り'};

% --- S柱断面算定表 ---
asrbbody = cell(0,size(asrbhead,2));
if nsb==0 || isempty(bnij_all)
  return
end
bnij = bnij_all+1;
bnmax = max(bnij,[],2);
asrbbody = cell(nsb,3);
ibbb = 1:nmb;
irow = 0;
for isb = 1:nsb
  irow = irow+1;
  asrbbody{irow,1} = sprintf('%s', secb.name{isb});

  % 左下り
  imbl = ibbb(brace.idsecb==isb&brace.pair==PRM.BRACE_MEMBER_PAIR_L);
  if ~isempty(imbl)
    bnl_ = max(bnmax(imbl));
    asrbbody{irow,2} = sprintf('%.2f', bnl_);
  end

  % 右下り
  imbr = ibbb(brace.idsecb==isb&brace.pair==PRM.BRACE_MEMBER_PAIR_R);
  if ~isempty(imbr)
    bnr_ = max(bnmax(imbr));
    asrbbody{irow,3} = sprintf('%.2f', bnr_);
  end
end
return
end
