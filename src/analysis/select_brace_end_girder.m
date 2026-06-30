function ig = select_brace_end_girder(idg)
%select_brace_end_girder - ブレース端点の採用梁番号を返す
%
%   ig = select_brace_end_girder(idg) は、ブレース端点に接続する
%   梁候補 idg から現行仕様で採用する梁番号を返す。候補がない
%   場合は0を返す。
%
%   入力引数:
%     idg - 接続梁候補の部材番号配列（0を含む）
%
%   出力引数:
%     ig - 採用する梁部材番号（0=梁なし）

ig = 0;
idg = idg(idg > 0);
if isempty(idg)
  return
end
ig = idg(1);

return
end
