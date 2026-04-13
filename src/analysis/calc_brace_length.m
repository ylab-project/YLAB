function [lm_brace, Lx_all, Lz_all] = calc_brace_length(...
  member_brace, member_girder, node)
%calc_brace_length - ブレース部材長を算出
%
%   [lm_brace, Lx_all, Lz_all] = calc_brace_length(
%     member_brace, member_girder, node) は、
%   ブレース端点間の斜め距離（構造心間距離）を算出する。
%   glv（梁レベル調整）を考慮し、分割節点では
%   nodezに反映済みのためglvをスキップする。
%
%   入力引数:
%     member_brace  - ブレース部材テーブル
%     member_girder - 梁部材テーブル
%     node          - 節点テーブル (x, y, z, type)
%
%   出力引数:
%     lm_brace - ブレース部材長 [nmeb×1]
%     Lx_all   - 水平距離 [nmeb×1]
%     Lz_all   - 鉛直距離（glv補正後） [nmeb×1]

nmeb = length(member_brace.idme);

% 水平距離
Lx_all = calc_brace_Lx(member_brace, node);

% ブレース節点
idnode1 = member_brace.idnode1;
idnode2 = member_brace.idnode2;

% 接続する梁の部材番号（両端）
brc_idmeg1 = member_brace.idmeg1;
brc_idmeg2 = member_brace.idmeg2;

% 梁レベル調整（下げが負）
glv = member_girder.level;

lm_brace = zeros(nmeb, 1);
Lz_all = zeros(nmeb, 1);

for ib = 1:nmeb
  in1 = idnode1(ib);
  in2 = idnode2(ib);

  % 分割節点判定（glvスキップ用）
  is_split1 = node.type(in1) == PRM.NODE_BRACE_FOR_COLUMN;
  is_split2 = node.type(in2) == PRM.NODE_BRACE_FOR_COLUMN;

  % glv補正（分割節点はnodezに反映済み）
  idg1 = brc_idmeg1(ib,:);
  idg1 = idg1(idg1 > 0);
  if is_split1 || isempty(idg1)
    max_glv1 = 0;
  else
    max_glv1 = glv(idg1(1));
  end

  idg2 = brc_idmeg2(ib,:);
  idg2 = idg2(idg2 > 0);
  if is_split2 || isempty(idg2)
    max_glv2 = 0;
  else
    max_glv2 = glv(idg2(1));
  end

  Lz = node.z(in2) - node.z(in1) + max_glv2 - max_glv1;

  % --- 斜め距離（部材長） ---
  Lz_all(ib) = Lz;
  lm_brace(ib) = sqrt(Lx_all(ib)^2 + Lz^2);
end

return
end
