function lm_brace_buckling = calc_brace_buckling_length(...
  member, node, section, secdim, options)
%calc_brace_buckling_length - ブレース座屈長Lを算出
%
%   lm_brace_buckling = calc_brace_buckling_length(
%     member, node, section, secdim, options) は、SS7 3.8.1の
%   ブレース長さLを算出する。解析用の取り付き位置とは独立して
%   基礎柱・基礎梁の天端を採用する。RC下端は梁天端を使う。
%   RC柱（PRM.RCRS）に取り付く端はブレース他端に近い柱面を端点と
%   し、構面方向の柱幅の半分を水平距離から控除する。その他の柱は
%   SS7 3.8.1のとおり鉄骨心を端点とし、控除しない。
%   idnode1は下端、idnode2は上端である前提とする。
%
%   入力引数:
%     member  - 接続柱梁と入力柱の端点を持つ部材データ
%     node    - 節点データ (z, z_standard, type)
%     section - 断面種別と部材別断面の対応
%     secdim  - 断面寸法 [nsec×ncol] (mm)
%     options - 基礎柱・基礎梁の天端の選択を持つオプション
%
%   出力引数:
%     lm_brace_buckling - ブレース長さL [nmeb×1] (mm)

member_brace = member.brace;
member_girder = member.girder;
stype_sec = section.property.type;
idsecg2sec = section.girder.idsec;

% RC柱に取り付く端は柱幅の半分を控除し、他端に近い柱面を端点にする。
% 柱幅は構面方向の断面寸法（第1列）を柱単位で求め、RC柱以外は控除
% しないため0にする。
member_column = member.column;
idmc2s = section.column.idsec(member_column.idsecc);
Dc_col = calc_column_outer_size(secdim(idmc2s, :), stype_sec(idmc2s), 1);
Dc_col(stype_sec(idmc2s) ~= PRM.RCRS, :) = 0;
Lx_inner_all = calc_brace_Lx_inner(member_brace, member_column, ...
  node, Dc_col);

% 梁せい・梁種別の取得
idmg2s = idsecg2sec(member_girder.idsecg);
stype_gir = stype_sec(idmg2s);
Hg_gir = calc_girder_section_depth(secdim, stype_gir, idmg2s);

% 梁レベル調整
glv = member_girder.level;

% 接続梁の有無・採用梁・ブレース節点
has_girder1 = member_brace.has_girder1;
has_girder2 = member_brace.has_girder2;
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

  % 採用梁がない端は既存の接続条件による基準高さを使う。
  % 基礎部の柱端は後段で指定された天端へ置き換える。
  z1 = node.z(in1);
  if ig1 == 0 && has_girder1(ib) ...
      && node.type(in1) ~= PRM.NODE_BRACE_FOR_COLUMN
    z1 = node.z_standard(in1);
  end
  z2 = node.z(in2);
  if ig2 == 0 && has_girder2(ib) ...
      && node.type(in2) ~= PRM.NODE_BRACE_FOR_COLUMN
    z2 = node.z_standard(in2);
  end
  is_split1 = node.type(in1) == PRM.NODE_BRACE_FOR_COLUMN;
  is_split2 = node.type(in2) == PRM.NODE_BRACE_FOR_COLUMN;

  if ig1 > 0 && ~is_split1
    if stype_gir(ig1) == PRM.WFS
      z1 = girder_center_z_standard(node.z_standard(in1), ...
        glv(ig1), Hg_gir(ig1));
    else
      if stype_gir(ig1) == PRM.RCRS
        z1 = node.z_standard(in1) + glv(ig1);
      else
        z1 = z1 + glv(ig1);
      end
    end
  end
  if ig2 > 0 && ~is_split2
    if stype_gir(ig2) == PRM.WFS
      z2 = girder_center_z_standard(node.z_standard(in2), ...
        glv(ig2), Hg_gir(ig2));
    else
      z2 = z2 + glv(ig2);
      if stype_gir(ig2) == PRM.RCRS
        z2 = z2 - Hg_gir(ig2) / 2;
      end
    end
  end

  % 柱端の物理的な高さは解析節点や同スパン梁の有無と分けて求める。
  ztop = calc_brace_foundation_z(ib, member, node, options);
  if ~isnan(ztop)
    z1 = ztop;
  end

  Lz = z2 - z1;
  lm_brace_buckling(ib) = sqrt(Lx_inner_all(ib)^2 + Lz^2);
end

return
end
