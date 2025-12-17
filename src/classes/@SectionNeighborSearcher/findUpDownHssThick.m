function [upsec, dwsec] = findUpDownHssThick(sechss, seclist, options)
%findUpDownHssThick HSS断面の板厚増減を探索
%   指定されたHSS断面から板厚を1段階増減した断面を探索します。
%   同じD寸法を持つ断面リストから、板厚が次に大きい/小さい断面を
%   選択します。
%
%   入力引数:
%     sechss - 対象HSS断面 [D, t]
%     seclist - 断面リスト [nlist×6]
%     options - オプション構造体（tolDgap含む）
%
%   出力引数:
%     upsec - 板厚を増やした断面 [D, t]（存在しない場合は空）
%     dwsec - 板厚を減らした断面 [D, t]（存在しない場合は空）

% Dに適合する断面を抽出（最初の2列のみ使用）
isGivenD = abs(seclist(:,1)-sechss(1)) <= options.tolDgap;
seclist = seclist(isGivenD, 1:2);

% 板厚tの配列を取得
t_list = seclist(:,2);
t_current = sechss(2);

% ワンサイズアップ：現在より大きい中で最小のt
t_up = t_list(t_list > t_current);
if isempty(t_up)
  upsec = [];
else
  idx_up = find(t_list == min(t_up), 1);
  upsec = seclist(idx_up, :);
end

% ワンサイズダウン：現在より小さい中で最大のt
t_down = t_list(t_list < t_current);
if isempty(t_down)
  dwsec = [];
else
  idx_down = find(t_list == max(t_down), 1);
  dwsec = seclist(idx_down, :);
end

return
end



