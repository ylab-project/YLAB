function [dcflhead, dcflbody] = ...
  write_cell_design_column_force_list(com, result, icase)
%write_cell_design_column_force_list - 柱設計応力表セル配列を生成
%
%   [dcflhead, dcflbody] =
%     write_cell_design_column_force_list(com, result, icase) は、
%   名目柱ごとの設計応力（軸力N・曲げMx/My・せん断Qx/Qy）一覧を
%   生成する。
%
%   入力引数:
%     com    - 共通オブジェクト
%     result - 解析結果構造体 (lm_nominal, dfn 等)
%     icase  - ケース指定 (1: 長期L のみ、2以上: 地震L±E)
%
%   出力引数:
%     dcflhead - ヘッダ部セル配列 [3×17]
%     dcflbody - データ部セル配列 [nrow×18]（最終列は CONT_MARKER）

% 定数
nc = com.nmec;
nnc = com.num.nominal_column;
nblx = com.nblx;
nbly = com.nbly;
nblz = com.nblz;
nstory = com.nstory;

% 共通配列
nominal_column = com.nominal.column;
column = com.member.column;
secc = com.section.column;
lm_nominal = result.lm_nominal;
dfn_all = result.dfn;

% ID変換
idnm2x = column.idx(nominal_column.idmec(:,1),1);
idnm2y = column.idy(nominal_column.idmec(:,1),1);
idnm2z = column.idz(nominal_column.idmec(:,1),1);
idnm2story = column.idstory(nominal_column.idmec(:,1),1);
idnm2mc = nominal_column.idmec;
idnmc2nm = nominal_column.idnominal;
idmc2m = column.idme;

% 場合分け
if icase == 1
  ilcset = 1;
  label = {'L'};
else
  ilcset = [PRM.EXP PRM.EXN PRM.EYP PRM.EYN];
  label = {'L+Ex', 'L-Ex', 'L+Ey', 'L-Ey'};
end
nlc = length(ilcset);
maxlc = max(ilcset);

% --- 柱設計応力表 ---
dcflhead = {'層', 'X軸', 'Y軸', '符号', 'ケース', '部材長', '軸力', ...
  '曲げx', '', '', 'せん断x', '', '曲げy', '', '', 'せん断y', '';
  '', '', '', '', '', '', '', '柱頭', '中央', '柱脚', '柱頭', ...
  '柱脚', '柱頭', '中央', '柱脚', '柱頭', '柱脚';
  '', '', '', '', '', 'mm', 'kN', 'kNm', 'kNm', 'kNm', 'kN', ...
  'kN', 'kNm', 'kNm', 'kNm', 'kN', 'kN'};
ncol = size(dcflhead,2);
dcflbody = cell(0,ncol);
if nnc==0 || isempty(lm_nominal)
  return
end
if isempty(dfn_all) || size(dfn_all,3)<maxlc
  return
end
dfn = dfn_all(:,:,ilcset);
% rows は head=17 列 + marker 列で 18 列
rows = cell(nc*nlc,ncol+1);
iccc = 1:nnc;
irow = 0;
for i = 1:nstory
  ist = nstory-i+1;
  for iy = 1:nbly
    for ix = 1:nblx
      for iz = 1:nblz
        inc = iccc(idnm2story==ist & idnm2x(:,1)==ix ...
          & idnm2y(:,1)==iy & idnm2z(:,1)==iz);
        if isempty(inc)
          continue
        end
        inm = idnmc2nm(inc);

        % --- 箇所ごとの部材番号 ---
        idsub = nominal_column.idsub(inc,:);
        ic1 = idnm2mc(inc,idsub(1)); im1 = idmc2m(ic1);

        for ilc=1:nlc
          irow = irow+1;
          if ilc==1
            rows{irow,1} = column.floor_name{ic1};
            rows{irow,2} = column.coord_name{ic1,1};
            rows{irow,3} = column.coord_name{ic1,2};
            isc = column.idsecc(ic1);
            rows{irow,4} = secc.full_name{isc};
            rows{irow,6} = sprintf('%.0f', lm_nominal(im1));
          end
          rows{irow,5} = label{ilc};
          rows{irow,7} = sprintf('%.1f', -dfn(inm,1,ilc)*1.d-3);
          rows{irow,8} = sprintf('%.1f', dfn(inm,11,ilc)*1.d-6);
          rows{irow,9} = '';
          rows{irow,10} = sprintf('%.1f', -dfn(inm,5,ilc)*1.d-6);
          rows{irow,11} = sprintf('%.1f', dfn(inm,9,ilc)*1.d-3);
          rows{irow,12} = sprintf('%.1f', dfn(inm,3,ilc)*1.d-3);
          rows{irow,13} = sprintf('%.1f', dfn(inm,12,ilc)*1.d-6);
          rows{irow,14} = '';
          rows{irow,15} = sprintf('%.1f', -dfn(inm,6,ilc)*1.d-6);
          rows{irow,16} = sprintf('%.1f', -dfn(inm,8,ilc)*1.d-3);
          rows{irow,17} = sprintf('%.1f', -dfn(inm,2,ilc)*1.d-3);
          % 1 名目柱 = nlc 物理行/論理ブロック。最終以外に CONT_MARKER
          if ilc < nlc
            rows{irow,end} = PRM.CONT_MARKER;
          end
        end
      end
    end
  end
end

if irow==0
  dcflbody = cell(0,ncol);
else
  dcflbody = rows(1:irow,:);
end
return
end
