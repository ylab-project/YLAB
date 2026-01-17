function lm_weight = calc_column_weight_length(...
  member_column, member_girder, floor, node, ...
  stype_sec, idsecc2sec, idsecg2sec, secdim)
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
% 通し梁（一本部材）の場合:
%   柱頭側の梁に一本部材の指定があり、一本部材の両端ではない中間箇所では
%   梁下面までとする（梁せい分を減算）
%
% Inputs:
%   member_column - 柱部材構造体
%   member_girder - 梁部材構造体
%   floor         - フロア構造体（standard_height, nfl）
%   node          - 節点構造体（dz, idz）
%   stype_sec     - 断面種別配列 [nsec×1]
%   idsecc2sec    - 柱断面ID→統一断面IDの変換配列
%   idsecg2sec    - 梁断面ID→統一断面IDの変換配列
%   secdim        - 断面寸法配列 [nsec×ncol]
%
% Outputs:
%   lm_weight - 柱荷重計算用の部材長配列 [nmec x 1]

% 柱数
nmec = length(member_column.idme);
nfl = size(floor, 1);

% 柱の節点情報
idmc2n1 = member_column.idnode1;
idmc2n2 = member_column.idnode2;

% S造判定用: HSS/WFSはS造、RCRSはRC造
is_steel_sec = stype_sec == PRM.HSS | stype_sec == PRM.WFS;

% 梁せいの取得（断面種別ごと）
Hs = zeros(size(secdim,1),1);
Hs(stype_sec==PRM.WFS) = secdim(stype_sec==PRM.WFS,1);   % H形鋼: 1列目がせい
Hs(stype_sec==PRM.RCRS) = secdim(stype_sec==PRM.RCRS,2); % RC梁: 2列目がせい

% 梁の情報
glv = member_girder.level;       % 梁レベル調整（下げが負）
% idsecg→統一断面IDへ変換
idmg2s = idsecg2sec(member_girder.idsecg);
Hg = Hs(idmg2s);                 % 梁せい

% 柱の断面種別（idsecc→統一断面IDへ変換）
idmc2s = idsecc2sec(member_column.idsecc);
is_steel_c = is_steel_sec(idmc2s);   % 柱がS造かどうか

% 梁の構造種別
is_steel_g = is_steel_sec(idmg2s);   % 梁がS造かどうか

% 柱に接続する梁ID
idgx1 = member_column.idmeg_face1x;  % 柱脚X
idgy1 = member_column.idmeg_face1y;  % 柱脚Y
idgx2 = member_column.idmeg_face2x;  % 柱頭X
idgy2 = member_column.idmeg_face2y;  % 柱頭Y

% 1階判定用: 最下層の柱かどうか（最小のidstory）
min_story = min(member_column.idstory);
is_first_story = member_column.idstory == min_story;

% 通し梁フラグ [nmeg×3]: 列1=i端が通し, 列2=j端が通し, 列3=中央部が通し
isthrough = member_girder.isthrough;

% 梁の節点情報（柱頭節点と梁端の対応判定用）
girder_idnode1 = member_girder.idnode1;
girder_idnode2 = member_girder.idnode2;

% 初期値: 柱脚〜柱頭間の標準階高を合算 + 節点移動分
% （ダミー層を含む複数階にまたがる柱に対応）
lm_weight = zeros(nmec, 1);
for ic = 1:nmec
  in1 = idmc2n1(ic);
  in2 = idmc2n2(ic);
  ifl1 = node.idz(in1);       % 柱脚のフロアID
  ifl2 = node.idz(in2) - 1;   % 柱頭のフロアID - 1

  if ifl2 > nfl
    continue
  end

  % 標準階高の合算 + 節点移動
  lm_weight(ic) = sum(floor.standard_height(ifl1:ifl2)) ...
    - node.dz(in1) + node.dz(in2);
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
  % ただし、通し梁の中間部の場合は追加しない
  if is_first_story(ic) && ~isempty(idg1)
    % 柱脚側の梁で、柱と同種別（S-S または RC-RC）のものの最大梁せいを取得
    % 通し梁の中間部（両端でない）は除外
    same_type_mask = is_steel_g(idg1) == is_steel_c(ic);
    in1 = idmc2n1(ic);  % 柱脚節点
    for k = 1:length(idg1)
      ig = idg1(k);
      % 梁のどちら側が柱脚に接続しているか
      if girder_idnode1(ig) == in1
        % 梁のi端が柱脚に接続 → i端が通しなら中間部
        if isthrough(ig, 1)
          same_type_mask(k) = false;
        end
      elseif girder_idnode2(ig) == in1
        % 梁のj端が柱脚に接続 → j端が通しなら中間部
        if isthrough(ig, 2)
          same_type_mask(k) = false;
        end
      end
    end
    if any(same_type_mask)
      max_beam_height = max(Hg(idg1(same_type_mask)));
      lm_weight(ic) = lm_weight(ic) + max_beam_height;
    end
  end

  % --- 通し梁中間部: 柱頭側の梁が通し梁の中間部なら梁せい分を減算 ---
  % SS7の定義: 柱頭側の梁に一本部材の指定があり、両端でない中間箇所では梁下面まで
  if ~isempty(idg2)
    in2 = idmc2n2(ic);  % 柱頭節点
    for k = 1:length(idg2)
      ig = idg2(k);
      is_through_intermediate = false;
      % 梁のどちら側が柱頭に接続しているか
      if girder_idnode1(ig) == in2
        % 梁のi端が柱頭に接続 → i端が通しなら中間部
        is_through_intermediate = isthrough(ig, 1);
      elseif girder_idnode2(ig) == in2
        % 梁のj端が柱頭に接続 → j端が通しなら中間部
        is_through_intermediate = isthrough(ig, 2);
      end
      % 通し梁の中間部かつ同種別なら梁せい分を減算
      if is_through_intermediate && is_steel_g(ig) == is_steel_c(ic)
        lm_weight(ic) = lm_weight(ic) - Hg(ig);
        break;  % 1つの梁で減算したら終了
      end
    end
  end

  % --- 斜め柱対応: 水平移動量を考慮した斜め長さに変換 ---
  % 節点同一化により柱頭が水平方向に移動している場合、
  % 鉛直方向の部材長から斜め長さを計算する
  in1 = idmc2n1(ic);
  in2 = idmc2n2(ic);
  dx = node.x(in2) - node.x(in1);
  dy = node.y(in2) - node.y(in1);
  horizontal = sqrt(dx^2 + dy^2);
  if horizontal > 0
    lm_weight(ic) = sqrt(lm_weight(ic)^2 + horizontal^2);
  end
end

return
end
