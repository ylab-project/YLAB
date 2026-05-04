function [head, body] = write_cell_steel_cost_column(com, result)
%write_cell_steel_cost_column - 鉄骨数量（柱）セル配列を生成
%
%   [head, body] = write_cell_steel_cost_column(
%     com, result) は、SS7積算「部位ごと数量 — 鉄骨」
%   の柱パートと同様式のセル配列を生成する。
%
%   入力引数:
%     com    - 共通オブジェクト
%     result - 解析結果構造体
%
%   出力引数:
%     head - ヘッダ部セル配列
%     body - データ部セル配列

NCOL = 13;

% 定数・共通配列
nfl = com.nfl;
nblx = com.nblx;
nbly = com.nbly;
nblz = com.nblz;
nc = com.nmec;
column = com.member.column;
secc = com.section.column;
stype = com.section.property.type;
idsecc2sec = com.section.column.idsec;
idsecg2sec = com.section.girder.idsec;
secdim = result.secdim;
lm_weight = result.lm_weight;
Am = result.msprop.A;
secmgr = com.secmgr;
material = com.material;
node = com.node;

% 鉄骨積算データの算出
[~, ~, idsec_col, idmat_col] = calc_steel_cost_column( ...
  column, stype, idsecc2sec, secdim, lm_weight, Am, secmgr);

% 仕口部長さの算出
[jt, jb] = calc_column_joint_length(column, com.member.girder, ...
  node, stype, idsecg2sec, secdim);

% 下階柱の有無（仕口部(柱脚)出力判定用）
has_column_below = ismember(column.idnode1, column.idnode2);

% ヘッダ
head = cell(2, NCOL);
head(1, :) = {'階', 'X軸', 'Y軸', '符号', '部位', '', '種類', ...
  '鉄骨断面', 'A', '材料', '単位重量', 'L', 'W'''};
head(2, 8:NCOL) = {'mm', 'cm2', 'ﾌﾗﾝｼﾞ/ｳｪﾌﾞ', 'kg/m', 'm', 't'};

% ボディ（柱+仕口部で最大3行/柱）
body = cell(nc * 3, NCOL);
irow = 0;
iccc = 1:nc;

for i = 1:nfl
  ifl = nfl - i + 1;
  for iy = 1:nbly
    for ix = 1:nblx
      for iz = 1:nblz
        ic = iccc(column.idfloor == ifl ...
          & column.idx(:,1) == ix & column.idy(:,1) == iy ...
          & column.idz(:,1) == iz);
        if isempty(ic)
          continue
        end
        if idsec_col(ic) == 0
          continue
        end

        is = idsec_col(ic);
        stype_ = stype(is);
        idm = column.idme(ic);
        idsc = column.idsecc(ic);
        idslist = secdim(is, 6);
        idsection = secdim(is, 7);
        A_ = Am(idm) * 1e-2;
        uw = Am(idm) * PRM.RHOS * 1e-3;
        sym = secmgr.secList.list{idslist}.symbol{idsection};
        dim_str = format_steel_cost_dim(stype_, secdim(is, :), sym);
        type_name = secmgr.secList.list{idslist}.type{idsection};
        mat_name = material.name{idmat_col(ic)};

        % 仕口部(柱脚)の出力判定
        % 下階に柱がある場合、柱脚仕口は下階柱の
        % 仕口部(柱頭)で計上される
        output_jb = jb(ic) > 0 && ~has_column_below(ic);

        % 柱本体: lm_weight - 仕口部
        L_body = lm_weight(idm) - jt(ic);
        if output_jb
          L_body = L_body - jb(ic);
        end
        W_body = Am(idm) * L_body * PRM.RHOS * 1e-9;

        irow = irow + 1;
        body{irow, 1} = com.floor.name{ifl};
        body(irow, 2:3) = column.coord_name(ic, 1:2);
        body{irow, 4} = make_section_symbol(secc, idsc);
        body{irow, 5} = '柱';
        body{irow, 7} = type_name;
        body{irow, 8} = dim_str;
        body{irow, 9} = sprintf('%.2f', A_);
        body{irow, 10} = mat_name;
        body{irow, 11} = sprintf('%.2f', uw);
        body{irow, 12} = sprintf('%.3f', L_body * 1e-3);
        body{irow, 13} = sprintf('%.3f', W_body);

        % 仕口部(柱頭): 常に出力
        if jt(ic) > 0
          W_jt = Am(idm) * jt(ic) * PRM.RHOS * 1e-9;
          irow = irow + 1;
          body{irow, 5} = '仕口部';
          body{irow, 6} = '柱頭';
          body{irow, 7} = type_name;
          body{irow, 8} = dim_str;
          body{irow, 9} = sprintf('%.2f', A_);
          body{irow, 10} = mat_name;
          body{irow, 11} = sprintf('%.2f', uw);
          body{irow, 12} = sprintf('%.3f', jt(ic) * 1e-3);
          body{irow, 13} = sprintf('%.3f', W_jt);
        end

        % 仕口部(柱脚): 下階に柱がないとき
        if output_jb
          W_jb = Am(idm) * jb(ic) * PRM.RHOS * 1e-9;
          irow = irow + 1;
          body{irow, 5} = '仕口部';
          body{irow, 6} = '柱脚';
          body{irow, 7} = type_name;
          body{irow, 8} = dim_str;
          body{irow, 9} = sprintf('%.2f', A_);
          body{irow, 10} = mat_name;
          body{irow, 11} = sprintf('%.2f', uw);
          body{irow, 12} = sprintf('%.3f', jb(ic) * 1e-3);
          body{irow, 13} = sprintf('%.3f', W_jb);
        end
      end
    end
  end
end

body = body(1:irow, :);

return
end
