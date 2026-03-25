function rs0 = correct_kbrace_shear(rs0, node_type, ...
  member_girder, member_brace, cxl, idm2n1, idm2n2)
%correct_kbrace_shear - Kブレース分割梁のMID側せん断力を補正
%
%   rs0 = correct_kbrace_shear(rs0, node_type, ...
%     member_girder, member_brace, cxl, ...
%     idm2n1, idm2n2) は、
%   MID節点（type=98）の力の平衡から外力Fextを算出し、
%   各分割梁のMID側Qに -Fext/2 を加算する。
%
%   入力引数:
%     rs0           - 部材端力配列 [nme×12×nlc]
%     node_type     - 節点タイプ [nnode×1]
%     member_girder - 梁部材構造体
%     member_brace  - ブレース部材構造体
%     cxl           - 全部材x軸方向余弦 [nme×3]
%     idm2n1        - 全部材のi端節点番号 [nme×1]
%     idm2n2        - 全部材のj端節点番号 [nme×1]
%
%   出力引数:
%     rs0 - 補正後の部材端力配列 [nme×12×nlc]
%
%   備考:
%     - 水平梁ではczl=[0,0,1]のため局所Qz=全体z
%     - ブレースはQy≈Qz≈0のためFz≈-N*cxl(3)で算出

nlc = size(rs0, 3);

% MID節点（Kブレース用梁分割節点）を列挙
idnode_mid = find(node_type == PRM.NODE_BRACE_FOR_GIRDER);
if isempty(idnode_mid)
  return
end

% ブレースの事前情報
brace_idme = member_brace.idme;
brace_cxl3 = cxl(brace_idme, 3);
idn1_b = idm2n1(brace_idme);
idn2_b = idm2n2(brace_idme);

for k = 1:length(idnode_mid)
  idnode = idnode_mid(k);

  % KBRACE1（左側梁）: j端がMID
  ig1 = find(member_girder.type == PRM.GIRDER_FOR_KBRACE1 ...
    & member_girder.idnode2 == idnode, 1);
  % KBRACE2（右側梁）: i端がMID
  ig2 = find(member_girder.type == PRM.GIRDER_FOR_KBRACE2 ...
    & member_girder.idnode1 == idnode, 1);
  if isempty(ig1) || isempty(ig2)
    continue
  end
  im1 = member_girder.idme(ig1);
  im2 = member_girder.idme(ig2);

  % MID節点に接続するブレースを特定
  ib_at_mid = find(idn1_b == idnode | idn2_b == idnode);

  for ilc = 1:nlc
    % 梁のelement→node z成分（水平梁: czl=[0,0,1]）
    Fz_beam = -rs0(im1, 9, ilc) - rs0(im2, 3, ilc);

    % ブレースのelement→node z成分: -N * cxl(3)
    Fz_brace = 0;
    for ii = 1:length(ib_at_mid)
      ib = ib_at_mid(ii);
      imb = brace_idme(ib);
      if idn1_b(ib) == idnode
        N = rs0(imb, 1, ilc);
      else
        N = rs0(imb, 7, ilc);
      end
      Fz_brace = Fz_brace - N * brace_cxl3(ib);
    end

    % 外力と補正: Q_output = Q_FEM - Fext/2
    Fext = -(Fz_beam + Fz_brace);
    rs0(im1, 9, ilc) = rs0(im1, 9, ilc) - Fext / 2;
    rs0(im2, 3, ilc) = rs0(im2, 3, ilc) - Fext / 2;
  end
end

return
end
