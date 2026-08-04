function [idmec1, idmec2, idmeg1, idmeg2, idmeg_selected1, ...
  idmeg_selected2] = countup_brace_to_column_girder(com)
%countup_brace_to_column_girder - ブレース端点の接続部材を取得
%
%   [idmec1, idmec2, idmeg1, idmeg2,
%     idmeg_selected1, idmeg_selected2] =
%     countup_brace_to_column_girder(com) は、各ブレースの両端に
%   接続する柱・梁候補と、同一構面でブレース他端側へ伸びる
%   採用梁を取得する。採用梁が複数ある場合は、解析開始前に
%   形状定義の曖昧さとしてエラーにする。
%
%   入力引数:
%     com - 共通オブジェクト
%
%   出力引数:
%     idmec1           - 端点1の接続柱番号 [nmeb×ncol_c]
%     idmec2           - 端点2の接続柱番号 [nmeb×ncol_c]
%     idmeg1           - 端点1の接続梁候補 [nmeb×ncol_g]
%     idmeg2           - 端点2の接続梁候補 [nmeb×ncol_g]
%     idmeg_selected1  - 端点1の採用梁番号 [nmeb×1]
%     idmeg_selected2  - 端点2の採用梁番号 [nmeb×1]
%
%   備考:
%     - 接続部材または採用梁が存在しない場合は0を格納する。
%     - 採用梁は梁とブレースの idir 完全一致で判定する。
%       isxdir/isydir は斜め梁の投影方向であり、この判定には
%       使用しない。

nmeb = com.nmeb;
nmec = com.nmec;
nmeg = com.nmeg;

% ブレース節点
idmeb2n = [com.member.brace.idnode1 com.member.brace.idnode2];

% 柱節点
idmec2n = [com.member.column.idnode1 com.member.column.idnode2];

% 梁節点
idmeg2n = [com.member.girder.idnode1 com.member.girder.idnode2];

% 分割節点では名目柱から基礎梁端点を解決する
iccc = 1:nmec;
idmeb2n_g = idmeb2n;
if any(com.node.type == PRM.NODE_BRACE_FOR_COLUMN)
  node_type = com.node.type;
  idnominal = com.member.column.idnominal;
  for ib = 1:nmeb
    for iend = 1:2
      inode = idmeb2n(ib, iend);
      if node_type(inode) ~= PRM.NODE_BRACE_FOR_COLUMN
        continue
      end

      % BRACE2柱から同じ名目部材のBRACE1柱を辿る
      ic_ = iccc(idmec2n(:,1) == inode);
      if isempty(ic_)
        continue
      end
      nominal_id = idnominal(ic_(1), 1);
      ic_primary = iccc(idnominal(:,1) == nominal_id & ...
        idnominal(:,2) == 1);
      if isempty(ic_primary)
        continue
      end
      idmeb2n_g(ib, iend) = idmec2n(ic_primary(1), 1);
    end
  end
end

% 柱の最大接続本数を調査する
maxcol_c = 0;
for ib = 1:nmeb
  for iend = 1:2
    cnt = 0;
    for idu = 1:2
      cnt = cnt + sum(idmec2n(:,idu) == idmeb2n(ib,iend));
    end
    maxcol_c = max(maxcol_c, cnt);
  end
end
ncol_c = max(2, maxcol_c);

% 梁の最大接続本数を調査する
iggg = 1:nmeg;
maxcol_g = 0;
for ib = 1:nmeb
  for iend = 1:2
    cnt = 0;
    for idu = 1:2
      cnt = cnt + sum(idmeg2n(:,idu) == idmeb2n_g(ib,iend));
    end
    maxcol_g = max(maxcol_g, cnt);
  end
end
ncol_g = max(2, maxcol_g);

% 出力配列の初期化
idmec1 = zeros(nmeb, ncol_c);
idmec2 = zeros(nmeb, ncol_c);
idmeg1 = zeros(nmeb, ncol_g);
idmeg2 = zeros(nmeb, ncol_g);
idmeg_selected1 = zeros(nmeb, 1);
idmeg_selected2 = zeros(nmeb, 1);

