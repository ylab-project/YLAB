function [lfcolumnx, lfcolumny] = comp_face_length_column(...
  secdim, stdh, column_idz, girder_level, stype, ...
  idmc2sf1x, idmc2sf2x, idmc2sf1y, idmc2sf2y, idmc2st, ...
  idmc2mf1x, idmc2mf2x, idmc2mf1y, idmc2mf2y, gcxl, gcyl, ccxl, ~)
%comp_face_length_column 柱のフェイス長を計算
%   斜め柱の場合、フェイス長を柱軸方向に投影補正する

% 定数
nmc = size(idmc2sf1x,1);
nstory = size(stdh,1);

% 計算の準備
lfcolumnx = zeros(nmc,2);
lfcolumny = zeros(nmc,2);
gczl = cross(gcxl, gcyl, 2);

% 柱軸方向のZ成分を取得
% ccxl は部材軸方向（i端からj端）の方向余弦 [cx, cy, cz]
% 柱軸のZ成分 = ccxl(:,3) = cos(θ)、θは柱軸と鉛直線のなす角度
cz = ccxl(:,3);

% 柱の梁面長さ
for ic=1:nmc
  % 斜め柱の投影補正係数を計算
  if abs(cz(ic)) > 1e-6
    proj_factor = 1 / abs(cz(ic));
  else
    proj_factor = 1;
  end
  % ist = idmc2st(i);
  for ij=1:2
    switch ij
      case 1
        % 柱脚側
        ist = column_idz(ic,1);
        % dh = -stdh(ist-1);
        if ist>nstory
          % TODO: とりあえず
          continue
        end
        dh = -stdh(ist);
        for idir = 1:2
          switch idir
            case PRM.X
              idmg = idmc2mf1x(ic,:);
            case PRM.Y
              idmg = idmc2mf1y(ic,:);
          end
          if any(idmg>0)
            gldh = zeros(length(idmg),1)+dh;
            gldh(idmg>0) = gldh(idmg>0) ...
              +girder_level(idmg(idmg>0));
            gldh = gldh(idmg>0);
          else
            % gldh = dh;
            gldh = 0;
          end
          gldh = max(gldh);
          switch idir
            case PRM.X
              lfcolumnx(ic,ij) = gldh * proj_factor;
            case PRM.Y
              lfcolumny(ic,ij) = gldh * proj_factor;
          end
        end
      case 2
        % 柱頭側
        ist = column_idz(ic,2);
        if ist>nstory
          % TODO: とりあえず
          continue
        end
        dh = -stdh(ist);
        for idir = 1:2
          switch idir
            case PRM.X
              ids = idmc2sf2x(ic,:);
              idmg = idmc2mf2x(ic,:);
            case PRM.Y
              ids = idmc2sf2y(ic,:);
              idmg = idmc2mf2y(ic,:);
          end
          gczl_ = ones(length(idmg),1);
          gczl_(idmg>0) = gczl(idmg(idmg>0),3);
          if any(idmg>0)
            gldh = zeros(length(idmg),1)-dh;
            % 断面タイプに応じて梁せいを取得（S梁:列1、RC梁:列2）
            ids_valid = ids(ids>0);
            H_girder = zeros(length(ids_valid),1);
            for k = 1:length(ids_valid)
              if stype(ids_valid(k)) == PRM.RCRS
                H_girder(k) = secdim(ids_valid(k),2);
              else
                H_girder(k) = secdim(ids_valid(k),1);
              end
            end
            gldh(idmg>0) = gldh(idmg>0) ...
              +H_girder./gczl_(idmg>0) ...
              -girder_level(idmg(idmg>0));
            gldh = gldh(idmg>0);
          else
            % gldh = -dh;
            gldh = 0;
          end
          gldh = max(gldh);
          switch idir
            case PRM.X
              lfcolumnx(ic,ij) = gldh * proj_factor;
            case PRM.Y
              lfcolumny(ic,ij) = gldh * proj_factor;
          end
        end
    end
  end
end

% 負値は0にする
lfcolumnx(lfcolumnx<0) = 0;
lfcolumny(lfcolumny<0) = 0;
return
end

