function [stvals, stnum] = deprecated_getStandardValues(secmgr)
%deprecated_getStandardValues 全断面リストの規格値セットを取得（非推奨）
%   [stvals, stnum] = deprecated_getStandardValues(secmgr) は、
%   GA最適化で使用する全断面の規格値を統合して返します。
%
%   非推奨: このメソッドは非推奨です。
%   代わりにstandardAccessor.getStandardValues()を使用してください。
%
%   出力引数:
%     stvals - 規格値配列 [nxvar×max(stnum)] NaN埋め
%     stnum - 各変数の規格値数 [nxvar×1]
%
%   参考:
%     SectionStandardAccessor.getStandardValues

% 非推奨警告
warning('SectionManager:DeprecatedMethod', ...
  'deprecated_getStandardValues は非推奨です。standardAccessor.getStandardValues() を使用してください。');

% 元の実装を保持（新旧比較テストのため）
nxvar = secmgr.nxvar;

% 規格値の取り出し
stvals = [];
for id=1:secmgr.nlist
  stvals_ = getStandardValues_(secmgr, id);
  if isempty(stvals)
    stvals = stvals_;
  else
    for i=1:nxvar
      stvals{i} = unique([stvals{i} stvals_{i}]);
    end
  end
end

% 規格値数
stnum = zeros(nxvar,1);
for i=1:nxvar
  stnum(i) = length(stvals{i});
end

% 行列に変換
m = max(stnum);
tmp = stvals;
stvals = nan(nxvar,m);
for i=1:nxvar
  stvals(i,1:stnum(i)) = tmp{i};
end

return
end

%--------------------------------------------------------------------------
function stval = getStandardValues_(secmgr, idslist)
stval = cell(secmgr.nxvar,1);
vtypeset = [...
  PRM.WFS_H PRM.WFS_B PRM.WFS_TW PRM.WFS_TF ...
  PRM.HSS_D PRM.HSS_T];
iddd = 1:secmgr.nxvar;
for vtype=vtypeset
  istarget = secmgr.isVarofSlist(:,idslist)&secmgr.idvar2vtype==vtype;
  if all(~istarget)
    continue
  end
  switch vtype
    case PRM.WFS_H
      stval_ = secmgr.getHnominal(idslist);
    case PRM.WFS_B
      stval_ = secmgr.getBnominal(idslist);
    case PRM.WFS_TW
      stval_ = secmgr.getTwst(idslist);
    case PRM.WFS_TF
      stval_ = secmgr.getTfst(idslist);
    case PRM.HSS_D
      stval_ = secmgr.getDst(idslist);
    case PRM.HSS_T
      stval_ = secmgr.getTst(idslist);
  end
  if ~isempty(stval_)
    idtarget = iddd(istarget);
    for i=idtarget
      stval{i} = unique([stval{i} stval_]);
    end
  end
end
return
end