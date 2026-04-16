function [nominal_brace, idnominal_brace] = countup_nominal_brace(com)
%countup_nominal_brace - 名目ブレースの束ね情報を作成
%
%   [nominal_brace, idnominal_brace] = countup_nominal_brace(com) は、
%   左右のブレースペアを名目ブレースとして束ねる。片側のみの
%   ブレースも単独の名目ブレースとして扱う。
%
%   入力引数:
%     com - 共通データ構造体（member.braceテーブルを含む）
%
%   出力引数:
%     nominal_brace   - 名目ブレース情報 (table)
%                       変数: idmeb, idsub, coord_name, floor_name,
%                       frame_name, idstory, idir, idx, idy, type
%     idnominal_brace - 各ブレースの[名目ブレース番号, サブ番号] [nb×2]
%
%   備考:
%     - idmeb の 1列目=左側、2列目=右側（物理位置）
%     - K下は brace.pair と物理位置が反転するため type+pair で列を決定
%     - ブレースペア情報は PRM.BRACE_MEMBER_PAIR_* 定数で判定

brace = com.member.brace;
nb = size(brace, 1);

used = false(nb,1);
idmeb = zeros(nb,2);
idsub = zeros(nb,2);
idn = 0;

for ib=1:nb
  if used(ib)
    continue
  end

  used(ib) = true;
  idn = idn+1;

  is_k = brace.type(ib) == PRM.BRACE_MEMBER_TYPE_K_UPPER ...
    || brace.type(ib) == PRM.BRACE_MEMBER_TYPE_K_LOWER;
  is_k_lower = brace.type(ib) == PRM.BRACE_MEMBER_TYPE_K_LOWER;

  switch brace.pair(ib)
    case {PRM.BRACE_MEMBER_PAIR_L, PRM.BRACE_MEMBER_PAIR_R}
      % 片側のみのブレース（ペアなし）
      if is_k
        % K上: PAIR_L(／)→左, PAIR_R(＼)→右
        % K下: PAIR_L(／)→右, PAIR_R(＼)→左（物理位置が反転）
        is_pair_l = brace.pair(ib) == PRM.BRACE_MEMBER_PAIR_L;
        is_pair_r = brace.pair(ib) == PRM.BRACE_MEMBER_PAIR_R;
        is_left = (is_pair_l && ~is_k_lower) || (is_pair_r && is_k_lower);
        col = 1 + ~is_left;
      else
        col = 1;              % X形片側は従来どおり1列目
      end
      idmeb(idn, col) = ib;
      idsub(idn, col) = 1;
    case {PRM.BRACE_MEMBER_PAIR_BOTH_L, PRM.BRACE_MEMBER_PAIR_BOTH_R}
      % ペアのブレースも同じ名目ブレースに登録
      ib2 = brace.idpair(ib);
      used(ib2) = true;
      is_l = brace.pair(ib) == PRM.BRACE_MEMBER_PAIR_BOTH_L;
      if is_k
        % K上: BOTH_L→1列目（左）/, BOTH_R→2列目（右）\
        % K下: BOTH_R→1列目（左）\, BOTH_L→2列目（右）/
        col = 1 + xor(is_k_lower, ~is_l);
      else
        % X形: BOTH_L→1列目、BOTH_R→2列目
        col = 1 + ~is_l;
      end
      col2 = 3 - col;
      idmeb(idn, col)  = ib;
      idmeb(idn, col2) = ib2;
      idsub(idn, 1) = 1;
      idsub(idn, 2) = 2;
  end
end

% 配列をトリミング
nnb = idn;
idmeb = idmeb(1:nnb,:);
idsub = idsub(1:nnb,:);

% 名目ブレース属性配列の初期化
coord_name = cell(nnb,2);
floor_name = cell(nnb,1);
frame_name = cell(nnb,1);
idstory = zeros(nnb,1);
idir = zeros(nnb,1);          % 方向（1:X方向, 2:Y方向）
idx = zeros(nnb,2);
idy = zeros(nnb,2);
type = zeros(nnb,1);

% K下片側では1列目が0になるため、最初の非0ブレースを代表とする
for k = 1:nnb
  ib_rep = max(idmeb(k,1), idmeb(k,2));

  coord_name(k,:) = brace.coord_name(ib_rep,:);
  floor_name{k,1} = brace.floor_name{ib_rep,1};
  frame_name{k,1} = brace.frame_name{ib_rep,1};
  idstory(k,1) = brace.idstory(ib_rep);
  idir(k,1) = brace.idir(ib_rep);
  idx(k,:) = brace.idx(ib_rep,:);
  idy(k,:) = brace.idy(ib_rep,:);
  type(k,1) = brace.type(ib_rep);
end

% 逆引きテーブル [nb×2]: 各ブレース → [名目ブレース番号, サブ番号]
idnominal_brace = zeros(nb,2);
for inb = 1:nnb
  for j = 1:2
    ib = idmeb(inb,j);
    if ib>0
      idnominal_brace(ib,:) = [inb j];
    end
  end
end

nominal_brace = table( ...
  idmeb, idsub, coord_name, floor_name, frame_name, ...
  idstory, idir, idx, idy, type, 'VariableNames', ...
  {'idmeb','idsub','coord_name','floor_name','frame_name', ...
  'idstory','idir','idx','idy','type'});

return
end
