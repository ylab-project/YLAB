function bounds = computeBounds(obj, idsList, boundType)
%computeBounds 上限値または下限値を計算（内部用）
%   bounds = computeBounds(obj, idsList, boundType) は、指定された
%   断面リストIDに対する各変数の上限値または下限値を計算します。
%   getLowerBoundsとgetUpperBoundsの共通処理を提供します。
%
%   入力引数:
%     idsList - 断面リストID (スカラー整数、1～nlist)
%     boundType - 境界値タイプ ('lower' または 'upper')
%
%   出力引数:
%     bounds - 境界値ベクトル [1×nxvar]
%              該当しない変数はNaN
%
%   参考:
%     getLowerBounds, getUpperBounds

% 入力検証
if nargin < 3
  error('SectionConstraintValidator:InvalidArgs', ...
    'idsList と boundType が必要です');
end

obj.validateSectionListId(idsList);

% 境界値初期化
bounds = nan(1, obj.nxvar);

% 断面タイプを取得
sectionType = obj.secList_.section_type(idsList);

% 変数タイプセット
vtypeset = PRM.VTYPE_SET_BOUNDS();

for vtype = vtypeset
  % 該当する変数を特定
  istarget = obj.isVarofSlist(:,idsList) & ...
    obj.idvar2vtype == vtype;
  
  if all(~istarget)
    % 対象外の場合はスキップ
    continue
  end

  % 断面タイプと変数タイプの整合性チェック
  % WFS変数はWFS断面のみ、HSS変数はHSS断面のみで有効
  isValidCombination = false;
  switch vtype
    case {PRM.WFS_H, PRM.WFS_B, PRM.WFS_TW, PRM.WFS_TF}
      isValidCombination = (sectionType == PRM.WFS);
    case {PRM.HSS_D, PRM.HSS_T}
      isValidCombination = (sectionType == PRM.HSS);
    case {PRM.BRB_V1, PRM.BRB_V2}
      isValidCombination = (sectionType == PRM.BRB);
  end
  
  if ~isValidCombination
    % 断面タイプと変数タイプが不一致の場合はスキップ
    continue
  end

  % 変数タイプに応じて値を取得tou
  val = [];
  switch vtype
    case PRM.WFS_H
      val = obj.standardAccessor_.getNominalH(idsList);
    case PRM.WFS_B
      val = obj.standardAccessor_.getNominalB(idsList);
    case PRM.WFS_TW
      val = obj.standardAccessor_.getStandardTw(idsList);
    case PRM.WFS_TF
      val = obj.standardAccessor_.getStandardTf(idsList);
    case PRM.HSS_D
      val = obj.standardAccessor_.getStandardD(idsList);
    case PRM.HSS_T
      val = obj.standardAccessor_.getStandardT(idsList);
    case PRM.BRB_V1
      val = obj.standardAccessor_.getStandardV1(idsList);
    case PRM.BRB_V2
      val = obj.standardAccessor_.getStandardV2(idsList);
    case PRM.HSR_D
      val = obj.standardAccessor_.getStandardHsrD(idsList);  % HSR外径の標準値取得
    case PRM.HSR_T
      val = obj.standardAccessor_.getStandardHsrT(idsList);  % HSR板厚の標準値取得
  end

  % 境界値を設定
  if ~isempty(val)
    if strcmp(boundType, 'lower')
      bounds(istarget) = min(val);
    else % 'upper'
      bounds(istarget) = max(val);
    end
  end
end

return
end