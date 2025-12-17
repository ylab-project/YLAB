function createConstraintValidator(secmgr, secList, ...
  standardAccessor, idMapper, idsec2var, columnBaseList)
% SectionConstraintValidatorインスタンスを作成・初期化
%
% この関数は、SectionConstraintValidatorのインスタンスを作成し、
% SectionManagerのconstraintValidatorプロパティに設定する。
% IdMapperとSectionStandardAccessorは事前に作成されている必要がある。
%
% Syntax
%   createConstraintValidator(secmgr, idsec2var, columnBaseList)
%
% Inputs
%   secmgr - SectionManager オブジェクト
%   secList - SectionListHandlerオブジェクト
%   standardAccessor - SectionStandardAccessorオブジェクト
%   idMapper - IdMapperオブジェクト
%   idsec2var - 断面→変数マッピング
%   columnBaseList - 柱脚リスト
%
% Example
%   >> secmgr.createConstraintValidator(secList, standardAccessor, ...
%        idMapper, idsec2var, columnBaseList);

% isVarofSlistをIdMapperプロパティから取得
isVarofSlist = idMapper.isVarofSlist;

% SectionConstraintValidatorインスタンスを作成
secmgr.constraintValidator_ = ...
  SectionConstraintValidator(secList, ...
  standardAccessor, ...
  isVarofSlist, ...
  idMapper, ...
  columnBaseList);

% 有効断面フラグセルを初期化
secmgr.constraintValidator_.initValidSectionFlagCell();

return
end
