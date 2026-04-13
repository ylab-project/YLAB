function lm_brace_buckling = calc_brace_buckling_length(...
  member_brace, member_girder, node, stype_sec, idsecg2sec, secdim)
%calc_brace_buckling_length - ブレース座屈長Lを算出
%
%   lm_brace_buckling = calc_brace_buckling_length(
%     member_brace, member_girder, node,
%     stype_sec, idsecg2sec, secdim) は、
%   SS7 3.8.1で定義されるブレース長さLを算出する。
%   node.z_standard（基準階高ベース）から各端の梁せい
%   オフセットを適用し座屈長を算出する。
%
%   入力引数:
%     member_brace  - ブレース部材テーブル
%     member_girder - 梁部材テーブル
%     node          - 節点テーブル (z_standard 必須)
%     stype_sec     - 断面種別配列 [nsec×1]
%     idsecg2sec    - 梁断面ID→統一断面ID変換配列
%     secdim        - 断面寸法配列 [nsec×ncol]
%
%   出力引数:
%     lm_brace_buckling - ブレース長さ L [nmeb×1]
%
%   備考:
%     ブレース端の位置（node.z_standard からのオフセット）:
%       S梁:  梁心（-H/2）
%       RC梁下端: 天端（0）、RC梁上端: 下面（-H）
%     梁レベル調整（glv）を加算

% 水平距離
Lx_all = calc_brace_Lx(member_brace, node);

% 梁せいの取得
Hg = zeros(size(secdim,1), 1);
Hg(stype_sec==PRM.WFS) = secdim(stype_sec==PRM.WFS, 1);
Hg(stype_sec==PRM.RCRS) = secdim(stype_sec==PRM.RCRS, 2);
idmg2s = idsecg2sec(member_girder.idsecg);
Hg_gir = Hg(idmg2s);
stype_gir = stype_sec(idmg2s);

% 梁レベル調整
glv = member_girder.level;

% 接続梁・ブレース節点
brc_idmeg1 = member_brace.idmeg1;
brc_idmeg2 = member_brace.idmeg2;
idnode1 = member_brace.idnode1;
idnode2 = member_brace.idnode2;

% 初期化
nmeb = length(member_brace.idme);
lm_brace_buckling = zeros(nmeb, 1);

for ib = 1:nmeb
  in1 = idnode1(ib);
  in2 = idnode2(ib);

  % 接続梁
  idg1 = brc_idmeg1(ib,:);
  idg1 = idg1(idg1 > 0);
  idg2 = brc_idmeg2(ib,:);
  idg2 = idg2(idg2 > 0);

  % z_standard + glv
  [z1, ig1] = endpoint_z(node.z_standard(in1), idg1, glv);
  [z2, ig2] = endpoint_z(node.z_standard(in2), idg2, glv);

  % 梁せいオフセット（SS7 3.8.1）
  % S梁: 梁心(-H/2)、RC梁下端: 天端(0)
  if ig1 > 0
    if stype_gir(ig1) == PRM.WFS
      z1 = z1 - Hg_gir(ig1) / 2;
    end
  end
  if ig2 > 0
    if stype_gir(ig2) == PRM.WFS
      z2 = z2 - Hg_gir(ig2) / 2;
    elseif stype_gir(ig2) == PRM.RCRS
      z2 = z2 - Hg_gir(ig2);
    end
  end

  Lz = z2 - z1;
  lm_brace_buckling(ib) = sqrt(Lx_all(ib)^2 + Lz^2);
end

return
end
