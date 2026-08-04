function lm_brace_buckling = calc_brace_buckling_length(...
  member_brace, member_girder, node, stype_sec, idsecg2sec, secdim)
%calc_brace_buckling_length - ブレース座屈長Lを算出
%
%   lm_brace_buckling = calc_brace_buckling_length(
%     member_brace, member_girder, node,
%     stype_sec, idsecg2sec, secdim) は、
%   SS7 3.8.1 で定義されるブレース長さ L を算出する。
%   S梁に取り付く端は梁部材心、RC梁に取り付く端は他点に近い
%   方のコンクリート面をブレース端として扱う。
%   idnode1 は常に下端、idnode2 は常に上端である前提。
%
%   入力引数:
%     member_brace  - ブレース部材テーブル
%     member_girder - 梁部材テーブル
%     node          - 節点テーブル (z, z_standard 必須)
%     stype_sec     - 断面種別配列 [nsec×1]
%     idsecg2sec    - 梁断面ID→統一断面ID変換配列
%     secdim        - 断面寸法配列 [nsec×ncol]
%
%   出力引数:
%     lm_brace_buckling - ブレース長さ L [nmeb×1]

% 水平距離
Lx_all = calc_brace_Lx(member_brace, node);

% 梁せい・梁種別の取得
idmg2s = idsecg2sec(member_girder.idsecg);
stype_gir = stype_sec(idmg2s);
Hg_gir = calc_girder_section_depth(secdim, stype_gir, idmg2s);

% 梁レベル調整
glv = member_girder.level;

% 接続梁候補・採用梁・ブレース節点
has_girder1 = any(member_brace.idmeg1 > 0, 2);
has_girder2 = any(member_brace.idmeg2 > 0, 2);
selected_girder1 = member_brace.idmeg_selected1;
selected_girder2 = member_brace.idmeg_selected2;
idnode1 = member_brace.idnode1;
idnode2 = member_brace.idnode2;

nmeb = length(member_brace.idme);
lm_brace_buckling = zeros(nmeb, 1);

for ib = 1:nmeb
  in1 = idnode1(ib);
  in2 = idnode2(ib);

  ig1 = selected_girder1(ib);
  ig2 = selected_girder2(ib);

  z1 = node.z(in1);
  if ig1 == 0 && has_girder1(ib)
    z1 = node.z_standard(in1);
  end
  z2 = node.z(in2);
  if ig2 == 0 && has_girder2(ib)
    z2 = node.z_standard(in2);
  end
  is_split1 = node.type(in1) == PRM.NODE_BRACE_FOR_COLUMN;
  is_split2 = node.type(in2) == PRM.NODE_BRACE_FOR_COLUMN;

  if ig1 > 0
    if ~is_split1 && stype_gir(ig1) == PRM.WFS
      z1 = girder_center_z_standard(node.z_standard(in1), ...
        glv(ig1), Hg_gir(ig1));
    else
      z1 = z1 + glv(ig1);
      if ~is_split1 && stype_gir(ig1) == PRM.RCRS
        z1 = z1 + Hg_gir(ig1) / 2;
      end
    end
  end
  if ig2 > 0
    if ~is_split2 && stype_gir(ig2) == PRM.WFS
      z2 = girder_center_z_standard(node.z_standard(in2), ...
        glv(ig2), Hg_gir(ig2));
    else
      z2 = z2 + glv(ig2);
      if ~is_split2 && stype_gir(ig2) == PRM.RCRS
        z2 = z2 - Hg_gir(ig2) / 2;
      end
    end
  end

  Lz = z2 - z1;
  lm_brace_buckling(ib) = sqrt(Lx_all(ib)^2 + Lz^2);
end

return
end
