function createSectionStandardAccessor(secmgr, secList, idMapper, idphase)
% createSectionStandardAccessor - 断面規格値Accessorを作成・設定
%
% この関数は、SectionStandardAccessorのインスタンスを作成し、
% SectionManagerのstandardAccessor_プロパティに設定する。
%
% Syntax
%   createSectionStandardAccessor(secmgr, secList, idMapper, idphase)
%
% Inputs
%   secmgr - SectionManager オブジェクト
%   secList - SectionListHandlerオブジェクト
%   idMapper - IdMapperオブジェクト
%   idphase - フェーズID
%
% Example
%   >> secmgr.createSectionStandardAccessor(secList, idMapper, idphase);

% SectionStandardAccessorインスタンスを直接作成
secmgr.standardAccessor_ = SectionStandardAccessor(secList, ...
  idMapper, idphase);

return
end