% 各ブレースについて接続先と採用梁を確定する
for ib = 1:nmeb
  for iend = 1:2
    idxc = 0;
    iddd_c = zeros(1, ncol_c);
    for idu = 1:2
      idmec_ = iccc(idmec2n(:,idu) == idmeb2n(ib,iend));
      for k = 1:length(idmec_)
        idxc = idxc + 1;
        iddd_c(idxc) = idmec_(k);
      end
    end

    % 梁端のi/j情報を採用梁の反対端決定まで保持する
    idxg = 0;
    iddd_g = zeros(1, ncol_g);
    iddd_g_end = zeros(1, ncol_g);
    for idu = 1:2
      idmeg_ = iggg(idmeg2n(:,idu) == idmeb2n_g(ib,iend));
      for k = 1:length(idmeg_)
        idxg = idxg + 1;
        iddd_g(idxg) = idmeg_(k);
        iddd_g_end(idxg) = idu;
      end
    end
    ig_selected = select_brace_end_girder_(iddd_g, iddd_g_end, ...
      com, ib, iend);

    if iend == 1
      idmec1(ib,:) = iddd_c;
      idmeg1(ib,:) = iddd_g;
      idmeg_selected1(ib) = ig_selected;
    else
      idmec2(ib,:) = iddd_c;
      idmeg2(ib,:) = iddd_g;
      idmeg_selected2(ib) = ig_selected;
    end
  end
end

return
end

function ig = select_brace_end_girder_(idg_raw, idg_end_raw, com, ib, iend)
%select_brace_end_girder_ - ブレース他端側へ伸びる梁を選ぶ
%
%   ig = select_brace_end_girder_(idg_raw, idg_end_raw, com,
%     ib, iend) は、端点に接続する梁候補から、ブレースと
%   同じ構面で他端側へ伸びる梁を選ぶ。複数該当する場合は
%   階・構面・座標と候補梁を含むエラーを送出する。
%
%   入力引数:
%     idg_raw     - 接続梁候補番号（0を含む）
%     idg_end_raw - 候補梁の接続端（1=i端、2=j端）
%     com         - 共通オブジェクト
%     ib          - ブレース表の行番号
%     iend        - ブレース端点（1または2）
%
%   出力引数:
%     ig - 採用梁番号（0=該当梁なし）

is_candidate = idg_raw > 0;
idg = idg_raw(is_candidate);
idg_end = idg_end_raw(is_candidate);
brace = com.member.brace;
girder = com.member.girder;
node = com.node;
idnode = [brace.idnode1(ib) brace.idnode2(ib)];
in_this = idnode(iend);
in_far = idnode(3 - iend);
db = [node.x(in_far) - node.x(in_this), node.y(in_far) - node.y(in_this)];
is_match = false(size(idg));

for icand = 1:length(idg)
  ig_ = idg(icand);
  if girder.idir(ig_) ~= brace.idir(ib)
    continue
  end

  if idg_end(icand) == 1
    in_other = girder.idnode2(ig_);
  else
    in_other = girder.idnode1(ig_);
  end
  dg = [node.x(in_other) - node.x(in_this), ...
    node.y(in_other) - node.y(in_this)];
  is_match(icand) = db * dg' > 0;
end

matched = idg(is_match);
if isempty(matched)
  ig = 0;
elseif isscalar(matched)
  ig = matched;
else
  coord_name = brace.coord_name(ib,:);
  error('YLAB:Geometry:AmbiguousBraceEndGirder', ...
    ['ブレース%d（階:%s、構面:%s、座標:%s-%s、端点:%d）の' ...
    '採用梁を一意に決定できません。候補梁:%s'], brace.idme(ib), ...
    brace.floor_name{ib}, brace.frame_name{ib}, coord_name{1}, ...
    coord_name{2}, iend, mat2str(matched));
end

return
end
