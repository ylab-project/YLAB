function lm_weight = calc_column_weight_length(com, secdim)
%calc_column_weight_length - 柱荷重計算用の部材長を算出
%
% SS7マニュアル「4.1.2 柱」に基づき、柱の自重・仕上重量計算用の部材長を算出する。
%
% SS7の定義:
%   梁天端〜梁天端 = 階高（基本）
%   部材長 = 標準階高 + (-dz(柱脚) + dz(柱頭)) + max(柱頭側glv) - max(柱脚側glv)
%   glvは下げが負の値。max(glv)は最も高い梁天端を選択する。
%   1階/下層柱抜け: 同種別（S-S, RC-RC）なら最大梁せい分を追加
%
% Inputs:
%   com    - 共通オブジェクト
%   secdim - 断面寸法配列
%
% Outputs:
%   lm_weight - 柱荷重計算用の部材長配列 [nmec x 1]

% 柱数
nmec = com.nmec;
nfl = com.nfl;

% 標準階高・節点移動
floor_standard_height = com.floor.standard_height;
dz = com.node.dz;
idmc2n1 = com.member.column.idnode1;
idmc2n2 = com.member.column.idnode2;
idn2z = com.node.idz;  % 節点のZ方向フロアID

% 断面種別
stype = com.section.property.type;

% S造判定用: HSS/WFSはS造、RCRSはRC造
is_steel_sec = stype == PRM.HSS | stype == PRM.WFS;

% 梁せいの取得（断面種別ごと）
Hs = zeros(size(secdim,1),1);
Hs(stype==PRM.WFS) = secdim(stype==PRM.WFS,1);   % H形鋼: 1列目がせい
Hs(stype==PRM.RCRS) = secdim(stype==PRM.RCRS,2); % RC梁: 2列目がせい

% 梁の情報
glv = com.member.girder.level;       % 梁レベル調整（下げが負）
% idsecg→統一断面IDへ変換
idmg2s = com.section.girder.idsec(com.member.girder.idsecg);
Hg = Hs(idmg2s);                     % 梁せい

% 柱の断面種別（idsecc→統一断面IDへ変換）
idmc2s = com.section.column.idsec(com.member.column.idsecc);
is_steel_c = is_steel_sec(idmc2s);   % 柱がS造かどうか

% 梁の構造種別
is_steel_g = is_steel_sec(idmg2s);   % 梁がS造かどうか

% 柱に接続する梁ID
idgx1 = com.member.column.idmeg_face1x;  % 柱脚X
idgy1 = com.member.column.idmeg_face1y;  % 柱脚Y
idgx2 = com.member.column.idmeg_face2x;  % 柱頭X
idgy2 = com.member.column.idmeg_face2y;  % 柱頭Y

% 1階判定用: 最下層の柱かどうか（最小のidstory）
min_story = min(com.member.column.idstory);
is_first_story = com.member.column.idstory == min_story;

% 初期値: 柱脚〜柱頭間の標準階高を合算 + 節点移動分
% （ダミー層を含む複数階にまたがる柱に対応）
lm_weight = zeros(nmec, 1);
for ic = 1:nmec
  in1 = idmc2n1(ic);
  in2 = idmc2n2(ic);
  ifl1 = idn2z(in1);       % 柱脚のフロアID
  ifl2 = idn2z(in2) - 1;   % 柱頭のフロアID - 1

  if ifl2 > nfl
    continue
  end

  % 標準階高の合算 + 節点移動
  lm_weight(ic) = sum(floor_standard_height(ifl1:ifl2)) ...
    - dz(in1) + dz(in2);
end

for ic = 1:nmec
  % --- 柱脚側: 取り付く梁の最大glv ---
  idg1 = [idgx1(ic,:) idgy1(ic,:)];
  idg1 = idg1(idg1 > 0);
  if ~isempty(idg1)
    max_glv1 = max(glv(idg1));  % 最も高い梁天端のglv
  else
    max_glv1 = 0;
  end

  % --- 柱頭側: 取り付く梁の最大glv ---
  idg2 = [idgx2(ic,:) idgy2(ic,:)];
  idg2 = idg2(idg2 > 0);
  if ~isempty(idg2)
    max_glv2 = max(glv(idg2));  % 最も高い梁天端のglv
  else
    max_glv2 = 0;
  end

  % --- 部材長 = 階高 + glv差分 ---
  lm_weight(ic) = lm_weight(ic) + max_glv2 - max_glv1;

  % --- 1階柱: 柱脚側の梁が同種別なら最大梁せい分を追加 ---
  % SS7の定義: 1階柱では柱脚側の梁を見て、同種別なら梁せい分を追加
  if is_first_story(ic) && ~isempty(idg1)
    % 柱脚側の梁で、柱と同種別（S-S または RC-RC）のものの最大梁せいを取得
    same_type_mask = is_steel_g(idg1) == is_steel_c(ic);
    if any(same_type_mask)
      max_beam_height = max(Hg(idg1(same_type_mask)));
      lm_weight(ic) = lm_weight(ic) + max_beam_height;
    end
  end
end

return
end
