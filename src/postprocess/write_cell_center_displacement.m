function [cdhead, cdbody] = write_cell_center_displacement(com, result, ...
  icase)
%write_cell_center_displacement - 各層の重心位置の変位を配置する
%
%   [cdhead, cdbody] = write_cell_center_displacement(com, result,
%   icase) は、剛床の代表節点に対応する水平変位と回転を上層から
%   並べる。代表節点を持たない層は出力しない。
%
%   入力引数:
%     com    - 層、節点および自由度情報
%     result - 解析変位dvecを持つ解析結果
%     icase  - 出力する荷重ケース番号
%
%   出力引数:
%     cdhead - 帳票ヘッダー
%     cdbody - 各層の重心位置の変位

nstory = com.nstory;
story = com.story;
dvec = result.dvec;
n2df = com.node.dof;

cdhead = {'層', 'Ux', 'Uy', 'φ'; '', 'mm', 'mm', 'rad'};
cdbody = cell(nstory, 4);
irow = 0;
for i = 1:nstory
  ist = nstory - i + 1;
  in = story.idnoderep(ist);
  if isnan(in)
    continue
  end
  irow = irow + 1;
  cdbody{irow, 1} = story.name{ist};
  ddd = dvec(n2df(in, [1 2 6]), icase);
  cdbody{irow, 2} = sprintf('%.5f', ddd(1));
  cdbody{irow, 3} = sprintf('%.5f', ddd(2));
  cdbody{irow, 4} = sprintf('%.7f', ddd(3));
end
cdbody = cdbody(1:irow, :);

return
end
