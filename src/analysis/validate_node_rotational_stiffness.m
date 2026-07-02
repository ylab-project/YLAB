function validate_node_rotational_stiffness(ksmat0, node, ...
  idf2node, idsup2n, isfixedsup, idn2df)
%validate_node_rotational_stiffness - 回転自由度の剛性欠落を検出
%
%   validate_node_rotational_stiffness(ksmat0, node, idf2node, ...
%     idsup2n, isfixedsup, idn2df) は、支点剛性加算前の全体剛性
%   行列 ksmat0 から、支点拘束されない RX/RY 回転自由度の剛性欠落
%   を検出し、入力エラーを発生させる。
%
%   入力引数:
%     ksmat0 - 支点剛性加算前の全体剛性行列 [ndf×nbw]
%     node - 節点構造体
%     idf2node - 自由度番号から節点番号・成分番号への変換 [ndf×2]
%     idsup2n - 支点番号から節点番号への変換 [nsup×1]
%     isfixedsup - 支点拘束フラグ [nsup×6]
%     idn2df - 節点番号から自由度番号への変換 [nnode×6]

target_components = [4 5];

% 支点拘束される回転自由度を事前に集約する
support_fixed = false(size(idf2node, 1), 1);
for comp = target_components
  dofs = idn2df(idsup2n(isfixedsup(:, comp)), comp);
  support_fixed(dofs(dofs > 0)) = true;
end

% 対象成分・非ダミー・非支点拘束で対角剛性が欠落する自由度
is_unstable = ismember(idf2node(:, 2), target_components) ...
  & idf2node(:, 1) ~= 0 & ~support_fixed ...
  & abs(ksmat0(:, 1)) <= PRM.TOL_STIFF_UNSTABLE;
idf = find(is_unstable, 1);

if ~isempty(idf)
  comp = idf2node(idf, 2);
  idnode = select_location_node(node, idn2df, idf, comp);
  throw_rot_stiff_error(node, idnode, comp);
end

return
end

% -------------------------------------------------------------------------
function idnode = select_location_node(node, idn2df, idf, comp)
%select_location_node - エラーメッセージに表示する節点を選択
%
%   idnode = select_location_node(node, idn2df, idf, comp) は、
%   指定自由度番号に対応する節点から、同一化されていない節点を
%   優先して表示用節点番号を返す。
%
%   入力引数:
%     node - 節点構造体
%     idn2df - 節点番号から自由度番号への変換 [nnode×6]
%     idf - 自由度番号
%     comp - 成分番号
%
%   出力引数:
%     idnode - 表示用節点番号

candidates = find(idn2df(:, comp) == idf);
base_nodes = candidates(node.idrep(candidates) == 0);
if isempty(base_nodes)
  idnode = candidates(1);
else
  idnode = base_nodes(1);
end

return
end

% -------------------------------------------------------------------------
function throw_rot_stiff_error(node, idnode, comp)
%throw_rot_stiff_error - 回転剛性欠落エラーを発生
%
%   throw_rot_stiff_error(node, idnode, comp) は、節点が保持する
%   階名・通り名と成分番号から方向名を取得し、
%   NodeRotationalStiffnessMissing エラーを発生させる。
%
%   入力引数:
%     node - 節点構造体
%     idnode - 節点番号
%     comp - 成分番号

dir_name = rotation_direction_name(comp);
throw_err('Input', 'NodeRotationalStiffnessMissing', ...
  node.zname{idnode}, node.xname{idnode}, node.yname{idnode}, ...
  dir_name);

return
end

% -------------------------------------------------------------------------
function dir_name = rotation_direction_name(comp)
%rotation_direction_name - 回転成分番号から方向名を取得
%
%   dir_name = rotation_direction_name(comp) は、成分番号 4/5 を
%   エラーメッセージ用の X/Y 方向名に変換する。
%
%   入力引数:
%     comp - 成分番号
%
%   出力引数:
%     dir_name - 方向名

if comp == 4
  dir_name = 'X';
else
  dir_name = 'Y';
end

return
end
