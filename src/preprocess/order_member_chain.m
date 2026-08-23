function [chain, ambiguous] = order_member_chain(ids, idnode1, idnode2)
%order_member_chain - 部材集合を接続順の直列セグメント列へ並べる
%
%   [chain, ambiguous] = order_member_chain(ids, idnode1, idnode2)
%   は、候補部材 ids を両端節点の接続をたどって始端側から並べる。
%   始端は、i端節点が他候補のj端節点に現れない部材とする。梁は
%   i端=左端軸側、柱はi端=柱脚として生成されるため（部材生成の端部
%   規約）、始端側が左端側・柱脚側になる。分岐、循環または複数経路
%   で順序を一意に決められない場合は ambiguous=true と空の chain を
%   返す。内部番号順をセグメント順として使用しない。
%
%   入力引数:
%     ids     - 候補部材の行番号 [1×k]
%     idnode1 - 全部材のi端節点番号 [n×1]
%     idnode2 - 全部材のj端節点番号 [n×1]
%
%   出力引数:
%     chain     - 接続順に並べた行番号 [1×k]。順序不定は空
%     ambiguous - 順序を一意に決められない場合 true
chain = zeros(1, 0);
ambiguous = false;
ids = ids(:).';
if isempty(ids)
  return
end
if isscalar(ids)
  chain = ids;
  return
end

inode1 = idnode1(ids);
inode2 = idnode2(ids);
start = ids(~ismember(inode1, inode2));
if length(start) ~= 1
  ambiguous = true;
  return
end

chain = start;
while length(chain) < length(ids)
  current_node = idnode2(chain(end));
  next = ids(idnode1(ids) == current_node);
  next = setdiff(next, chain, 'stable');
  if length(next) ~= 1
    chain = zeros(1, 0);
    ambiguous = true;
    return
  end
  chain(end + 1) = next; %#ok<AGROW>
end

return
end
