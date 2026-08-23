function idnode = find_idnode_from_names(story_name, xaxis_name, ...
  yaxis_name, com)
%find_idnode_from_names - 層・X軸・Y軸の名前から節点番号を返す
%
%   idnode = find_idnode_from_names(story_name, xaxis_name,
%     yaxis_name, com) は、層・X軸・Y軸の名前を通り番号へ解決し、
%   節点検索を find_idnode_from_idxyz へ委譲して節点番号を返す。
%   節点同一化で代表節点を持つ節点は、既存検索と同じ規則で代表
%   節点へ置換される。名前を解決できない場合、または該当する節点が
%   ない場合は0を返す。
%
%   入力引数:
%     story_name - 層名
%     xaxis_name - X軸名
%     yaxis_name - Y軸名
%     com        - 共通オブジェクト
%
%   出力引数:
%     idnode - 節点番号（代表節点置換後）。見つからなければ0
idnode = 0;
baseline = com.baseline;
idz = find(strcmp(baseline.z.name, story_name), 1);
idx = find(strcmp(baseline.x.name, xaxis_name), 1);
idy = find(strcmp(baseline.y.name, yaxis_name), 1);
if isempty(idz) || isempty(idx) || isempty(idy)
  return
end
idnode = find_idnode_from_idxyz(idx, idy, idz, com.node);

return
end
