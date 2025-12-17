function secmgr = create_section_manager(...
  Hp, Bp, twp, tfp, Dp, tp, HsrDp, Hsrtp, brb1p, brb2p, com, secList, options)
%create_section_manager SectionManagerインスタンスを作成・初期化
%   リファクタリング後の新実装（Phase 1-4を含む）
%
%   入力引数:
%     Hp, Bp, twp, tfp - WFS断面の変数ID
%     Dp, tp - HSS断面の変数ID
%     HsrDp, Hsrtp - HSR断面の変数ID
%     brb1p, brb2p - BRB断面の変数ID
%     com - 共通データ構造体
%     secList - 断面リストオブジェクト
%     options - オプション構造体
%
%   出力引数:
%     secmgr - 初期化されたSectionManagerインスタンス

secmgr = SectionManager;
% dimensionはSectionNeighborSearcherで管理（後でcreateNeighborSearcher経由で設定）
% comp_effectは削除（member.girder.comp_effectから直接参照）
% materialの直接設定を削除（PropertyCalculator経由で取得）
% secmgr.material = table2struct(com.material,'ToScalar',true);
% idphaseを設定（createSectionStandardAccessor内で設定）
idphase = 999;
% secmgr.idphase = idphase;  % 削除（standardAccessorで管理）
secmgr.setSectionList(secList);
material = table2struct(com.material,'ToScalar',true);

% IdMapper初期化（全マッピング情報を提供）
idMapper = secmgr.createIdMapper(...
  com.section.property.id_section_list, ...  % 断面→断面リストID（1列版）
  com.section.property.type, ...             % 断面→断面タイプ
  com.section.property.idsrep, ...          % 断面→代表断面
  com.member.property.idsec, ...            % 部材→断面
  com.design.variable.type, ...             % 変数→変数タイプ
  com.section.representative.idsec, ...     % 代表断面→断面
  com.section.property.idvar, ...           % 断面→変数
  Hp, ...                                    % H変数ID配列（WFS）
  Bp, ...                                    % B変数ID配列（WFS）
  twp, ...                                   % tw変数ID配列（WFS）
  tfp, ...                                   % tf変数ID配列（WFS）
  Dp, ...                                    % D変数ID配列（HSS）
  tp, ...                                    % t変数ID配列（HSS）
  HsrDp, ...                                 % D変数ID配列（HSR）
  Hsrtp, ...                                 % t変数ID配列（HSR）
  brb1p, ...                                 % BRB V1変数ID配列
  brb2p, ...                                 % BRB V2変数ID配列
  com.member.property.type, ...             % 部材→部材タイプ
  com.design.variable.idsrep, ...           % 変数→代表断面
  secList.idsublist);                         % サブリストIDのcell配列（20番目）

% SectionStandardAccessor初期化
secmgr.createSectionStandardAccessor(...
  secList, ...
  idMapper, ...
  idphase);

% SectionPropertyCalculator初期化  
secmgr.createPropertyCalculator(...
  secList, ...
  material, ...
  com.section.property.idmaterial, ...  % デフォルト材料IDマッピング
  idMapper);

% SectionConstraintValidator初期化
secmgr.createConstraintValidator(...
  secList, ...
  secmgr.standardAccessor, ...
  idMapper, ...
  com.section.property.idvar, ...
  com.column_base_list);

% SectionNeighborSearcher初期化
secmgr.createNeighborSearcher(...
  com.Hgap.idvar, ...
  com.Hgap.idsec, ...
  options, ...
  idMapper, ...
  secmgr.standardAccessor, ...
  secmgr.constraintValidator, ...
  com.section.property.dimension);

secmgr.initValidSectionFlagCell
return
end