function [asrbhead, asrbbody] = ...
  write_cell_allowable_stress_ratio_brace(com, result)

% 定数
nmb = com.nmeb;
nsb = com.nsecb;

% 共通配列
brace = com.member.brace;
secb = com.section.brace;

% 許容応力度比（物理ブレース単位）
bnij = result.bnij;

asrbhead = {'符号','N',''; ...
  '','左下り','右下り'};

% --- ブレース検定比一覧 ---
asrbbody = cell(0,size(asrbhead,2));
if nsb==0 || isempty(bnij)
  return
end
bnij = bnij+1;
bnmax = max(bnij,[],2);
asrbbody = cell(nsb,3);
ibbb = 1:nmb;
irow = 0;
for isb = 1:nsb
  irow = irow+1;
  asrbbody{irow,1} = sprintf('%s', secb.name{isb});

  % 左下り
  imbl = ibbb(brace.idsecb==isb & ...
    ismember(brace.pair, ...
      [PRM.BRACE_MEMBER_PAIR_L, ...
       PRM.BRACE_MEMBER_PAIR_BOTH_L]));
  if ~isempty(imbl)
    bnl_ = max(bnmax(imbl));
    asrbbody{irow,2} = ...
      sprintf('%.2f', ceil(bnl_ * 100) / 100);
  end

  % 右下り
  imbr = ibbb(brace.idsecb==isb & ...
    ismember(brace.pair, ...
      [PRM.BRACE_MEMBER_PAIR_R, ...
       PRM.BRACE_MEMBER_PAIR_BOTH_R]));
  if ~isempty(imbr)
    bnr_ = max(bnmax(imbr));
    asrbbody{irow,3} = ...
      sprintf('%.2f', ceil(bnr_ * 100) / 100);
  end
end

return
end
