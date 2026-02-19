function fvec = add_rigid_eccentric_moment(...
  fvec, idnode, fx, fy, ilc, node, story)
%add_rigid_eccentric_moment - 剛床の偏心モーメント計算
%
%   fvec = add_rigid_eccentric_moment(fvec, idnode, fx, fy,
%     ilc, node, story) は、
%   剛床内の節点に水平力(fx, fy)がかかった場合、
%   重心まわりのモーメントをfvecに加算する。
%
%   入力引数:
%     fvec   - 等価節点力ベクトル [ndf×nlc]
%     idnode - 対象節点番号
%     fx, fy - 水平力成分（スカラー）
%     ilc    - 荷重ケース番号
%     node   - 節点情報構造体
%     story  - 層情報構造体
%
%   出力引数:
%     fvec - 偏心モーメント加算後の等価節点力ベクトル

is_ = node.idstory(idnode);
if story.isrigid(is_)
  xr_ = node.xr(idnode);
  yr_ = node.yr(idnode);
  Mz_add = fx*(-yr_) + fy*xr_;
  idof_rz = node.dof(idnode, 6);
  fvec(idof_rz, ilc) = fvec(idof_rz, ilc) + Mz_add;
end

return
end
