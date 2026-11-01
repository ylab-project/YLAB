function element_force = parse_legacy_girder_force_block( ...
  element_force, com)
%parse_legacy_girder_force_block - 従来梁要素荷重を梁の区間へ対応付ける
%
%   element_force = parse_legacy_girder_force_block(element_force, com)
%   は、配置指定から梁を検索し、分割梁の継続行を各区間へ適用する。
%   荷重の長さ比による再配分は行わない。
%
%   入力引数:
%     element_force - 正規化した配置指定・継続順・荷重値のテーブル
%     com           - 梁と基準線を持つ解析モデル
%
%   出力引数:
%     element_force - 全体部材番号に解決した線材荷重テーブル

n = height(element_force);
member_girder = com.member.girder;
idmg2m = member_girder.idme;
idsplit = member_girder.idsplit;
is_continued = element_force.is_continued;
story_name = element_force.selector(:, 1);
frame_name = element_force.selector(:, 2);
coord_name = element_force.selector(:, 3:4);
[idx, idy, idz] = find_idxyz_girder(story_name, frame_name, ...
  coord_name, com.baseline);
idmgs = find_idgirder_from_idxyz(idx, idy, idz, member_girder, ...
  [], com.baseline);

% 分割梁の継続行は入力順に区間へ割り当て、入力値をそのまま残す。
idme = zeros(n, 1);
for i = 1:n
  if i > 1 && is_continued(i-1)
    continue
  end
  ids = nonzeros(idmgs(i, :));
  if numel(ids) > 1 && any(idsplit(ids) > 0)
    if ~is_continued(i)
      error('分割梁に継続列がありません（行%d）', i);
    end
    idmeg_all = build_split_group(idmgs(i, :), idsplit);
    assert(length(idmeg_all) == 2, '継続行ペア処理は2分割梁のみ対応');
    idme(i:i+1) = idmg2m(idmeg_all(1:2));
  elseif ~isempty(ids)
    idme(i) = idmg2m(ids(1));
  end
end

% 入力位置と荷重値を残し、新形式と共通の成分列を追加する。
element_force = removevars(element_force, {'selector', 'is_continued'});
element_force = addvars(element_force, idme, 'Before', 1);
M0y = zeros(n, 1);
M0z = zeros(n, 1);
quarter = nan(n, 4);
wclass = zeros(n, 1);
wusage = zeros(n, 1);
wtype = zeros(n, 1);
element_force = addvars(element_force, M0y, M0z, quarter, wclass, ...
  wusage, wtype, 'After', 'M0');
element_force = element_force(idme > 0, :);

return
end


function idmeg_all = build_split_group(idmgs_row, idsplit)
%build_split_group - idsplitチェーンから分割梁グループを構築
%
%   idmeg_all = build_split_group(idmgs_row, idsplit) は、
%   idmgs_row内のidsplit>0の部材からidsplitを辿り、
%   分割梁グループを通り順（昇順）で返す。
%
%   入力引数:
%     idmgs_row - 梁番号の行ベクトル [1×m]
%     idsplit   - idsplit配列 [全梁数×1]
%
%   出力引数:
%     idmeg_all - 分割梁グループ [1×k]（昇順）

ids = idmgs_row(idmgs_row > 0);
% idsplit>0の部材を起点にする
start = ids(idsplit(ids) > 0);
ig1 = start(1);
idmeg_all = sort([ig1, idsplit(ig1)]);

return
end
