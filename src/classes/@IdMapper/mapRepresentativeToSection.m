function idsrep2sec = mapRepresentativeToSection(obj)
%mapRepresentativeToSection 代表断面から断面への変換
%   idsrep2sec = mapRepresentativeToSection(obj) は、
%   すべての代表断面IDから対応する断面IDへのマッピングを返します。
%
%   出力引数:
%     idsrep2sec - 代表断面→断面 [nsrep×1]
%
%   参考:
%     mapRepresentativeToVariable

if ~isempty(obj.idsrep2sec_)
  % 7引数コンストラクタで提供されている場合
  idsrep2sec = obj.idsrep2sec_;
else
  % 5引数コンストラクタの場合は計算
  [~, idsrep2sec] = unique(obj.idsec2srep_);
end

return
end