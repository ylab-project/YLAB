function [lm_girder_weight, face_deduct] = calc_girder_weight_length(...
  member_girder, node, story, floor, stype_sec, idsecg2sec, secdim)
%calc_girder_weight_length - 梁荷重計算用の部材長を算出
%
% SS7マニュアル「4.1.1 梁」に基づき、梁の自重・仕上重量計算用の部材長を算出する。
%
% SS7の定義:
%   大梁・片持梁: 柱面間の内法長さ
%   小梁: 通り心間距離
%
% 斜め梁の場合:
%   鉛直方向は標準階高を使用し、水平移動量と合わせて実長を計算
%   (calc_column_weight_length.mの斜め柱対応と同様)
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
%   member_girder - 梁部材構造体（idme, idsecg, idsec_facel/r, isthrough, idnode1/2, level）
%   node          - 節点構造体（x, y, z, idz）
%   story         - 層構造体（idfloor）
%   floor         - フロア構造体（standard_height）
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

% 梁の節点情報
idnode1 = member_girder.idnode1;
idnode2 = member_girder.idnode2;

% 梁レベル調整（下げが負）
glv = member_girder.level;

% 階数
nfl = size(floor, 1);

% 初期値: 梁端間の標準階高を合算 + 梁レベル調整
% （calc_column_weight_length.mの斜め柱対応と同様の処理）
lm_girder_weight = zeros(nmeg, 1);
for ig = 1:nmeg
  in1 = idnode1(ig);
  in2 = idnode2(ig);
  idz1 = node.idz(in1);
  idz2 = node.idz(in2);

  if idz1 == idz2
    % 水平梁: 鉛直成分なし
    lm_girder_weight(ig) = 0;
  else
    % 斜め梁: 両端層間の標準階高を合算
    idz_min = min(idz1, idz2);
    idz_max = max(idz1, idz2);

    % idz_min層〜idz_max層の間の階数分の標準階高を合算
    % 例: idz_min=1, idz_max=2 の場合、1階分（floor 1）
    vertical = 0;
    for idz = idz_min:(idz_max-1)
      ifl = story.idfloor(idz + 1);  % idz+1層のfloor
      if ~isnan(ifl) && ifl >= 1 && ifl <= nfl
        vertical = vertical + floor.standard_height(ifl);
      end
    end
    lm_girder_weight(ig) = vertical;
  end
end

for ig = 1:nmeg
  % --- i端側: 当該梁のglv ---
  glv1 = glv(ig);

  % --- j端側: 当該梁のglv ---
  glv2 = glv(ig);

  % --- 部材長 = 階高 + glv差分 ---
  lm_girder_weight(ig) = lm_girder_weight(ig) + glv2 - glv1;

  % --- 斜め梁対応: 水平移動量を考慮した斜め長さに変換 ---
  % 節点同一化により梁端が水平方向に移動している場合、
  % 鉛直方向の部材長から斜め長さを計算する
  in1 = idnode1(ig);
  in2 = idnode2(ig);
  dx = node.x(in2) - node.x(in1);
  dy = node.y(in2) - node.y(in1);
  horizontal = sqrt(dx^2 + dy^2);
  if horizontal > 0
    lm_girder_weight(ig) = sqrt(lm_girder_weight(ig)^2 + horizontal^2);
  end
end

% 柱面減算量の初期化
face_deduct = zeros(nmeg, 2);

for ig = 1:nmeg
  % 斜め梁の換算係数を計算（水平方向→斜め方向）
  in1 = idnode1(ig);
  in2 = idnode2(ig);
  dx = node.x(in2) - node.x(in1);
  dy = node.y(in2) - node.y(in1);
  horizontal = sqrt(dx^2 + dy^2);
  if horizontal > 0 && lm_girder_weight(ig) > horizontal
    % 斜め梁: 柱面位置を斜め方向に換算
    scale = lm_girder_weight(ig) / horizontal;
  else
    scale = 1;
  end

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
        face_deduct(ig, 1) = Dc1/2 * scale;  % 斜め方向に換算
        lm_girder_weight(ig) = lm_girder_weight(ig) - Dc1/2 * scale;
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
        face_deduct(ig, 2) = Dc2/2 * scale;  % 斜め方向に換算
        lm_girder_weight(ig) = lm_girder_weight(ig) - Dc2/2 * scale;
        break;  % 1つの柱面で減算したら終了
      end
    end
  end
end

return
end
