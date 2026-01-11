function [lm_girder_weight, face_deduct] = calc_girder_weight_length(...
  member_girder, node, stype_sec, idsecg2sec, secdim)
%calc_girder_weight_length - 梁荷重計算用の部材長を算出
%
% SS7マニュアル「4.1.1 梁」に基づき、梁の自重・仕上重量計算用の部材長を算出する。
%
% SS7の定義:
%   大梁・片持梁: 柱面間の内法長さ
%   小梁: 通り心間距離
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
%   member_girder - 梁部材構造体（idme, idsecg, idsec_facel/r, isthrough, idnode1/2）
%   node          - 節点構造体（x, y, z）
%   stype_sec     - 断面種別配列 [nsec×1]
%   idsecg2sec    - 梁断面ID→統一断面IDの変換配列
%   secdim        - 断面寸法配列 [nsec×ncol]
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
idsec_facel = member_girder.idsec_facel;  % i端（左端）の対面柱断面
idsec_facer = member_girder.idsec_facer;  % j端（右端）の対面柱断面

% 通し梁フラグ [nmeg×3]: 列1=i端が通し, 列2=j端が通し, 列3=中央部が通し
isthrough = member_girder.isthrough;

% 初期値: 節点座標から梁の実長を計算（node.dzを含む）
idnode1 = member_girder.idnode1;
idnode2 = member_girder.idnode2;
dx = node.x(idnode2) - node.x(idnode1);
dy = node.y(idnode2) - node.y(idnode1);
z1 = node.z(idnode1) + node.dz(idnode1);
z2 = node.z(idnode2) + node.dz(idnode2);
dz = z2 - z1;
lm_girder_weight = sqrt(dx.^2 + dy.^2 + dz.^2);

% 柱面減算量の初期化
face_deduct = zeros(nmeg, 2);

for ig = 1:nmeg
  % --- i端側の柱 ---
  % 通し梁の中間節点（i端が通し接合）の場合は柱面減算しない
  if ~isthrough(ig, 1)
    ids_l = idsec_facel(ig,:);
    ids_l = ids_l(ids_l > 0);
    for k = 1:length(ids_l)
      is_steel_c1 = is_steel_sec(ids_l(k));
      % 同種別（S-S または RC-RC）なら柱面まで減算
      if is_steel_g(ig) == is_steel_c1
        Dc1 = Dc(ids_l(k));
        face_deduct(ig, 1) = Dc1/2;
        lm_girder_weight(ig) = lm_girder_weight(ig) - Dc1/2;
        break;  % 1つの柱面で減算したら終了
      end
    end
  end

  % --- j端側の柱 ---
  % 通し梁の中間節点（j端が通し接合）の場合は柱面減算しない
  if ~isthrough(ig, 2)
    ids_r = idsec_facer(ig,:);
    ids_r = ids_r(ids_r > 0);
    for k = 1:length(ids_r)
      is_steel_c2 = is_steel_sec(ids_r(k));
      % 同種別（S-S または RC-RC）なら柱面まで減算
      if is_steel_g(ig) == is_steel_c2
        Dc2 = Dc(ids_r(k));
        face_deduct(ig, 2) = Dc2/2;
        lm_girder_weight(ig) = lm_girder_weight(ig) - Dc2/2;
        break;  % 1つの柱面で減算したら終了
      end
    end
  end
end

return
end
