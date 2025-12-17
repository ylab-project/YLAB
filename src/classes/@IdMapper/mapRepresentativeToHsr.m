function idrephsr2hsr = mapRepresentativeToHsr(obj)
%mapRepresentativeToHsr 代表HSR断面→HSR断面マッピングを取得
%   idrephsr2hsr = mapRepresentativeToHsr(obj) は、代表HSR断面から
%   HSR断面へのマッピングを返します。
%   HSRは全断面が代表断面のため、1:nhsrの連番を返します。
%
%   出力引数:
%     idrephsr2hsr - 代表HSR断面→HSR断面マッピング [nrephsr×1]
%
%   例:
%     idrephsr2hsr = mapper.mapRepresentativeToHsr();

if isempty(obj.idrephsr2hsr_)
  % HSRは全断面が代表断面
  isHsr = (obj.idsec2stype_ == PRM.HSR);
  idhsr2sec = find(isHsr);
  nhsr = length(idhsr2sec);
  obj.idrephsr2hsr_ = (1:nhsr)';
end

idrephsr2hsr = obj.idrephsr2hsr_;

return
end