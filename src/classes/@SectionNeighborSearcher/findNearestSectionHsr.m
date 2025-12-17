function [hsrsec, rephsrs, id] = ...
  findNearestSectionHsr(obj, xvar, idslist, options)
%findNearestSectionHsr HSR断面の最近傍選択
%   [hsrsec, rephsrs, id] = findNearestSectionHsr(obj, xvar, idslist,
%     options) は、変数値から最近傍のHSR断面を選択します。
%
%   断面選択アルゴリズム:
%     1. 完全一致チェック: 目標値（D,t）と候補断面を比較
%     2. 最近傍選択: ユークリッド距離が最小となる断面を選択
%
%   データ取り扱いルール:
%     - xvar: 設計変数（D=外径, t=板厚）
%     - secdimlist: 断面リストデータ
%       - 列1: 外径D [mm]
%       - 列2: 板厚t [mm]
%     - HSR断面は一般規格品なので代表断面の概念は不要
%
%   入力引数:
%     xvar      - 設計変数ベクトル [nxvar×1]
%     idslist   - 断面リストID (スカラー)
%     options   - オプション構造体
%
%   出力引数:
%     hsrsec  - HSR断面寸法 [nhsrs×2]
%     rephsrs - 代表HSR断面（HSRでは全断面が代表）[nhsrs×2]
%     id      - ID構造体（.slist, .section）

% HSR断面の断面リストIDを取得
idsec2stype = obj.idMapper_.idsec2stype;
idSectionList = obj.idMapper_.idSectionList;
isHsr = (idsec2stype == PRM.HSR);
idhsrs2sec = find(isHsr);
nhsrs = length(idhsrs2sec);

% 代表HSR断面の変数IDを取得
idrephsr2hsr = obj.idMapper_.idrephsr2hsr;
idrephsr2var = obj.idMapper_.idrephsr2var;

% 断面リストの寸法データを取得
secdimlist_all = obj.standardAccessor_.getSectionDimension(idslist);
% idPhaseはstandardAccessorから取得
idPhase = obj.standardAccessor_.idPhase;
isvalid = obj.constraintValidator_.extractValidSectionFlags(idslist, idPhase);
secdimlist = secdimlist_all(isvalid,:);

% 代表HSR断面に対応する変数値を抽出（D,t）
nrephsr = size(idrephsr2var, 1);
xvar_D = zeros(nrephsr, 1);
xvar_t = zeros(nrephsr, 1);
for i = 1:nrephsr
  if idrephsr2var(i,1) > 0
    xvar_D(i) = xvar(idrephsr2var(i,1));
  end
  if idrephsr2var(i,2) > 0
    xvar_t(i) = xvar(idrephsr2var(i,2));
  end
end

% HSR断面へマッピング
xvar_D_hsr = xvar_D(idrephsr2hsr);
xvar_t_hsr = xvar_t(idrephsr2hsr);

% 断面選択処理
hsrsec = zeros(nhsrs, 2);
id.slist = zeros(nhsrs, 1);
id.section = zeros(nhsrs, 1);

for i = 1:nhsrs
  % 目標値
  target = [xvar_D_hsr(i), xvar_t_hsr(i)];

  % ユークリッド距離計算
  dist = sqrt(sum((secdimlist - target).^2, 2));

  % 最近傍断面を選択
  [~, idx] = min(dist);

  % 選択された断面を保存
  hsrsec(i,:) = secdimlist(idx,:);
  id.slist(i) = idslist;
  id.section(i) = idx;
end

% HSRでは全断面が代表断面（BRBのような製品固有の代表断面はない）
rephsrs = hsrsec;

return
end