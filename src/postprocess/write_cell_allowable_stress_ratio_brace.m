function [asrbhead, asrbbody] = ...
  write_cell_allowable_stress_ratio_brace(com, result)
%write_cell_allowable_stress_ratio_brace - ブレース検定比一覧を生成
%
%   [asrbhead, asrbbody] = ...
%     write_cell_allowable_stress_ratio_brace(com, result) は、
%   ブレース断面ごとの検定比（左下り/右下り最大）をセル配列として返す。
%
%   入力引数:
%     com    - 共通オブジェクト
%     result - 結果構造体（bnij を使用）
%
%   出力引数:
%     asrbhead - ヘッダセル配列 [2×3]
%     asrbbody - データセル配列 [nsb×3]

nmb = com.nmeb;
nsb = com.nsecb;

brace = com.member.brace;
secb = com.section.brace;
nominal_brace = com.nominal.brace;
nnb = com.num.nominal_brace;

% 許容応力度比（物理ブレース単位）
bnij = result.bnij;

asrbhead = {'符号','N',''; '','左下り','右下り'};

asrbbody = cell(0,size(asrbhead,2));
if nsb==0 || isempty(bnij)
  return
end

% 左右列割り当て: 1=左下り(左側)、2=右下り(右側)
% X型: brace.pair で判定
% K型: idmeb の列番号（1列目=左側、2列目=右側、物理位置）
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
  nz = find(ibij > 0);
  ib1 = ibij(nz(1));
  if brace.type(ib1) == PRM.BRACE_MEMBER_TYPE_X
    continue
  end
  for ij = nz
    side(ibij(ij)) = ij;
  end
end

bnij = bnij+1;
bnmax = max(bnij,[],2);
asrbbody = cell(nsb,3);
ibbb = 1:nmb;
irow = 0;

% SS7 仕様に合わせ符号昇順で出力（secb の登録順ではない）
[~, sort_idx] = sort(secb.name);

for k = 1:nsb
  isb = sort_idx(k);
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
