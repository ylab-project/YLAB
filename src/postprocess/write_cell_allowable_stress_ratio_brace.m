function [asrbhead, asrbbody] = ...
  write_cell_allowable_stress_ratio_brace(com, result)

% 定数
nmb = com.nmeb;
nsb = com.nsecb;

% 共通配列
brace = com.member.brace;
secb = com.section.brace;
idmb2m = com.member.brace.idme;
mstype = com.member.property.section_type;

% 許容応力度比（名目単位・物理部材単位）
bnij_all = result.bnij;
bnij_member = result.bnij_member;

asrbhead = {'符号','N',''; ...
  '','左下り','右下り'};

% --- ブレース検定比一覧 ---
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
  imbl = ibbb(brace.idsecb==isb & ...
    ismember(brace.pair, ...
      [PRM.BRACE_MEMBER_PAIR_L, PRM.BRACE_MEMBER_PAIR_BOTH_L]));
  if ~isempty(imbl)
    if ~isempty(bnij_member) && mstype(idmb2m(imbl(1))) == PRM.TB
      im_l = idmb2m(imbl);
      bnl_ = max(max(bnij_member(im_l, :), [], 2)) + 1;
    else
      inbl = brace.idnominal(imbl, 1);
      bnl_ = max(bnmax(inbl));
    end
    asrbbody{irow,2} = sprintf('%.2f', bnl_);
  end

  % 右下り
  imbr = ibbb(brace.idsecb==isb & ...
    ismember(brace.pair, ...
      [PRM.BRACE_MEMBER_PAIR_R, PRM.BRACE_MEMBER_PAIR_BOTH_R]));
  if ~isempty(imbr)
    if ~isempty(bnij_member) && mstype(idmb2m(imbr(1))) == PRM.TB
      im_r = idmb2m(imbr);
      bnr_ = max(max(bnij_member(im_r, :), [], 2)) + 1;
    else
      inbr = brace.idnominal(imbr, 1);
      bnr_ = max(bnmax(inbr));
    end
    asrbbody{irow,3} = sprintf('%.2f', bnr_);
  end
end

return
end
