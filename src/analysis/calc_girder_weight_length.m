function lm_girder_weight = calc_girder_weight_length(com, secdim, lm)
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
% Inputs:
%   com    - 共通オブジェクト
%   secdim - 断面寸法配列
%   lm     - 部材長配列（全部材）
%
% Outputs:
%   lm_girder_weight - 梁荷重計算用の部材長配列 [nmeg x 1]

% 梁数
nmeg = com.nmeg;

% 断面種別
stype_sec = com.section.property.type;

% S造判定用: HSS/WFSはS造、RCRSはRC造
is_steel_sec = stype_sec == PRM.HSS | stype_sec == PRM.WFS;

% 梁の構造種別（idsecg→統一断面IDへ変換）
idmg2s = com.section.girder.idsec(com.member.girder.idsecg);
is_steel_g = is_steel_sec(idmg2s);

% 柱せいの取得（断面種別ごと）
Dc = zeros(size(secdim,1),1);
Dc(stype_sec==PRM.HSS) = secdim(stype_sec==PRM.HSS,1);   % 角形鋼管: 1列目
Dc(stype_sec==PRM.RCRS) = secdim(stype_sec==PRM.RCRS,3); % RC柱: 3列目が実寸法

% 梁の両端の対面柱断面ID（統一断面ID、柱なしは0）
idsec_facel = com.member.girder.idsec_facel;  % i端（左端）の対面柱断面
idsec_facer = com.member.girder.idsec_facer;  % j端（右端）の対面柱断面

% 初期値: 節点間距離（構造階高ベース）
lm_girder_weight = lm(com.member.girder.idme);

for ig = 1:nmeg
  % --- i端側の柱 ---
  ids_l = idsec_facel(ig,:);
  ids_l = ids_l(ids_l > 0);
  for k = 1:length(ids_l)
    is_steel_c1 = is_steel_sec(ids_l(k));
    % 同種別（S-S または RC-RC）なら柱面まで減算
    if is_steel_g(ig) == is_steel_c1
      Dc1 = Dc(ids_l(k));
      lm_girder_weight(ig) = lm_girder_weight(ig) - Dc1/2;
      break;  % 1つの柱面で減算したら終了
    end
  end

  % --- j端側の柱 ---
  ids_r = idsec_facer(ig,:);
  ids_r = ids_r(ids_r > 0);
  for k = 1:length(ids_r)
    is_steel_c2 = is_steel_sec(ids_r(k));
    % 同種別（S-S または RC-RC）なら柱面まで減算
    if is_steel_g(ig) == is_steel_c2
      Dc2 = Dc(ids_r(k));
      lm_girder_weight(ig) = lm_girder_weight(ig) - Dc2/2;
      break;  % 1つの柱面で減算したら終了
    end
  end
end

return
end
