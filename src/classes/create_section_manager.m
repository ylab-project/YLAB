function secmgr = create_section_manager(Hp, Bp, twp, tfp, Dp, tp, ...
  HsrDp, Hsrtp, brb1p, brb2p, com, secList, options)
%create_section_manager - 固定した断面・変数対応から断面管理を作る
%
%   secmgr = create_section_manager(Hp, Bp, twp, tfp, Dp, tp, ...
%   HsrDp, Hsrtp, brb1p, brb2p, com, secList, options)
%   は、断面・変数対応を各構成オブジェクトへ設定し、断面管理から
%   材料取得と制約評価を呼び出せる状態にする。
%
%   入力引数:
%     Hp, Bp, twp, tfp - H形鋼の各寸法の設計変数番号
%     Dp, tp - 角形鋼管の外径と板厚の設計変数番号
%     HsrDp, Hsrtp - 円形鋼管の外径と板厚の設計変数番号
%     brb1p, brb2p - 座屈拘束ブレースの設計変数番号
%     com - 入力断面と設計変数の対応を持つ共通データ
%     secList - 断面リストオブジェクト
%     options - 候補選択と制約条件
%
%   出力引数:
%     secmgr - 初期化した断面管理オブジェクト

secmgr = SectionManager;
% dimensionはSectionNeighborSearcherで管理（createNeighborSearcher経由）
% comp_effectは削除（member.girder.comp_effectから直接参照）
% materialの直接設定を削除（PropertyCalculator経由で取得）
% secmgr.material = table2struct(com.material,'ToScalar',true);
% idphaseを設定（createSectionStandardAccessor内で設定）
idphase = 999;
% secmgr.idphase = idphase;  % 削除（standardAccessorで管理）
secmgr.setSectionList(secList);
material = table2struct(com.material,'ToScalar',true);

% IdMapper初期化（全マッピング情報を提供）
idMapper = secmgr.createIdMapper(com.section.property.id_section_list, ...
  com.section.property.type, com.section.property.idsrep, ...
  com.design.variable.type, com.section.representative.idsec, ...
  com.section.property.idvar, Hp, Bp, twp, tfp, Dp, tp, HsrDp, Hsrtp, ...
  brb1p, brb2p, com.design.variable.idsrep, secList.idsublist, ...
  secList.section_type);                    % 断面リスト→鉄骨形状

% SectionStandardAccessor初期化
secmgr.createSectionStandardAccessor(secList, idMapper, idphase);

% SectionPropertyCalculator初期化
secmgr.createPropertyCalculator(secList, material, ...
  com.section.property.idmaterial);

% SectionConstraintValidator初期化
secmgr.createConstraintValidator(secList, secmgr.standardAccessor, ...
  idMapper, com.column_base_list);

% SectionNeighborSearcher初期化
secmgr.createNeighborSearcher(com.Hgap.idvar, com.Hgap.idsec, options, ...
  idMapper, secmgr.standardAccessor, secmgr.constraintValidator, ...
  com.section.property.dimension);

% 全構成要素の生成後に現在フェーズ用検索配列を初期化
secmgr.idphase = idphase;
return
end
