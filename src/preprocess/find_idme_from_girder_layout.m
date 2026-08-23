function [chain, ambiguous] = find_idme_from_girder_layout(story_name, ...
  frame_name, axis1, axis2, com)
%find_idme_from_girder_layout - 配置指定から梁の部材番号列を返す
%
%   [chain, ambiguous] = find_idme_from_girder_layout(story_name,
%     frame_name, axis1, axis2, com) は、大梁配置と同じ層・フレーム・
%   左端軸・右端軸の指定から対象梁を特定し、両端節点の接続を左端側
%   からたどった全体部材番号の直列セグメント列を返す。層・フレーム・
%   軸の名前を解決できない場合、対象の梁がない場合、およびたどった
%   両端が指定軸と一致しない場合は空の chain を返す。K形ブレースで
%   分割された部材は複数セグメントになる。
%
%   端部規約: 梁部材はi端=配置の始端軸（左端軸）側、j端=終端軸側の
%   節点として生成される（set_member_girder_block）。この規約により
%   入力の左端→右端がそのままi端→j端の順に対応する。
%
%   入力引数:
%     story_name - 層名
%     frame_name - フレーム名（X軸名またはY軸名）
%     axis1      - 左端軸名
%     axis2      - 右端軸名
%     com        - 共通オブジェクト
%
%   出力引数:
%     chain     - 全体部材番号の直列セグメント列 [1×k]。対象なしは空
%     ambiguous - 接続順を一意に決められない場合 true
baseline = com.baseline;
member_girder = com.member.girder;
chain = zeros(1, 0);
ambiguous = false;

% 名前解決（フレーム名の軸種別で梁方向を確定する）
idz = find(strcmp(baseline.z.name, story_name), 1);
idfx = find(strcmp(baseline.x.name, frame_name), 1);
idfy = find(strcmp(baseline.y.name, frame_name), 1);
if isempty(idz) || (isempty(idfx) && isempty(idfy))
  return
end
if ~isempty(idfx)
  % フレームがX軸: Y方向の梁。左端軸・右端軸はY軸名
  idir = PRM.Y;
  id1 = find(strcmp(baseline.y.name, axis1), 1);
  id2 = find(strcmp(baseline.y.name, axis2), 1);
  idx_range = [idfx, idfx];
  idy_range = [id1, id2];
else
  % フレームがY軸: X方向の梁。左端軸・右端軸はX軸名
  idir = PRM.X;
  id1 = find(strcmp(baseline.x.name, axis1), 1);
  id2 = find(strcmp(baseline.x.name, axis2), 1);
  idx_range = [id1, id2];
  idy_range = [idfy, idfy];
end
if isempty(id1) || isempty(id2)
  return
end

% 指定区間に含まれる梁の検索（分割セグメントを含む）
idmgs = find_idgirder_from_idxyz(idx_range, idy_range, [idz, idz], ...
  member_girder, idir, baseline);
ids = idmgs(1, 1:nnz(idmgs(1, :)));
if isempty(ids)
  return
end

% 接続順の直列セグメント列を構成する
[ordered, ambiguous] = order_member_chain(ids, member_girder.idnode1, ...
  member_girder.idnode2);
if ambiguous || isempty(ordered)
  chain = zeros(1, 0);
  return
end

% たどった両端が指定軸と一致しない場合は対象なしとする
if idir == PRM.X
  is_matched = member_girder.idx(ordered(1), 1) == id1 ...
    && member_girder.idx(ordered(end), 2) == id2;
else
  is_matched = member_girder.idy(ordered(1), 1) == id1 ...
    && member_girder.idy(ordered(end), 2) == id2;
end
if ~is_matched
  return
end
chain = reshape(member_girder.idme(ordered), 1, []);

return
end
