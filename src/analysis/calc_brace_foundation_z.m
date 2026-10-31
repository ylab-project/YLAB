function [z, ic] = calc_brace_foundation_z(ib, member, node, options)
%calc_brace_foundation_z - 基礎部の柱端でブレースの天端高さを求める
%
%   [z, ic] = calc_brace_foundation_z(ib, member, node, options) は、
%   最下階のX形・K上形で接続RC梁を持つ柱端の天端高さを返す。
%   基礎柱天端指定では標準階高基準の節点座標を用いる。
%   柱脚の回転剛性・水平寸法の割当から高さは推定しない。
%   解析用の分割節点の高さは参照しない。
%
%   入力引数:
%     ib      - ブレース部材番号
%     member  - 接続柱梁と入力柱の端点を持つ部材データ
%     node    - 標準階高基準の節点座標を持つ節点データ
%     options - 基礎柱・基礎梁の天端の選択を持つオプション
%
%   出力引数:
%     z  - 天端のZ座標 (mm)。対象となる柱端がなければNaN
%     ic - 入力柱番号。接続柱がなければ0

z = NaN;
ic = 0;
mb = member.brace;
if mb.idz(ib, 1) ~= 1 || (mb.type(ib) ~= PRM.BRACE_MEMBER_TYPE_X ...
    && mb.type(ib) ~= PRM.BRACE_MEMBER_TYPE_K_UPPER)
  return
end
mc = member.column;
mg = member.girder;
ids = mb.idmec1(ib, :);
ids = ids(ids > 0);
ids = ids(mc.type(ids) ~= PRM.COLUMN_FOR_BRACE_FOUNDATION);
ids = ids(mc.idnode1(ids) == mb.idnode1(ib));
if isempty(ids)
  return
end
ic = ids(1);
icbase = ic;
if mc.type(ic) == PRM.COLUMN_FOR_BRACE_BODY
  icbase = mc.idsplit(ic);
end
% 同構面・直交構面の接続RC梁を既存の梁面対応から取り出す。
idg = [mc.idmeg_face1x(icbase, :) mc.idmeg_face1y(icbase, :)];
idg = idg(idg > 0);
idg = idg(mg.section_type(idg) == PRM.RCRS);
if isempty(idg)
  return
end
z = node.z_standard(member.column_input.idnode1(ic));
if options.position_brace_foundation == PRM.BRACE_FOUNDATION_BEAM_TOP
  z = z + max(mg.level(idg));
end

return
end
