function initializeDerivedMappings(obj)
%initializeDerivedMappings 代表断面の派生マッピングを事前生成
%   コンストラクタで保存した正本配列から、候補検索で繰り返し
%   参照する代表断面の派生マッピングを生成します。

obj.idsrep2var_ = obj.idsec2var_(obj.idsrep2sec_, :);
obj.idsrep2stype_ = obj.idsec2stype_(obj.idsrep2sec_);
obj.idsrep2shape_ = obj.idsec2shape_(obj.idsrep2sec_);

isWfs = obj.idsrep2shape_ == PRM.WFS;
isHss = obj.idsrep2shape_ == PRM.HSS;
isBrb = obj.idsrep2shape_ == PRM.BRB;
isHsr = obj.idsrep2shape_ == PRM.HSR;

obj.idrepwfs2var_ = obj.idsrep2var_(isWfs, :);
obj.idrephss2var_ = obj.idsrep2var_(isHss, :);
obj.idrepbrbs2var_ = obj.idsrep2var_(isBrb, :);
obj.idrephsr2var_ = obj.idsrep2var_(isHsr, :);
if size(obj.idrephsr2var_, 2) > 2
  obj.idrephsr2var_ = obj.idrephsr2var_(:, 1:2);
end

return
end