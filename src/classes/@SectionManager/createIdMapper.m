function idMapper = createIdMapper(secmgr, idSectionList, idsec2stype, ...
  idsec2srep, idvar2vtype, idsrep2sec, idsec2var, idH2var, idB2var, ...
  idtw2var, idtf2var, idD2var, idt2var, idHsrD2var, idHsrt2var, ...
  idBrb1_var, idBrb2_var, idvar2srep, idsublistCell, idlist2stype)
%createIdMapper - IdMapperインスタンスを作成・設定
%
%   idMapper = createIdMapper(secmgr, idSectionList, idsec2stype, ...
%     idsec2srep, idvar2vtype, idsrep2sec, idsec2var, ...
%     idH2var, idB2var, idtw2var, idtf2var, idD2var, idt2var, ...
%     idHsrD2var, idHsrt2var, idBrb1_var, idBrb2_var, ...
%     idvar2srep, idsublistCell, idlist2stype) は、固定した断面と変数の
%   対応からIdMapperを生成し、secmgrに設定したインスタンスを返す。
%
%   入力引数:
%     secmgr - SectionManager オブジェクト
%     idSectionList - 各断面の断面リストID [nsec×1]
%     idsec2stype - 断面→断面タイプマッピング
%     idsec2srep - 断面→代表断面マッピング
%     idvar2vtype - 変数→変数タイプマッピング
%     idsrep2sec - 代表断面→断面マッピング
%     idsec2var - 断面→変数マッピング
%     idH2var - H変数ID配列（WFS断面）
%     idB2var - B変数ID配列（WFS断面）
%     idtw2var - tw変数ID配列（WFS断面）
%     idtf2var - tf変数ID配列（WFS断面）
%     idD2var - D変数ID配列（HSS断面）
%     idt2var - t変数ID配列（HSS断面）
%     idHsrD2var - D変数ID配列（HSR断面）
%     idHsrt2var - t変数ID配列（HSR断面）
%     idBrb1_var - BRB V1変数ID配列
%     idBrb2_var - BRB V2変数ID配列
%     idvar2srep - 変数→代表断面
%     idsublistCell - サブリストIDのcell配列
%     idlist2stype - 断面リスト→鉄骨形状の種別 [nlist×1]
%
%   出力引数:
%     idMapper - 作成されたIdMapperインスタンス
%
%   例:
%   >> idMapper = secmgr.createIdMapper(idSectionList, idsec2stype, ...
%        idsec2srep, idvar2vtype, idsrep2sec, idsec2var, ...
%        idH2var, idB2var, idtw2var, idtf2var, idD2var, idt2var, ...
%        idHsrD2var, idHsrt2var, idBrb1_var, idBrb2_var, ...
%        idvar2srep, idsublistCell, idlist2stype);

% IdMapperインスタンスを作成（19引数）
idMapper = IdMapper(idSectionList, idsec2stype, idsec2srep, ...
  idvar2vtype, idsrep2sec, idsec2var, idH2var, idB2var, idtw2var, ...
  idtf2var, idD2var, idt2var, idHsrD2var, idHsrt2var, idBrb1_var, ...
  idBrb2_var, idvar2srep, idsublistCell, idlist2stype);

% SectionManagerのプロパティに設定
secmgr.idMapper_ = idMapper;

return
end
