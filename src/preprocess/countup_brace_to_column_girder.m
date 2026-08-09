function [idmec1, idmec2, has_girder1, has_girder2, ...
  idmeg_selected1, idmeg_selected2] = countup_brace_to_column_girder(com)
%countup_brace_to_column_girder - ブレース端点の接続部材を取得
%
%   [idmec1, idmec2, has_girder1, has_girder2,
%     idmeg_selected1, idmeg_selected2] =
%     countup_brace_to_column_girder(com) は、各ブレースの両端に
%   接続する柱と、接続梁の有無、および同一構面でブレース他端側へ
%   伸びる採用梁を取得する。採用梁が複数ある場合は、解析開始前に
%   形状定義の曖昧さとしてエラーにする。
%
%   入力引数:
%     com - 共通オブジェクト
%
%   出力引数:
%     idmec1           - 端点1の接続柱番号 [nmeb×ncol_c]
%     idmec2           - 端点2の接続柱番号 [nmeb×ncol_c]
%     has_girder1      - 端点1の接続梁の有無 [nmeb×1]
%     has_girder2      - 端点2の接続梁の有無 [nmeb×1]
%     idmeg_selected1  - 端点1の採用梁番号 [nmeb×1]
%     idmeg_selected2  - 端点2の採用梁番号 [nmeb×1]
%
%   備考:
%     - 接続柱または採用梁が存在しない場合は0を格納する。
%     - 採用梁は梁とブレースの idir 完全一致で判定する。
%       isxdir/isydir は斜め梁の投影方向であり、この判定には
%       使用しない。
%     - 接続梁の有無は、採用梁がない端の基準レベルを階高レベルに
%       するか節点Zのままにするかの判定に使う。

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

% 出力配列の初期化
idmec1 = zeros(nmeb, ncol_c);
idmec2 = zeros(nmeb, ncol_c);
has_girder1 = false(nmeb, 1);
has_girder2 = false(nmeb, 1);
idmeg_selected1 = zeros(nmeb, 1);
idmeg_selected2 = zeros(nmeb, 1);

% 梁選択に使う幾何配列（エラー表示以外でtableを参照しない）
iggg = 1:nmeg;
girder_idir = com.member.girder.idir;
brace_idir = com.member.brace.idir;
node_x = com.node.x;
node_y = com.node.y;

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

    % 接続梁候補から同一構面で他端側へ伸びる梁を絞り込む
    in_connect = idmeb2n_g(ib, iend);
    idg = iggg(any(idmeg2n == in_connect, 2));
    matched = select_brace_end_girder_(idg, in_connect, ...
      brace_idir(ib), idmeb2n(ib,iend), idmeb2n(ib,3-iend), ...
      girder_idir, idmeg2n, node_x, node_y);
    if isempty(matched)
      ig_selected = 0;
    elseif isscalar(matched)
      ig_selected = matched;
    else
      brace = com.member.brace;
      coord_name = brace.coord_name(ib,:);
      error('YLAB:Geometry:AmbiguousBraceEndGirder', ...
        ['ブレース%d（階:%s、構面:%s、座標:%s-%s、端点:%d）の' ...
        '採用梁を一意に決定できません。候補梁:%s'], brace.idme(ib), ...
        brace.floor_name{ib}, brace.frame_name{ib}, coord_name{1}, ...
        coord_name{2}, iend, format_id_list(matched));
    end

    if iend == 1
      idmec1(ib,:) = iddd_c;
      has_girder1(ib) = ~isempty(idg);
      idmeg_selected1(ib) = ig_selected;
    else
      idmec2(ib,:) = iddd_c;
      has_girder2(ib) = ~isempty(idg);
      idmeg_selected2(ib) = ig_selected;
    end
  end
end

return
end

function matched = select_brace_end_girder_(idg, in_connect, ...
  brace_idir, in_this, in_far, girder_idir, idmeg2n, node_x, node_y)
%select_brace_end_girder_ - ブレース他端側へ伸びる梁を絞り込む
%
%   matched = select_brace_end_girder_(idg, in_connect,
%     brace_idir, in_this, in_far, girder_idir, idmeg2n,
%     node_x, node_y) は、端点に接続する梁候補から、ブレースと
%   同じ構面で他端側へ伸びる梁を返す。
%
%   入力引数:
%     idg         - 接続梁候補番号
%     in_connect  - 候補梁側の接続節点番号（分割節点解決済み）
%     brace_idir  - ブレースの構面方向
%     in_this     - ブレース自端の節点番号
%     in_far      - ブレース他端の節点番号
%     girder_idir - 梁の構面方向 [nmeg×1]
%     idmeg2n     - 梁の両端節点番号 [nmeg×2]
%     node_x      - 節点X座標 [nnode×1]
%     node_y      - 節点Y座標 [nnode×1]
%
%   出力引数:
%     matched - 条件を満たす梁番号（空=該当なし）

db = [node_x(in_far) - node_x(in_this), node_y(in_far) - node_y(in_this)];
is_match = false(size(idg));
for icand = 1:length(idg)
  ig_ = idg(icand);
  if girder_idir(ig_) ~= brace_idir
    continue
  end

  % 接続節点でない側の梁端点で他端方向を判定する
  gnodes = idmeg2n(ig_,:);
  in_other = gnodes(gnodes ~= in_connect);
  dg = [node_x(in_other) - node_x(in_this), ...
    node_y(in_other) - node_y(in_this)];
  is_match(icand) = db * dg' > 0;
end
matched = idg(is_match);

return
end
