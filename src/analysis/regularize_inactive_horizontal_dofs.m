function ksmat = regularize_inactive_horizontal_dofs( ...
  ksmat, fvec, idf2node)
%regularize_inactive_horizontal_dofs - 無荷重の孤立水平自由度を固定する
%
%   ksmat = regularize_inactive_horizontal_dofs(ksmat, fvec, ...
%     idf2node) は、反復解析中にX・Y方向の剛性と外力がともに
%   0となった節点自由度へ対角剛性を設定する。圧縮ブレースの
%   剛性除去はその代表的な発生原因である。外力が作用する
%   不安定自由度は変更しない。
%
%   入力引数:
%     ksmat    - 全体剛性行列の上三角帯格納 [ndf×nbw]
%     fvec     - 対象荷重ケースの外力 [ndf×1]
%     idf2node - 自由度から節点・成分への変換 [ndf×2]
%
%   出力引数:
%     ksmat - 無荷重の孤立水平自由度を固定した全体剛性行列
%
%   備考:
%     設定する対角剛性は物理ばねではなく、剛性を失って値が
%     不定となった水平変位を0とするための数値上の拘束である。

target_components = [1, 2];
has_node = idf2node(:, 1) ~= 0;
is_horizontal = ismember(idf2node(:, 2), target_components);
has_no_stiffness = abs(ksmat(:, 1)) <= PRM.TOL_STIFF_UNSTABLE;
has_no_load = fvec == 0;
is_inactive = has_node & is_horizontal & has_no_stiffness & has_no_load;

ksmat(is_inactive, 1) = PRM.STIFF_HORIZONTAL_DOF_REGULARIZATION;

return
end
