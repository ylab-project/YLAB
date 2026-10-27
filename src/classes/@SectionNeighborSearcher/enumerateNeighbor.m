function [xlist, index] = enumerateNeighbor(obj, xvar, ...
  idvar, vtype_id, options)
%enumerateNeighbor - 変数種別に応じた近傍断面を列挙
%
%   [xlist, index] = enumerateNeighbor(obj, xvar, idvar,
%     vtype_id, options) は、指定した変数種別に対応する列挙メソッドを
%   呼び出し、近傍断面と上下方向の行番号を返す。
%
%   入力引数:
%     obj      - SectionNeighborSearcherインスタンス
%     xvar     - 現在の変数値 [1×nxvar]
%     idvar    - 列挙対象の変数ID
%     vtype_id - 列挙対象の変数種別
%     options  - 共通オプション
%
%   出力引数:
%     xlist   - 列挙した近傍断面の変数値リスト
%     index   - 上下方向の行番号（.up、.dw）

xlist = [];
index = struct('up', [], 'dw', []);
switch vtype_id
  case PRM.WFS_H
    [xlist, ~, ~, index] = obj.enumerateNeighborH(xvar, idvar, options);
  case PRM.WFS_B
    [xlist, ~, ~, index] = obj.enumerateNeighborB(xvar, idvar, options);
  case PRM.WFS_TW
    [xlist, ~, ~, ~, index] = obj.enumerateNeighborTw( ...
      xvar, idvar, options);
  case PRM.WFS_TF
    [xlist, ~, ~, ~, index] = obj.enumerateNeighborTf( ...
      xvar, idvar, options);
  case PRM.HSS_D
    [xlist, ~, ~, index] = obj.enumerateNeighborD(xvar, idvar, options);
  case PRM.HSS_T
    [xlist, ~, ~, ~, index] = obj.enumerateNeighborT( ...
      xvar, idvar, options);
  case PRM.BRB_V1
    [xlist, ~, ~, index] = obj.enumerateBrbV1(xvar, idvar, options);
  case PRM.BRB_V2
    [xlist, ~, ~, index] = obj.enumerateBrbV2(xvar, idvar, options);
end

return
end