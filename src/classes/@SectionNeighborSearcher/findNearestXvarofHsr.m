function xvar = findNearestXvarofHsr(obj, rephsr, xvar, options)
%findNearestXvarofHsr HSR断面から変数値を抽出
%   xvar = findNearestXvarofHsr(obj, rephsr, xvar, options) は、
%   HSR断面寸法データから対応する変数値を抽出します。
%
%   入力引数:
%     rephsr  - 代表HSR断面寸法 [nrephsr×2以上]
%               列1: 外径D [mm]
%               列2: 板厚t [mm]
%     xvar    - 既存の変数値ベクトル（拡張される）
%     options - オプション構造体
%
%   出力引数:
%     xvar    - 更新された変数値ベクトル

% HSR断面が存在しない場合は何もしない
if isempty(rephsr)
  return;
end

% 変数インデックスを取得
idrephsr2var = obj.idMapper_.idrephsr2var;
if isempty(idrephsr2var)
  return;
end

% 変数値を設定（D, t）
nrephsr = size(rephsr, 1);
for i = 1:nrephsr
  % D（外径）
  if idrephsr2var(i,1) > 0
    xvar(idrephsr2var(i,1)) = rephsr(i,1);
  end
  % t（板厚）
  if idrephsr2var(i,2) > 0
    xvar(idrephsr2var(i,2)) = rephsr(i,2);
  end
end

return
end