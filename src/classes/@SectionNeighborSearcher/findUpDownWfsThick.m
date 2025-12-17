function [upsec, dwsec] = findUpDownWfsThick(secwfs, twortf, seclist, options)
%findUpDownWfsThick WFS断面の板厚増減を探索
%   指定されたWFS断面からウェブまたはフランジ板厚を1段階増減した
%   断面を探索します。同じH,B寸法を持つ断面リストから、指定された
%   板厚が次に大きい/小さい断面を選択します。
%
%   入力引数:
%     secwfs - 対象WFS断面 [H, B, tw, tf]
%     twortf - 対象板厚 ('tw'または'tf')
%     seclist - 断面リスト [nlist×4]
%     options - オプション構造体（tolHgap, tolBgap含む）
%
%   出力引数:
%     upsec - 板厚を増やした断面 [H, B, tw, tf]（存在しない場合は空）
%     dwsec - 板厚を減らした断面 [H, B, tw, tf]（存在しない場合は空）

% H,Bに適合する断面を抽出
isGivenH = abs(seclist(:,1)-secwfs(1)) <= options.tolHgap;
isGivenB = abs(seclist(:,2)-secwfs(2)) <= options.tolBgap;
isGiven = isGivenH & isGivenB;
seclist = seclist(isGiven, :);

% 対象板厚の列インデックスを決定
switch twortf
  case 'tw'
    tid = 3;  % ウェブ板厚
  case 'tf'
    tid = 4;  % フランジ板厚
  otherwise
    error('twかtfを指定してください')
end

% 対象板厚の配列を取得
t_list = seclist(:, tid);
t_current = secwfs(tid);

% ワンサイズアップ：現在より大きい中で最小の板厚
t_up = t_list(t_list > t_current);
if isempty(t_up)
  upsec = [];
else
  % 最小の板厚を持つ断面を選択
  idx_up = find(t_list == min(t_up), 1);
  upsec = seclist(idx_up, :);
end

% ワンサイズダウン：現在より小さい中で最大の板厚
t_down = t_list(t_list < t_current);
if isempty(t_down)
  dwsec = [];
else
  % 最大の板厚を持つ断面を選択
  idx_down = find(t_list == max(t_down), 1);
  dwsec = seclist(idx_down, :);
end

return
end



