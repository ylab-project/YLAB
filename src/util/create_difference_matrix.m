function Dmat = create_difference_matrix(idstory2H, nH)
%create_difference_matrix - 層方向の一次差分行列を作成
%
%   Dmat = create_difference_matrix(idstory2H, nH) は、各列の層順ID
%   から隣接する異なるID間の一次差分行列を作成する。ID 0は省き、
%   連続する同一IDだけを一つにまとめる。全列の行を連結した後、
%   同一の符号付き差分行を一意化し、逆向きの行は残す。
%
%   入力引数:
%     idstory2H - 層・符号ごとの局所梁せいID
%     nH        - 差分行列の列数
%
%   出力引数:
%     Dmat - 層方向の一次差分行列

% 各列で0を省き、連続する同一IDをまとめて隣接ペアを集める。
pair_set = cell(1, size(idstory2H, 2));
for i = 1:size(idstory2H, 2)
  ids = idstory2H(:, i);
  ids(ids == 0) = [];
  if ~isempty(ids)
    ids = ids([true; ids(2:end) ~= ids(1:end - 1)]);
  end
  % 1要素以下ではids(1:0)が1×0となり列数が崩れるため先に除く
  if numel(ids) < 2
    pair_set{i} = zeros(0, 2);
    continue
  end
  pair_set{i} = [ids(1:end - 1) ids(2:end)];
end

% 同じ向きのH変数ペアだけを一意化する。
pairs = unique(vertcat(pair_set{:}), 'rows', 'stable');

% 隣接IDの列へ[-1 1]を設定する。
nD = size(pairs, 1);
Dmat = zeros(nD, nH);
irow = (1:nD)';
Dmat(sub2ind([nD nH], irow, pairs(:, 1))) = -1;
Dmat(sub2ind([nD nH], irow, pairs(:, 2))) = 1;

return
end
