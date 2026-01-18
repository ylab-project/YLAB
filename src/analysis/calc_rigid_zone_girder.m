function lrgirder = calc_rigid_zone_girder(...
  mgstype, idmg2sfl, idmg2sfr, idscb2s, cbsDf, sdimgm, ...
  secdim, stype, gdir, idmg2n, idsup2n)
%calc_rigid_zone_girder 梁の剛域長を計算
%   lrgirder = calc_rigid_zone_girder(mgstype, idmg2sfl, idmg2sfr, ...
%   idscb2s, cbsDf, sdimgm, secdim, stype, gdir, idmg2n, idsup2n) は、
%   SS7仕様書3.3.1に基づいて梁の剛域長を計算します。
%   RC梁は最小柱面/2-α×梁せい、S梁は最大柱面/2で計算します。
%   柱脚Dfは支点のある梁端部にのみ適用します。
%
%   入力引数:
%     mgstype - 梁断面タイプ [nmg×1]
%     idmg2sfl - 梁左端の全断面ID [nmg×ncol]
%               ncol: 接続柱本数（節点同一化で変動）
%     idmg2sfr - 梁右端の全断面ID [nmg×ncol]
%     idscb2s - 基礎柱の全断面ID [ncb×1]
%     cbsDf - 基礎柱のフーチング幅 [ncb×1]
%     sdimgm - 梁断面寸法 [nmg×4]
%     secdim - 全断面寸法 [nsec×4]
%     stype - 全断面タイプ配列 [nsec×1]
%     gdir - 梁方向 [nmg×1] (PRM.X or PRM.Y)
%     idmg2n - 梁端節点ID [nmg×2]（左端、右端）
%     idsup2n - 支点節点ID [nsup×1]
%
%   出力引数:
%     lrgirder - 梁剛域長 [nmg×2]
%                (1列目:左端、2列目:右端)

% 定数
nmg = size(idmg2sfl,1);
alfa = 0.25;

% 計算の準備
lrgirder = zeros(nmg,2);

% 梁の剛域長さ計算
for ig=1:nmg
  
  % 柱のとりつきを調べる（上下の柱を考慮）
  for ilr=1:2
    switch ilr
      case 1
        ids_all = idmg2sfl(ig,:);  % 左端の全柱（上下）
      case 2
        ids_all = idmg2sfr(ig,:);  % 右端の全柱（上下）
    end
    
    % 最小・最大柱面サイズの初期化
    min_col_size = inf;
    max_col_size = 0;

    % 梁端節点が支点かどうかを確認
    is_support = any(idmg2n(ig,ilr) == idsup2n);

    % 全列を走査して柱をチェック
    for i = 1:length(ids_all)
      idsc = ids_all(i);
      if idsc <= 0
        continue
      end

      % 基礎柱のチェック（支点のある梁端部でのみ考慮）
      if any(idsc==idscb2s) && is_support
        Df = cbsDf(idsc==idscb2s);
        min_col_size = min(min_col_size, Df);
        max_col_size = max(max_col_size, Df);
      end

      % RC柱に接続する場合
      if stype(idsc) == PRM.RCRS
        % X方向梁：RC柱のY方向寸法（幅）
        % Y方向梁：RC柱のX方向寸法（せい）
        % 実寸法を使用（列1-2、SS7仕様）
        if gdir(ig) == PRM.X
          rc_dim = secdim(idsc,2);  % RC柱幅（実寸法）
        else  % PRM.Y
          rc_dim = secdim(idsc,1);  % RC柱せい（実寸法）
        end
        min_col_size = min(min_col_size, rc_dim);
        max_col_size = max(max_col_size, rc_dim);
      end
    end
    
    % 剛域長の計算（SS7仕様書3.3.1準拠）
    if min_col_size < inf  % 柱が存在する場合
      if mgstype(ig)==PRM.RCRS
        % RC梁の場合：最小柱面/2 - α×梁せい
        % SS7仕様書：取り付く柱の最小値からαDを引く
        lrgirder(ig,ilr) = min_col_size*0.5 - alfa*sdimgm(ig,2);
      else  % WFS (S梁)
        % S梁の場合：最大柱面/2（コンクリート柱面）
        lrgirder(ig,ilr) = max_col_size*0.5;
      end
    end
  end
end

% 負値は0に
lrgirder(lrgirder<0) = 0;
return
end

