function [idmeg2secl, idmeg2secr] = countup_girder_to_column_face(com)
%countup_girder_to_column_face - 梁端部に対面する柱断面IDを取得
%
% 各梁の両端（i端・j端）に接続する柱の断面IDを取得する。
% 梁荷重計算用の部材長（柱面間内法長さ）の算出に使用する。
%
% Inputs:
%   com - 共通オブジェクト
%
% Outputs:
%   idmeg2secl - 梁i端に対面する柱断面ID [nmeg×ncol]
%   idmeg2secr - 梁j端に対面する柱断面ID [nmeg×ncol]
%                ncol: 最大接続柱本数（節点同一化により複数柱が接続する場合に対応）
%
% Note:
%   柱が存在しない場合は0が格納される。
%   呼び出し側では ids(ids>0) でフィルタリングして使用すること。

% 共通定数
nmec = com.nmec;
nmeg = com.nmeg;

% 共通配列
idmeg2n = [com.member.girder.idnode1 com.member.girder.idnode2];
idmec2n = [com.member.column.idnode1 com.member.column.idnode2];
idmec2sec = com.section.column.idsec(com.member.column.idsecc);
iccc = 1:nmec;

% 最大接続柱本数を調査
maxcol = 0;
for ig = 1:nmeg
  for ilr = 1:2  % 1:i端, 2:j端
    for idu = 1:2  % 1:柱下端, 2:柱上端
      idmec = iccc(any(idmec2n(:,idu)==idmeg2n(ig,ilr),2));
      maxcol = max(maxcol, length(idmec));
    end
  end
end

% 最低2列は確保（従来の上下2列に相当）
ncol = max(2, maxcol);

% 出力配列の初期化
idmeg2secl = zeros(nmeg, ncol);
idmeg2secr = zeros(nmeg, ncol);

% 各梁について対面柱を探索
for ig = 1:nmeg
  for ilr = 1:2  % 1:i端, 2:j端
    iddd = zeros(1, ncol);
    idx = 0;
    for idu = 1:2  % 1:柱下端, 2:柱上端
      % 梁端部節点と一致する柱端部を持つ柱を検索
      idmec = iccc(any(idmec2n(:,idu)==idmeg2n(ig,ilr),2));

      % 柱断面IDを格納（複数柱に対応）
      for k = 1:length(idmec)
        idx = idx + 1;
        iddd(idx) = idmec2sec(idmec(k));
      end
    end
    % i端またはj端に格納
    if ilr == 1
      idmeg2secl(ig,:) = iddd;
    else
      idmeg2secr(ig,:) = iddd;
    end
  end
end

return
end

