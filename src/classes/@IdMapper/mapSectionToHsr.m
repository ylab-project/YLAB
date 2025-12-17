function idsec2hsr = mapSectionToHsr(obj)
%mapSectionToHsr 全断面のHSR断面IDマッピングを取得
%   idsec2hsr = mapSectionToHsr(obj) は、全断面に対するHSR断面ID
%   マッピングを返します。HSR断面でない場合は0を返します。
%
%   出力引数:
%     idsec2hsr - HSR断面IDマッピング [nsec×1]
%                 HSR断面でない場合は0
%
%   例:
%     idsec2hsr = mapper.mapSectionToHsr();

% HSR断面のインデックスを取得
isHsr = (obj.idsec2stype_ == PRM.HSR);

% マッピング配列を初期化
idsec2hsr = zeros(obj.nsec, 1);

% HSR断面に連番を割り当て
idhsr = find(isHsr);
for i = 1:length(idhsr)
  idsec2hsr(idhsr(i)) = i;
end

return
end