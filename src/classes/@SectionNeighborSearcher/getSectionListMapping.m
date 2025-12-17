function idsec2slist = getSectionListMapping(secdim)
% 断面寸法データから断面リストID/断面IDマッピングを取得
%
% この関数は、断面寸法データ（secdim）の構造化された配列から、
% 断面リストIDと断面IDのペアを抽出する。secdim配列の内部構造を
% カプセル化し、将来的な変更に対する保守性を向上させる。
%
% Syntax
%   idsec2slist = SectionManager.getSectionListMapping(secdim)
%
% Inputs
%   secdim - 断面寸法データ配列 [nsec × 7以上]
%            第1-5列: 断面寸法（断面タイプにより異なる）
%            第6列: 断面リストID (idslist)
%            第7列: 断面ID (idsection)
%
% Outputs
%   idsec2slist - 断面リストID/断面IDペア配列 [nsec × 2]
%                 第1列: 断面リストID
%                 第2列: 断面ID
%
% Example
%   >> secdim = [100, 100, 6, 9, 0, 1, 3; 200, 200, 8, 12, 0, 1, 5];
%   >> idsec2slist = SectionManager.getSectionListMapping(secdim);
%   >> disp(idsec2slist)
%        1     3
%        1     5
%
% Note
%   この関数により、secdim配列の内部構造（列インデックス）への
%   直接的な依存を排除し、コードの保守性を向上させる。

% 入力チェック
if size(secdim, 2) < 7
  error('SectionManager:getSectionListMapping:InvalidInput', ...
        'secdim は少なくとも7列必要です（現在: %d列）', size(secdim, 2));
end

% 断面リストID/断面IDマッピングの抽出
% 第6列: 断面リストID、第7列: 断面ID
idsec2slist = secdim(:, 6:7);

end