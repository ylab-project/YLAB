function idMapper = createIdMapper(secmgr, idSectionList, ...
  idsec2stype, idsec2srep, idme2sec, idvar2vtype, ...
  idsrep2sec, idsec2var, idH2var, idB2var, idtw2var, idtf2var, ...
  idD2var, idt2var, idHsrD2var, idHsrt2var, ...
  idBrb1_var, idBrb2_var, idme2mtype, idvar2srep, idsublistCell)
% createIdMapper - IdMapperインスタンスを作成・設定
%
% この関数は、IdMapperのインスタンスを作成し、
% SectionManagerのidMapper_プロパティに設定する。
% 作成したIdMapperインスタンスを返す。
%
% Syntax
%   idMapper = createIdMapper(secmgr, idSectionList, idsec2stype, ...
%     idsec2srep, idme2sec, idvar2vtype, idsrep2sec, idsec2var, ...
%     idH2var, idB2var, idtw2var, idtf2var, idD2var, idt2var, ...
%     idHsrD2var, idHsrt2var, idBrb1_var, idBrb2_var, idme2mtype, idvar2srep, idme2sublist)
%
% Inputs
%   secmgr - SectionManager オブジェクト
%   idSectionList - 断面→断面リストIDマッピング（1列版）
%   idsec2stype - 断面→断面タイプマッピング
%   idsec2srep - 断面→代表断面マッピング
%   idme2sec - 部材→断面マッピング
%   idvar2vtype - 変数→変数タイプマッピング
%   idsrep2sec - 代表断面→断面マッピング
%   idsec2var - 断面→変数マッピング
%   idH2var - H変数ID配列（WFS断面）
%   idB2var - B変数ID配列（WFS断面）
%   idtw2var - tw変数ID配列（WFS断面）
%   idtf2var - tf変数ID配列（WFS断面）
%   idD2var - D変数ID配列（HSS断面）
%   idt2var - t変数ID配列（HSS断面）
%   idHsrD2var - D変数ID配列（HSR断面）
%   idHsrt2var - t変数ID配列（HSR断面）
%   idBrb1_var - BRB V1変数ID配列
%   idBrb2_var - BRB V2変数ID配列
%   idme2mtype - 部材→部材タイプ
%   idvar2srep - 変数→代表断面
%   idsublistCell - サブリストIDのcell配列
%
% Output
%   idMapper - 作成されたIdMapperインスタンス
%
% Example
%   >> idMapper = secmgr.createIdMapper(idSectionList, idsec2stype, ...
%        idsec2srep, idme2sec, idvar2vtype, idsrep2sec, idsec2var, ...
%        idH2var, idB2var, idtw2var, idtf2var, idD2var, idt2var, ...
%        idHsrD2var, idHsrt2var, idBrb1_var, idBrb2_var, idme2mtype, idvar2srep, idsublistCell);

% IdMapperインスタンスを作成（20引数）
idMapper = IdMapper(idSectionList, idsec2stype, ...
  idsec2srep, idme2sec, idvar2vtype, idsrep2sec, idsec2var, ...
  idH2var, idB2var, idtw2var, idtf2var, idD2var, idt2var, ...
  idHsrD2var, idHsrt2var, idBrb1_var, idBrb2_var, idme2mtype, idvar2srep, idsublistCell);

% SectionManagerのプロパティに設定
secmgr.idMapper_ = idMapper;

return
end