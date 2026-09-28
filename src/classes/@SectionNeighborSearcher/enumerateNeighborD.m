function [xlist, xup, xdw, idvlist] = enumerateNeighborD( ...
  obj, xvar, idvar, ~)
%enumerateNeighborD - D寸法の近傍を設計変数の候補行へ展開する
%
%   [xlist, xup, xdw, idvlist] = enumerateNeighborD(obj, xvar,
%     idvar, options) は、getNeighborD が選んだ寸法から候補行を作る。
%   上側の候補行の後に下側の候補行を並べる。
%
%   入力引数:
%     obj     - SectionNeighborSearcherインスタンス
%     xvar    - 現在の変数値 [1×nx]
%     idvar   - 対象変数ID（空なら候補なし）
%     options - 共通オプション（未使用）
%
%   出力引数:
%     xlist  - 上下の候補行 [n×nx]
%     xup    - 上側の候補行 [nup×nx]
%     xdw    - 下側の候補行 [ndw×nx]
%     idvlist - 上下の候補行番号（up, dw）

[vup, vdw] = obj.getNeighborD(xvar(idvar),idvar);
nup = numel(vup);
ndw = numel(vdw);
xlist = repmat(xvar,nup+ndw,1);
% 空の候補行は全変数幅の0行行列として返す。
if ~isempty(xlist)
  xlist(:,idvar) = [vup; vdw];
end
xup = xlist(1:nup,:);
xdw = xlist(nup+1:end,:);
idvlist.up = 1:nup;
idvlist.dw = nup+1:nup+ndw;

return
end