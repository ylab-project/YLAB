function createSectionStandardAccessor(secmgr, secList, idMapper, idphase)
% createSectionStandardAccessor - SectionStandardAccessorインスタンスを作成・設定
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
secmgr.standardAccessor_ = SectionStandardAccessor(secList, idMapper);

% idPhaseを設定
secmgr.standardAccessor_.idPhase = idphase;

return
end