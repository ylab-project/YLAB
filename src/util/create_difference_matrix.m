function Dmat = create_difference_matrix(idstory2H, nH)
%create_difference_matrix - 層方向の一次差分行列を作成
%
%   Dmat = create_difference_matrix(idstory2H, nH) は、各通りの層順
%   断面IDから、隣接する異なる断面間の一次差分行列を作成する。
%   断面ID 0は対象外とし、連続する同一IDは一つにまとめる。
%
%   入力引数:
%     idstory2H - 層・通りごとの局所断面ID
%     nH        - 差分行列の列数
%
%   出力引数:
%     Dmat - 層方向の一次差分行列

% 通りごとに層順の重複を除き、必要な差分行数を先に確定する。
id_set = cell(1, size(idstory2H, 2));
nD = 0;
for i = 1:size(idstory2H, 2)
  id_section = idstory2H(:, i);
  id_section(id_section == 0) = [];
  id_set{i} = unique(id_section, 'stable');
  nD = nD + max(numel(id_set{i}) - 1, 0);
end

% 隣接する断面IDの列へ[-1 1]を設定する。
Dmat = zeros(nD, nH);
id = 0;
for i = 1:numel(id_set)
  id_section = id_set{i};
  for j = 1:numel(id_section) - 1
    id = id + 1;
    Dmat(id, id_section([j j + 1])) = [-1 1];
  end
end
Dmat = Dmat(1:id, :);

return
end