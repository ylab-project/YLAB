function [asrbhead, asrbbody] = ...
  write_cell_allowable_stress_ratio_brace(com, result)
%write_cell_allowable_stress_ratio_brace - ブレース検定比一覧

% 定数
nmb = com.nmeb;
nsb = com.nsecb;

% 共通配列
brace = com.member.brace;
secb = com.section.brace;
nominal_brace = com.nominal.brace;
nnb = com.num.nominal_brace;

% 許容応力度比（物理ブレース単位）
bnij = result.bnij;

asrbhead = {'符号','N',''; '','左下り','右下り'};

% --- ブレース検定比一覧 ---
asrbbody = cell(0,size(asrbhead,2));
if nsb==0 || isempty(bnij)
  return
end

% 左右列割り当て: 1=左下り、2=右下り
% X型: pair値（傾斜方向）で判定
% K型: nominal_braceの登録順（1番目=左側、2番目=右側）
side = zeros(nmb, 1);
for ib = 1:nmb
  if brace.type(ib) == PRM.BRACE_MEMBER_TYPE_X
    if ismember(brace.pair(ib), [PRM.BRACE_MEMBER_PAIR_L, ...
        PRM.BRACE_MEMBER_PAIR_BOTH_L])
      side(ib) = 1;
    else
      side(ib) = 2;
    end
  end
end
for inb = 1:nnb
  ibij = nominal_brace.idmeb(inb, :);
  if brace.type(ibij(1)) == PRM.BRACE_MEMBER_TYPE_X
    continue
  end
  for ij = 1:nnz(ibij)
    side(ibij(ij)) = ij;
  end
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
  imbl = ibbb(brace.idsecb==isb & side==1);
  if ~isempty(imbl)
    bnl_ = max(bnmax(imbl));
    asrbbody{irow,2} = sprintf('%.2f', ceil(bnl_*100)/100);
  end

  % 右下り
  imbr = ibbb(brace.idsecb==isb & side==2);
  if ~isempty(imbr)
    bnr_ = max(bnmax(imbr));
    asrbbody{irow,3} = sprintf('%.2f', ceil(bnr_*100)/100);
  end
end

return
end
