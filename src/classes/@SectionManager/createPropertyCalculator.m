function createPropertyCalculator(secmgr, secList, material, ...
    idsec2mat, idMapper)
% SectionPropertyCalculatorインスタンスを作成・初期化
%
% この関数は、SectionPropertyCalculatorのインスタンスを作成し、
% SectionManagerのpropertyCalculatorプロパティに設定する。
%
% Syntax
%   createPropertyCalculator(secmgr, secList, material, ...
%     idsec2mat, idMapper)
%
% Inputs
%   secmgr - SectionManager オブジェクト
%   secList - SectionListHandlerオブジェクト
%   material - 材料データオブジェクト
%   idsec2mat - デフォルト断面→材料IDマッピング
%   idMapper - IdMapperオブジェクト
%
% Example
%   >> secmgr.createPropertyCalculator(secList, material, ...
%        idsec2mat, idMapper);

% SectionPropertyCalculatorインスタンスを作成
secmgr.propertyCalculator_ = ...
  SectionPropertyCalculator(secList, material, idsec2mat, idMapper);

return
end