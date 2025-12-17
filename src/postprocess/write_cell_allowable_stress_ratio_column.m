function [asrchead, asrcbody] = ...
  write_cell_allowable_stress_ratio_column(com, result)

% 定数
nmc = com.nmec;
nsc = com.nsecc;
nlc = com.nlc;
nstory = com.nstory;
nnc = com.num.nominal_column;

% 共通配列
column = com.member.column;
nominal_column = com.nominal.column;
secc = com.section.column;

% 梁許容応力度比（部材単位の各ケース最大値）
cri_all = result.cri;
crj_all = result.crj;
csi_all = result.csi;
csj_all = result.csj;

% --- ヘッダ ---
asrchead = {'階', '符号', 'M', '', 'Q'	, ''; ...
  '', '', '柱頭', '柱脚', '柱頭', '柱脚'};

% --- S柱断面算定表 ---
ncol = size(asrchead,2);
asrcbody = cell(0,ncol);
if nsc==0 || isempty(cri_all) || isempty(crj_all) ...
    || isempty(csi_all) || isempty(csj_all)
  return
end
cri = reshape(cri_all,[],nlc)+1;
crj = reshape(crj_all,[],nlc)+1;
csi = reshape(csi_all,[],nlc)+1;
csj = reshape(csj_all,[],nlc)+1;
crimax = max(cri,[],[2 3]);
crjmax = max(crj,[],[2 3]);
csimax = max(csi,[],[2 3]);
csjmax = max(csj,[],[2 3]);
asrcbody = cell(nsc,ncol);
idnm2sc = column.idsecc(nominal_column.idmec(:,1));
iccc = 1:nnc;
irow = 0;
for i = 1:nstory
  ist = nstory-i+1;
  for isc = 1:nsc
    if secc.idstory(isc)~=ist
      continue
    end
    inc = iccc(idnm2sc==isc);

    % 除外
    if ~nominal_column.is_allowable_stress(inc)
      continue
    end

    % 検定値
    irow = irow+1;
    cri_ = max(crimax(inc));
    crj_ = max(crjmax(inc));
    csi_ = max(csimax(inc));
    csj_ = max(csjmax(inc));

    % 切り上げ
    cri_ = ceil(cri_*100)/100;
    crj_ = ceil(crj_*100)/100;
    csi_ = ceil(csi_*100)/100;
    csj_ = ceil(csj_*100)/100;

    % 書き出し
    asrcbody{irow,1} = secc.floor_name{isc};
    asrcbody{irow,2} = sprintf('%s', ...
      [secc.subindex{isc} secc.name{isc}]);
    asrcbody{irow,3} = sprintf('%.2f', crj_);
    asrcbody{irow,4} = sprintf('%.2f', cri_);
    asrcbody{irow,5} = sprintf('%.2f', csj_);
    asrcbody{irow,6} = sprintf('%.2f', csi_);
  end
end
return
end
