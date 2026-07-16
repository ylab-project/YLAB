function createConstraintValidator(secmgr, secList, ...
  standardAccessor, idMapper, columnBaseList)
% SectionConstraintValidatorインスタンスを作成・初期化
%
% この関数は、SectionConstraintValidatorのインスタンスを作成し、
% SectionManagerのconstraintValidatorプロパティに設定する。
% IdMapperとSectionStandardAccessorは事前に作成されている必要がある。
%
% Syntax
%   createConstraintValidator(secmgr, secList, standardAccessor, ...
%     idMapper, columnBaseList)
%
% Inputs
%   secmgr - SectionManager オブジェクト
%   secList - SectionListHandlerオブジェクト
%   standardAccessor - SectionStandardAccessorオブジェクト
%   idMapper - IdMapperオブジェクト
%   columnBaseList - 柱脚リスト
%
% Example
%   >> secmgr.createConstraintValidator(secList, standardAccessor, ...
%        idMapper, columnBaseList);

% isVarofSlistをIdMapperプロパティから取得
isVarofSlist = idMapper.isVarofSlist;

% SectionConstraintValidatorインスタンスを作成
secmgr.constraintValidator_ = SectionConstraintValidator(secList, ...
  standardAccessor, isVarofSlist, idMapper, columnBaseList);

return
end
