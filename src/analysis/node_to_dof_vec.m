function fvec = node_to_dof_vec(f_raw, node, story, ndf, apply_eccentric)
%node_to_dof_vec - (nnode, 6, nlc) 節点荷重を (ndf, nlc) DOF ベクトルへ変換
%
% 各節点の DOF マップ node.dof を介して DOF に値を集約する。
% 剛床節点の PX / PY / MZ は共有 DOF であるため、自動的に代表節点
% DOF に合算される。apply_eccentric が true のときは、剛床節点の
% 水平力 (fx, fy) による重心まわりの偏心モーメント fx*(-yr)+fy*xr
% を代表節点 MZ DOF に加算する。節点荷重 fnode は重心作用とみなし
% 偏心モーメントを計算しない慣例があるため、その場合は false を指定。
%
% Inputs:
%   f_raw           - 節点荷重配列 (nnode, 6, nlc)
%                     第2軸 = [PX, PY, PZ, MX, MY, MZ]
%   node            - 節点情報構造体 (.dof, .xr, .yr, .idstory)
%   story           - 層情報構造体 (.isrigid)
%   ndf             - 全体自由度数
%   apply_eccentric - 偏心 Mz を加算するか（省略時 true）
%
% Outputs:
%   fvec  - DOF ベクトル (ndf, nlc)

if nargin < 5
  apply_eccentric = true;
end

nnode = size(f_raw, 1);
nlc = size(f_raw, 3);
idn2df = node.dof;
xr = node.xr;
yr = node.yr;
idstory = node.idstory;
isrigid = story.isrigid;

fvec = zeros(ndf, nlc);
for ilc = 1:nlc
  for in = 1:nnode
    idof = idn2df(in, :);
    f_in = reshape(f_raw(in, :, ilc), 6, 1);
    fvec(idof, ilc) = fvec(idof, ilc) + f_in;
    if ~apply_eccentric
      continue
    end
    is_ = idstory(in);
    if is_ > 0 && isrigid(is_)
      Mz_add = f_in(1)*(-yr(in)) + f_in(2)*xr(in);
      fvec(idof(6), ilc) = fvec(idof(6), ilc) + Mz_add;
    end
  end
end

return
end
