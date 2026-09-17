function [joint_top, joint_bottom] = calc_column_joint_length( ...
  member_column, member_girder, ~, stype_sec, idsecg2sec, secdim, ...
  cxl_girder)
%calc_column_joint_length - 柱仕口部長さを算出
%
%   [joint_top, joint_bottom] =
%     calc_column_joint_length(member_column,
%     member_girder, [], stype_sec,
%     idsecg2sec, secdim, cxl_girder) は、
%   SS7マニュアル 4.4.1 に基づき柱頭・柱脚の
%   仕口部長さを算出する。
%
%   仕口部の長さは、ノードに接続する４方向の梁の最上部から
%   最下部までの鉛直距離を、柱軸方向へ投影した長さとする。
%   斜行梁は梁せいを鉛直方向へ投影してから計算する。
%
%   入力引数:
%     member_column - 柱部材構造体。BODYのidsplitはFOUNDATION番号
%     member_girder - 梁部材構造体
%     ~             - 未使用（既存の呼出し引数位置を維持）
%     stype_sec     - 断面種別配列 [nsec x 1]
%     idsecg2sec    - 梁断面→統一断面ID変換配列
%     secdim        - 断面寸法配列 [nsec x ncol]
%     cxl_girder    - 標準系の梁軸方向余弦 [nmg x 3]
%
%   入力の梁レベルと梁せいはmm単位。
%
%   出力引数:
%     joint_top    - 柱頭の仕口部長さ [nmec x 1] (mm)
%     joint_bottom - 柱脚の仕口部長さ [nmec x 1] (mm)

nmec = length(member_column.idme);

% 梁せい取得（S梁のみ: 鉄骨積算の仕口部はS梁で決まる）
Hs = zeros(size(secdim, 1), 1);
Hs(stype_sec == PRM.WFS) = secdim(stype_sec == PRM.WFS, 1);
idmg2s = idsecg2sec(member_girder.idsecg);
Hg = Hs(idmg2s);

% 梁の鉛直投影せい（斜行梁の補正）
Hg_proj = calc_girder_vertical_depth_projection(Hg, cxl_girder);

% 柱軸方向への投影係数（斜め柱の補正）
col_proj = column_axial_projection(member_column.cz_std);

% 梁レベル調整
glv = member_girder.level;

% 柱に接続する梁ID [nmec x 2]
idgx1 = member_column.idmeg_face1x;
idgy1 = member_column.idmeg_face1y;
idgx2 = member_column.idmeg_face2x;
idgy2 = member_column.idmeg_face2y;

ctype = member_column.type;

joint_top = zeros(nmec, 1);
joint_bottom = zeros(nmec, 1);

for ic = 1:nmec
  % BRACE1（基礎梁内RC部分）はスキップ
  if ctype(ic) == PRM.COLUMN_FOR_BRACE_FOUNDATION
    continue
  end

  % --- 柱頭: face2 の梁 ---
  idg = [idgx2(ic,:) idgy2(ic,:)];
  idg = idg(idg > 0);
  if ~isempty(idg)
    joint_top(ic) = joint_length(idg) * col_proj(ic);
  end

  % --- 柱脚: face1 の梁 ---
  % BODYの柱脚梁面は、idsplitで対応するFOUNDATIONから採る
  if ctype(ic) == PRM.COLUMN_FOR_BRACE_BODY
    ic_f1 = member_column.idsplit(ic);
  else
    ic_f1 = ic;
  end
  idg = [idgx1(ic_f1,:) idgy1(ic_f1,:)];
  idg = idg(idg > 0);
  if ~isempty(idg)
    joint_bottom(ic) = joint_length(idg) * col_proj(ic);
  end
end

return

  function jlen = joint_length(idg_)
  %joint_length - 接続梁の最上部から最下部までの距離を求める
  %
  %   jlen = joint_length(idg_) は、親関数の梁レベルglvと
  %   鉛直投影した梁せいHg_projから仕口部の鉛直長さを求める。
  %
  %   入力引数:
  %     idg_ - 柱端に接続する梁番号
  %
  %   出力引数:
  %     jlen - 接続梁の最上部から最下部までの鉛直長さ (mm)

    top_ = glv(idg_);
    bot_ = glv(idg_) - Hg_proj(idg_);
    jlen = max(top_) - min(bot_);

    return
  end
end
