function str = format_steel_cost_dim(stype, dim, sym)
%format_steel_cost_dim - SS7形式の鉄骨断面名を生成
%
%   str = format_steel_cost_dim(stype, dim, sym) は、
%   断面タイプに応じたSS7積算用の断面名文字列を
%   生成する。
%
%   入力引数:
%     stype - 断面タイプ (PRM.HSS, PRM.WFS 等)
%     dim   - 断面寸法ベクトル [1×ncol]
%     sym   - 断面記号文字列
%
%   出力引数:
%     str - 断面名文字列 (例: 'H-400*200*8*13')

switch stype
  case PRM.HSS
    str = sprintf('%s-%g*%g*%g*%g', sym, dim(1), dim(1), dim(2), dim(3));
  case {PRM.WFS, PRM.BWFS}
    if dim(5) > 0
      str = sprintf( ...
        '%s-%g*%g*%g*%g*%g', sym, ...
        dim(1), dim(2), dim(3), ...
        dim(4), dim(5));
    else
      str = sprintf('%s-%g*%g*%g*%g', sym, dim(1), dim(2), dim(3), dim(4));
    end
  case PRM.BHSS
    str = sprintf('%s-%g*%g*%g*%g', sym, dim(1), dim(1), dim(2), dim(3));
  case PRM.BHSR
    str = sprintf('%s-%g*%g', sym, dim(1), dim(2));
  case PRM.TB
    str = sym;
  otherwise
    str = '';
end

return
end
