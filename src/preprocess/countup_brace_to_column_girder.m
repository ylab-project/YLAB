function [idmec1, idmec2, idmeg1, idmeg2] = ...
  countup_brace_to_column_girder(com)
%countup_brace_to_column_girder - ブレース端点接続の柱・梁番号を取得
%
%   [idmec1, idmec2, idmeg1, idmeg2] =
%     countup_brace_to_column_girder(com) は、各ブレースの両端
%   （端点1・端点2）に接続する柱および梁の部材番号を取得する。
%   ブレース荷重計算用の部材長（lm_weight）の算出に使用する。
%
%   入力引数:
%     com - 共通オブジェクト
%
%   出力引数:
%     idmec1 - 端点1に接続する柱の部材番号 [nmeb×ncol_c]
%     idmec2 - 端点2に接続する柱の部材番号 [nmeb×ncol_c]
%     idmeg1 - 端点1に接続する梁の部材番号 [nmeb×ncol_g]
%     idmeg2 - 端点2に接続する梁の部材番号 [nmeb×ncol_g]
%
%   備考:
%     - 柱・梁が存在しない場合は0が格納される。
%     - 呼び出し側では ids(ids>0) でフィルタリングして使用する。

% 共通定数
nmeb = com.nmeb;
nmec = com.nmec;
nmeg = com.nmeg;

% ブレース節点
idmeb2n = [com.member.brace.idnode1 com.member.brace.idnode2];

% 柱節点
idmec2n = [com.member.column.idnode1 com.member.column.idnode2];

% 梁節点
idmeg2n = [com.member.girder.idnode1 com.member.girder.idnode2];

% --- 分割節点対応: 梁検索用の節点IDを事前計算 ---
% 分割節点（基礎梁天端）では梁端点と一致しないため、
% 名目部材番号で基礎梁端点ノードを辿る
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
      % BRACE2柱（idnode1 == 分割節点）を検索
      ic_ = iccc(idmec2n(:,1) == inode);
      if isempty(ic_)
        continue
      end
      % 名目部材番号で主柱（BRACE1）を検索
      nominal_id = idnominal(ic_(1), 1);
      ic_primary = iccc(idnominal(:,1) == nominal_id & ...
        idnominal(:,2) == 1);
      if isempty(ic_primary)
        continue
      end
      % BRACE1のidnode1 = 基礎梁端点ノード
      idmeb2n_g(ib, iend) = idmec2n(ic_primary(1), 1);
    end
  end
end

% --- 柱の最大接続本数を調査（端点ごとに上下を合算） ---
maxcol_c = 0;
for ib = 1:nmeb
  for iend = 1:2
    cnt = 0;
    for idu = 1:2  % 1:柱下端, 2:柱上端
      cnt = cnt + sum(idmec2n(:,idu) == idmeb2n(ib,iend));
    end
    maxcol_c = max(maxcol_c, cnt);
  end
end
ncol_c = max(2, maxcol_c);

% --- 梁の最大接続本数を調査（端点ごとにi/j端を合算） ---
iggg = 1:nmeg;
maxcol_g = 0;
for ib = 1:nmeb
  for iend = 1:2
    cnt = 0;
    for idu = 1:2  % 1:梁i端, 2:梁j端
      cnt = cnt + sum(idmeg2n(:,idu) == idmeb2n_g(ib,iend));
    end
    maxcol_g = max(maxcol_g, cnt);
  end
end
ncol_g = max(2, maxcol_g);

% --- 出力配列の初期化 ---
idmec1 = zeros(nmeb, ncol_c);
idmec2 = zeros(nmeb, ncol_c);
idmeg1 = zeros(nmeb, ncol_g);
idmeg2 = zeros(nmeb, ncol_g);

% --- 各ブレースについて接続先を探索 ---
for ib = 1:nmeb
  for iend = 1:2
    % 柱の探索
    idxc = 0;
    iddd_c = zeros(1, ncol_c);
    for idu = 1:2
      idmec_ = iccc(idmec2n(:,idu) == idmeb2n(ib,iend));
      for k = 1:length(idmec_)
        idxc = idxc + 1;
        if idxc <= ncol_c
          iddd_c(idxc) = idmec_(k);
        end
      end
    end

    % 梁の探索（分割節点は基礎梁端点で検索）
    idxg = 0;
    iddd_g = zeros(1, ncol_g);
    for idu = 1:2
      idmeg_ = iggg(idmeg2n(:,idu) == idmeb2n_g(ib,iend));
      for k = 1:length(idmeg_)
        idxg = idxg + 1;
        if idxg <= ncol_g
          iddd_g(idxg) = idmeg_(k);
        end
      end
    end

    % 端点1または端点2に格納
    if iend == 1
      idmec1(ib,:) = iddd_c;
      idmeg1(ib,:) = iddd_g;
    else
      idmec2(ib,:) = iddd_c;
      idmeg2(ib,:) = iddd_g;
    end
  end
end

return
end
