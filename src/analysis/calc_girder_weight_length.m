function [lm_girder_weight, face_deduct] = ...
  calc_girder_weight_length(...
  member_girder, node, stype_sec, ...
  idsecg2sec, secdim, Df_foundation)
%calc_girder_weight_length - 梁荷重計算用の部材長を算出
%
% SS7マニュアル「4.1.1 梁」に基づき、梁の自重・仕上重量計算用の部材長を算出する。
%
% SS7の定義:
%   大梁・片持梁: 柱面間の内法長さ
%   小梁: 通り心間距離
%
% 斜め梁・節点上下移動の場合:
%   鉛直方向はnode.zの差を使用し、水平移動量と合わせて実長を計算
%
% 柱と梁の構造種別による場合分け:
%   同種別（RC-RC, S-S）: 柱面まで
%   S柱（基礎柱あり）-RC梁: 基礎柱面まで
%   S柱（基礎柱なし）-RC梁: 通り心まで
%
% 通し梁（一本部材）の場合:
%   一本部材の両端以外（中間節点）は通り心までを部材長とする（柱面減算なし）
%
% Inputs:
%   member_girder - 梁部材構造体
%     （idme, idsecg, idsec_facel/r, isthrough, idnode1/2）
%   node          - 節点構造体（x, y, z）
%   stype_sec     - 断面種別配列 [nsec×1]
%   idsecg2sec    - 梁断面ID→統一断面IDの変換配列
%   secdim        - 断面寸法配列 [nsec×ncol]
%   Df_foundation - 基礎柱面寸法配列 [nsec×1]（統一断面ID→Df）
%
% Outputs:
%   lm_girder_weight - 梁荷重計算用の部材長配列 [nmeg x 1]
%   face_deduct      - 柱面減算量 [nmeg x 2]（列1: i端, 列2: j端）

% 梁数
nmeg = length(member_girder.idme);

% S造判定用: HSS/WFSはS造、RCRSはRC造
is_steel_sec = stype_sec == PRM.HSS | stype_sec == PRM.WFS;

% 梁の構造種別（idsecg→統一断面IDへ変換）
idmg2s = idsecg2sec(member_girder.idsecg);
is_steel_g = is_steel_sec(idmg2s);

% 柱せいの取得（断面種別ごと）
Dc = zeros(size(secdim,1),1);
Dc(stype_sec==PRM.HSS) = secdim(stype_sec==PRM.HSS,1);   % 角形鋼管: 1列目
Dc(stype_sec==PRM.RCRS) = secdim(stype_sec==PRM.RCRS,3); % RC柱: 3列目が実寸法

% 梁の両端の対面柱断面ID（統一断面ID、柱なしは0）
idsec_facel = member_girder.idsec_facel;
idsec_facer = member_girder.idsec_facer;
isthrough = member_girder.isthrough;  % [nmeg×3]
idnode1 = member_girder.idnode1;
idnode2 = member_girder.idnode2;

% 梁端間の3D距離（node.zは実座標のため、同一層内の
% 節点上下移動も異層の斜め梁も正しく処理できる）
dz = abs(node.z(idnode2) - node.z(idnode1));
dx = node.x(idnode2) - node.x(idnode1);
dy = node.y(idnode2) - node.y(idnode1);
horizontal = sqrt(dx.^2 + dy.^2);
lm_girder_weight = sqrt(dz.^2 + horizontal.^2);

% 斜め梁の換算係数（水平方向→斜め方向）
scale = ones(nmeg, 1);
is_sloped = ...
  horizontal > 0 & lm_girder_weight > horizontal;
scale(is_sloped) = lm_girder_weight(is_sloped) ...
  ./ horizontal(is_sloped);

% 柱面減算量の初期化
face_deduct = zeros(nmeg, 2);

idsec_face = {idsec_facel, idsec_facer};
for ig = 1:nmeg
  for iend = 1:2
    if isthrough(ig, iend)
      continue
    end
    face_deduct(ig, iend) = calc_face_deduct( ...
      idsec_face{iend}(ig,:), is_steel_g(ig), ...
      is_steel_sec, Dc, Df_foundation, scale(ig));
    lm_girder_weight(ig) = lm_girder_weight(ig) ...
      - face_deduct(ig, iend);
  end
end

return
end

function d = calc_face_deduct(ids_row, ...
  is_steel_g_, is_steel_sec_, ...
  Dc, Df_foundation, scale_)
%calc_face_deduct - 片端の柱面減算量を算出
%
%   d = calc_face_deduct(ids_row, is_steel_g_,
%   is_steel_sec_, Dc, Df_foundation, scale_)
%   は、梁の片端について柱面減算量を算出する。
%
%   入力引数:
%     ids_row       - 対面柱断面IDの行 [1×ncol]
%     is_steel_g_   - 梁がS造か (logical)
%     is_steel_sec_ - 断面ごとのS造判定 [nsec×1]
%     Dc            - 柱せい配列 [nsec×1]
%     Df_foundation - 基礎柱面寸法 [nsec×1]
%     scale_        - 斜め梁換算係数 (scalar)
%
%   出力引数:
%     d - 柱面減算量 (scalar)

d = 0;
ids = ids_row(ids_row > 0);
for k = 1:length(ids)
  is_steel_c = is_steel_sec_(ids(k));
  if is_steel_g_ == is_steel_c
    % 同種別（S-S または RC-RC）: 柱面まで減算
    d = Dc(ids(k)) / 2 * scale_;
    return;
  elseif ~is_steel_g_ && is_steel_c
    % RC梁-S柱: 基礎柱があれば基礎柱面まで減算
    Df = Df_foundation(ids(k));
    if Df > 0
      d = Df / 2 * scale_;
    end
    return;
  end
end

return
end
