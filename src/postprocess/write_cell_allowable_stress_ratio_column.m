function [asrchead, asrcbody] = ...
  write_cell_allowable_stress_ratio_column(com, result)
%write_cell_allowable_stress_ratio_column - S柱検定比一覧
%
%   [asrchead, asrcbody] =
%     write_cell_allowable_stress_ratio_column(com, result) は、
%   S柱の許容応力度検定比（M, Q, 組合せ）を符号ごとに集計したセル
%   配列を生成する。柱頭・柱脚に対応する j端・i端の最大値を出力する。
%   組合せ応力度比は角形鋼管・円形鋼管の柱だけ算定され、算定しない
%   柱は欄を空にする。
%
%   入力引数:
%     com    - 共通オブジェクト
%     result - 解析結果構造体 (cri/crj/csi/csj/ration 等)
%
%   出力引数:
%     asrchead - ヘッダ部セル配列 [2×9]
%     asrcbody - データ部セル配列 [nrow×9]

% 定数
nsc = com.nsecc;
nlc = com.nlc;
nstory = com.nstory;
nnc = com.num.nominal_column;

% 共通配列
column = com.member.column;
nominal_column = com.nominal.column;
secc = com.section.column;
idnmc2nm = nominal_column.idnominal;

% 柱許容応力度比（部材単位の各ケース最大値）
cri_all = result.cri;
crj_all = result.crj;
csi_all = result.csi;
csj_all = result.csj;
% 組合せ応力度比は ration の15列（柱脚=i端）と16列（柱頭=j端）
ration = abs(result.ration);

% --- ヘッダ ---
asrchead = {'階', '符号', 'M', '', '', 'Q', '', '組合せ', ''; ...
  '', '', '柱頭', '中央', '柱脚', '柱頭', '柱脚', '柱頭', '柱脚'};

% --- S柱検定比一覧 ---
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
    inm_ = idnmc2nm(inc);
    combj_ = max(ration(inm_, 16, :), [], 'all');
    combi_ = max(ration(inm_, 15, :), [], 'all');

    % 切り上げ
    cri_ = ceil(cri_*100)/100;
    crj_ = ceil(crj_*100)/100;
    csi_ = ceil(csi_*100)/100;
    csj_ = ceil(csj_*100)/100;
    combj_ = ceil(combj_*100)/100;
    combi_ = ceil(combi_*100)/100;

    % 書き出し（柱頭=j端, 柱脚=i端）
    asrcbody{irow,1} = secc.floor_name{isc};
    asrcbody{irow,2} = secc.full_name{isc};
    asrcbody{irow,3} = sprintf('%.2f', crj_);
    asrcbody{irow,4} = '';
    asrcbody{irow,5} = sprintf('%.2f', cri_);
    asrcbody{irow,6} = sprintf('%.2f', csj_);
    asrcbody{irow,7} = sprintf('%.2f', csi_);
    if ~isnan(combj_)
      asrcbody{irow,8} = sprintf('%.2f', combj_);
    end
    if ~isnan(combi_)
      asrcbody{irow,9} = sprintf('%.2f', combi_);
    end
  end
end

return
end
