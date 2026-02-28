function lk_brace = calc_brace_buckling_length(...
  member_brace, member_girder, node, ...
  stype_sec, idsecg2sec, secdim, position_fg)
%calc_brace_buckling_length - SS7 3.8.1のブレース座屈長Lを算出
%
%   lk_brace = calc_brace_buckling_length(
%     member_brace, member_girder, node,
%     stype_sec, idsecg2sec, secdim,
%     position_fg) は、
%   SS7 3.8.1で定義されるブレース長さLを算出する。
%   calc_brace_lengthで部材長を算出し、K下形+基礎梁
%   天端(TOP)のみLzをHg/2シフトして座屈長を再計算する。
%
%   入力引数:
%     member_brace  - ブレース部材テーブル
%     member_girder - 梁部材テーブル
%     node          - 節点テーブル (x, y, z, type)
%     stype_sec     - 断面種別配列 [nsec×1]
%     idsecg2sec    - 梁断面ID→統一断面ID変換配列
%     secdim        - 断面寸法配列 [nsec×ncol]
%     position_fg   - 基礎梁接続位置オプション
%
%   出力引数:
%     lk_brace - ブレース座屈長 [nmeb×1]
%
%   備考:
%     - K下形+基礎梁天端(TOP)のみZ-shiftを適用
%     - K上形/X形は分割節点で天端移動済み
%     - CENTER時はシフトなし（座屈長=部材長）

% 部材長をベースとして使用
[lk_brace, Lx_all, Lz_all] = calc_brace_length(...
  member_brace, member_girder, node);

if position_fg ...
    ~= PRM.BRACE_FOUNDATION_GIRDER_TOP
  return
end

% K下形+基礎梁接続のブレースを抽出
is_k_lower = member_brace.type ...
  == PRM.BRACE_MEMBER_TYPE_K_LOWER;
has_fg = any(member_brace.onfg, 2);
idx_target = find(is_k_lower & has_fg);
if isempty(idx_target)
  return
end

% 梁せいの取得（基礎梁天端シフト用）
Hg = zeros(size(secdim,1), 1);
Hg(stype_sec==PRM.WFS) = ...
  secdim(stype_sec==PRM.WFS, 1);
Hg(stype_sec==PRM.RCRS) = ...
  secdim(stype_sec==PRM.RCRS, 2);
idmg2s = idsecg2sec(member_girder.idsecg);
Hg_gir = Hg(idmg2s);

% 接続する梁の部材番号（両端）
brc_idmeg1 = member_brace.idmeg1;
brc_idmeg2 = member_brace.idmeg2;

% K下形のみLzシフト→座屈長を再計算
for ib = idx_target'
  Lz = Lz_all(ib);

  % 端点1側: 基礎梁ならLzを減少（上シフト）
  idg1 = brc_idmeg1(ib,:);
  idg1 = idg1(idg1 > 0);
  idg1_fg = idg1(member_girder.isfg(idg1));
  if ~isempty(idg1_fg)
    Lz = Lz - Hg_gir(idg1_fg(1)) / 2;
  end

  % 端点2側: 基礎梁ならLzを増加（上シフト）
  idg2 = brc_idmeg2(ib,:);
  idg2 = idg2(idg2 > 0);
  idg2_fg = idg2(member_girder.isfg(idg2));
  if ~isempty(idg2_fg)
    Lz = Lz + Hg_gir(idg2_fg(1)) / 2;
  end

  lk_brace(ib) = sqrt(Lx_all(ib)^2 + Lz^2);
end

return
end
