function lm_brace_buckling = calc_brace_buckling_length(...
  member_brace, member_girder, node, stype_sec, idsecg2sec, secdim)
%calc_brace_buckling_length - ブレース座屈長Lを算出
%
%   lm_brace_buckling = calc_brace_buckling_length(
%     member_brace, member_girder, node,
%     stype_sec, idsecg2sec, secdim) は、
%   SS7 3.8.1 で定義されるブレース長さ L を算出する。
%   node.z（構造心ベース）に梁レベル調整 glv を加えて端部Z座標を
%   求め、RC梁に取り付く端はコンクリートとの重複を除くため
%   近い方のコンクリート面まで梁せい/2 オフセットする。
%   idnode1 は常に下端、idnode2 は常に上端である前提。
%
%   入力引数:
%     member_brace  - ブレース部材テーブル
%     member_girder - 梁部材テーブル
%     node          - 節点テーブル (z 必須)
%     stype_sec     - 断面種別配列 [nsec×1]
%     idsecg2sec    - 梁断面ID→統一断面ID変換配列
%     secdim        - 断面寸法配列 [nsec×ncol]
%
%   出力引数:
%     lm_brace_buckling - ブレース長さ L [nmeb×1]

% 水平距離
Lx_all = calc_brace_Lx(member_brace, node);

% RC梁せいの取得（S梁は 鉄骨心=node.z のためオフセット不要）
Hg = zeros(size(secdim,1), 1);
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

  % ブレース端部Z = node.z + 梁レベル調整
  [z1, ig1] = endpoint_z(node.z(in1), idg1, glv);
  [z2, ig2] = endpoint_z(node.z(in2), idg2, glv);

  % RC梁接続端はコンクリートとの重複を除く（近い方の面まで詰める）
  % idnode1=下端は梁天端(+H/2)、idnode2=上端は梁下面(-H/2)
  % ただし柱分割点（NODE_BRACE_FOR_COLUMN）はすでに基礎梁天端位置
  % にあるためオフセットしない
  is_split1 = node.type(in1) == PRM.NODE_BRACE_FOR_COLUMN;
  is_split2 = node.type(in2) == PRM.NODE_BRACE_FOR_COLUMN;
  if ig1 > 0 && stype_gir(ig1) == PRM.RCRS && ~is_split1
    z1 = z1 + Hg_gir(ig1) / 2;
  end
  if ig2 > 0 && stype_gir(ig2) == PRM.RCRS && ~is_split2
    z2 = z2 - Hg_gir(ig2) / 2;
  end

  Lz = z2 - z1;
  lm_brace_buckling(ib) = sqrt(Lx_all(ib)^2 + Lz^2);
end

return
end
