function [chain, ambiguous] = find_idme_from_column_layout(floor_name, ...
  xaxis_name, yaxis_name, com)
%find_idme_from_column_layout - 配置指定から柱の部材番号列を返す
%
%   [chain, ambiguous] = find_idme_from_column_layout(floor_name,
%     xaxis_name, yaxis_name, com) は、柱配置と同じ階・X軸・Y軸の
%   指定から対象柱を特定し、両端節点の接続を柱脚側からたどった全体
%   部材番号の直列セグメント列を返す。指定を解決できない場合は空の
%   chain を返す。ブレース脚部で分割された柱（FOUNDATION・BODY）は
%   複数セグメントになる。
%
%   端部規約: 柱部材はi端=柱脚（下端）、j端=柱頭（上端）の節点と
%   して生成される（set_member_column_p2_block）。この規約により
%   入力の柱脚→柱頭がそのままi端→j端の順に対応する。分割で追加
%   された柱行は元の配置行の階名・軸名を保持するため、階・軸の照合
%   で分割セグメントも取得できる（set_member_brace_block）。
%
%   入力引数:
%     floor_name - 階名
%     xaxis_name - X軸名
%     yaxis_name - Y軸名
%     com        - 共通オブジェクト
%
%   出力引数:
%     chain     - 全体部材番号の直列セグメント列 [1×k]。対象なしは空
%     ambiguous - 接続順を一意に決められない場合 true
chain = zeros(1, 0);
ambiguous = false;
member_column = com.member.column;
ids = find(strcmp(member_column.floor_name, floor_name) ...
  & strcmp(member_column.coord_name(:, 1), xaxis_name) ...
  & strcmp(member_column.coord_name(:, 2), yaxis_name)).';
if isempty(ids)
  return
end
[ordered, ambiguous] = order_member_chain(ids, member_column.idnode1, ...
  member_column.idnode2);
if ambiguous || isempty(ordered)
  chain = zeros(1, 0);
  return
end
chain = reshape(member_column.idme(ordered), 1, []);

return
end
