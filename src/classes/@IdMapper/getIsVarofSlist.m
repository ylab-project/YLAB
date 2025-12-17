function isVarofSlist = getIsVarofSlist(obj)
%getIsVarofSlist 変数-断面リストマッピングを計算
%   isVarofSlist = getIsVarofSlist(obj) は、
%   各変数がどの断面リストに属するかを示す論理配列を返します。
%
%   出力引数:
%     isVarofSlist - 変数-断面リストマッピング [nxvar×nlist] 論理配列
%                    isVarofSlist(i,j)=true: 変数iがリストjに属する
%
%   例:
%     mapping = idMapper.getIsVarofSlist();
%
%   参考:
%     idSectionList, idsec2var

% 初期化
nxvar = obj.nxvar;
nlist = max(obj.idSectionList_);  % 断面リスト数を自動取得
isVarofSlist = false(nxvar, nlist);

% 各断面リストについて処理
for il = 1:nlist
  % リストilに属する断面を特定
  sections_in_list = (obj.idSectionList_ == il);
  
  % それらの断面が使用する変数IDを取得
  iddd = obj.idsec2var_(sections_in_list, :);
  iddd = iddd(:);
  iddd(iddd == 0) = [];  % 0（未使用）を除外
  
  % 該当変数をマーク
  if ~isempty(iddd)
    isVarofSlist(iddd, il) = true;
  end
end

return
end