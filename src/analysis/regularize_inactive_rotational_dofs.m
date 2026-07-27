function [ksmat, fvec, ignored_node] = ...
  regularize_inactive_rotational_dofs(ksmat, fvec, idf2node, ...
  idn2df, idsup2n, isfixedsup)
%regularize_inactive_rotational_dofs - 孤立回転自由度を正規化する
%
%   [ksmat, fvec, ignored_node] = ...
%     regularize_inactive_rotational_dofs(ksmat, fvec, ...
%     idf2node, idn2df, idsup2n, isfixedsup) は、支点で拘束されず
%   回転剛性を持たない成分4・5の自由度について、外力を0にし、
%   対角へ正規化剛性を設定する。
%
%   入力引数:
%     ksmat      - 支点剛性加算前の全体剛性行列 [ndf x nbw]
%     fvec       - 正規化前の外力ベクトル [ndf x nlc]
%     idf2node   - 自由度から節点・成分への変換 [ndf x 2]
%     idn2df     - 節点から自由度への変換 [nnode x 6]
%     idsup2n    - 支点から節点への変換 [nsup x 1]
%     isfixedsup - 支点拘束フラグ [nsup x 6]
%
%   出力引数:
%     ksmat        - 正規化剛性を設定した全体剛性行列
%     fvec         - 孤立回転自由度の外力を0にしたベクトル
%     ignored_node - 無視した節点モーメント [nnode x 6 x nlc]
%
%   備考:
%     - 正規化剛性は物理ばねではなく、孤立自由度をθ=0とする。
%     - 支点拘束自由度はadd_sup_stifで剛性が入るため対象外とする。

target_components = [4 5];
ndf = size(idf2node,1);
support_fixed = false(ndf,1);
for comp = target_components
  fixed_supports = isfixedsup(:,comp);
  support_dofs = idn2df(idsup2n(fixed_supports),comp);
  support_dofs = support_dofs(support_dofs > 0);
  support_fixed(support_dofs) = true;
end

is_target = ismember(idf2node(:,2), target_components);
has_node = idf2node(:,1) ~= 0;
has_no_stiffness = abs(ksmat(:,1)) <= PRM.TOL_STIFF_UNSTABLE;
is_inactive = has_node & is_target & ~support_fixed & has_no_stiffness;

nnode = size(idn2df,1);
nlc = size(fvec,2);
ignored_node = zeros(nnode,6,nlc);
inactive_dofs = find(is_inactive);
for idf = reshape(inactive_dofs,1,[])
  idnode = idf2node(idf,1);
  comp = idf2node(idf,2);
  ignored_node(idnode,comp,:) = reshape(fvec(idf,:),1,1,nlc);
end

fvec(is_inactive,:) = 0;
ksmat(is_inactive,1) = PRM.STIFF_ROTATIONAL_DOF_REGULARIZATION;

return
end
