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
%     head - ヘッダ部セル配列 [2×13]
%     body - データ部セル配列 [nrow×14]（最終列は CONT_MARKER）

NCOL = 13;

% 定数・共通配列
nfl = com.nfl;
nblx = com.nblx;
nbly = com.nbly;
nblz = com.nblz;
column = com.member.column;
nominal_column = com.nominal.column;
nnc = com.num.nominal_column;
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

[~, ~, idsec_col, idmat_col] = calc_steel_cost_column( ...
  column, stype, idsecc2sec, secdim, lm_weight, Am, secmgr);

[jt, jb] = calc_column_joint_length(column, com.member.girder, ...
  node, stype, idsecg2sec, secdim);

% 下階柱の有無（仕口部(柱脚)出力判定用）
has_column_below = ismember(column.idnode1, column.idnode2);

% nominal_column の最下階メンバーから位置情報を取得
% （通し柱は chain 最下階に集約。各層独立柱は chain 長さ 1）
ic_bottom_all = nominal_column.idmec(:, 1);
nc_idfloor = column.idfloor(ic_bottom_all);
nc_idx_b = column.idx(ic_bottom_all, 1);
nc_idy_b = column.idy(ic_bottom_all, 1);
nc_idz_b = column.idz(ic_bottom_all, 1);

% (ifl, iy, ix, iz) 位置 → nominal_column インデックスのバケット
% （5重ループ内の線形検索を回避し O(nnc + nfl*nbly*nblx*nblz) に削減）
key_all = sub2ind([nfl, nbly, nblx, nblz], nc_idfloor, ...
  nc_idy_b, nc_idx_b, nc_idz_b);
buckets = accumarray(key_all, (1:nnc)', [nfl*nbly*nblx*nblz, 1], ...
  @(v){v}, {[]});

% ヘッダ
head = cell(2, NCOL);
head(1, :) = {'階', 'X軸', 'Y軸', '符号', '部位', '', '種類', ...
  '鉄骨断面', 'A', '材料', '単位重量', 'L', 'W'''};
head(2, 8:NCOL) = {'mm', 'cm2', 'ﾌﾗﾝｼﾞ/ｳｪﾌﾞ', 'kg/m', 'm', 't'};

% ボディ（柱+仕口部で最大3行/nominal_column、最終列は marker）
body = cell(nnc * 3, NCOL + 1);
irow = 0;

for i = 1:nfl
  ifl = nfl - i + 1;
  for iy = 1:nbly
    for ix = 1:nblx
      for iz = 1:nblz
        key = sub2ind([nfl, nbly, nblx, nblz], ifl, iy, ix, iz);
        inc_list = buckets{key};
        for inc = inc_list(:).'
          n_chain = nominal_column.idsub(inc, 2);
          chain_ics = nominal_column.idmec(inc, 1:n_chain);
          ic_bottom = chain_ics(1);
          ic_top = chain_ics(end);
          if idsec_col(ic_bottom) == 0
            continue
          end

          is = idsec_col(ic_bottom);
          stype_ = stype(is);
          idm_bottom = column.idme(ic_bottom);
          idsc = column.idsecc(ic_bottom);
          idslist = secdim(is, 6);
          idsection = secdim(is, 7);
          A_ = Am(idm_bottom) * 1e-2;
          uw = Am(idm_bottom) * PRM.RHOS * 1e-3;
          sym = secmgr.secList.list{idslist}.symbol{idsection};
          dim_str = format_steel_cost_dim(stype_, secdim(is, :), sym);
          type_name = secmgr.secList.list{idslist}.type{idsection};
          mat_name = material.name{idmat_col(ic_bottom)};

          % 仕口部(柱脚)の出力判定: chain 最下階の柱脚
          % 下階に柱がある場合、柱脚仕口は下階柱の柱頭で計上される
          output_jb = jb(ic_bottom) > 0 && ~has_column_below(ic_bottom);

          % 柱本体: chain 全メンバー長の合計 − 端部仕口部
          % 中間階の仕口部は本体長に含める（SS7 互換）
          idm_chain = column.idme(chain_ics);
          L_chain_total = sum(lm_weight(idm_chain));
          L_body = L_chain_total - jt(ic_top);
          if output_jb
            L_body = L_body - jb(ic_bottom);
          end
          W_body = Am(idm_bottom) * L_body * PRM.RHOS * 1e-9;

          % 1 nominal_column = 1 論理ブロック（柱本体 + 仕口部）
          block_start = irow + 1;
          irow = write_body_row(irow, '柱', '', L_body, W_body);
          body{block_start, 1} = com.floor.name{ifl};
          body(block_start, 2:3) = column.coord_name(ic_bottom, 1:2);
          body{block_start, 4} = make_section_symbol(secc, idsc);

          % 仕口部(柱頭): chain 最上階柱頭に梁がとりつくとき
          if jt(ic_top) > 0
            W_jt = Am(idm_bottom) * jt(ic_top) * PRM.RHOS * 1e-9;
            irow = write_body_row(irow, '仕口部', '柱頭', ...
              jt(ic_top), W_jt);
          end

          % 仕口部(柱脚): chain 最下階に下階柱がないとき
          if output_jb
            W_jb = Am(idm_bottom) * jb(ic_bottom) * PRM.RHOS * 1e-9;
            irow = write_body_row(irow, '仕口部', '柱脚', ...
              jb(ic_bottom), W_jb);
          end
          % ブロック内の中間行に CONT_MARKER を付与
          body(block_start:irow-1, end) = {PRM.CONT_MARKER};
        end
      end
    end
  end
end

body = body(1:irow, :);

return

  function irow_out = write_body_row(irow_in, part_label, sub_label, ...
    L_mm, W_t)
  %write_body_row - 柱/仕口部の 1 行を書き込む（鉄骨数量表 body）
  %
  %   irow_out = write_body_row(irow_in, part_label, sub_label,
  %     L_mm, W_t) は、鉄骨数量（柱）の body 配列に部位行を 1 行
  %   追加し、書き込み後の行番号を返す。part_label/sub_label/
  %   L_mm/W_t 以外は呼び出し元スコープの type_name/dim_str/A_/
  %   mat_name/uw を共有する。
  %
  %   入力引数:
  %     irow_in    - 書き込み前の行番号（現在の最終行）
  %     part_label - 部位名（'柱' / '仕口部'）
  %     sub_label  - 補足ラベル（'柱頭' / '柱脚' / 空）
  %     L_mm       - 長さ [mm]
  %     W_t        - 重量 [t]
  %
  %   出力引数:
  %     irow_out - 書き込み後の行番号
    irow_out = irow_in + 1;
    body{irow_out, 5} = part_label;
    body{irow_out, 6} = sub_label;
    body{irow_out, 7} = type_name;
    body{irow_out, 8} = dim_str;
    body{irow_out, 9} = sprintf('%.2f', A_);
    body{irow_out, 10} = mat_name;
    body{irow_out, 11} = sprintf('%.2f', uw);
    body{irow_out, 12} = sprintf('%.3f', L_mm * 1e-3);
    body{irow_out, 13} = sprintf('%.3f', W_t);
    return
  end
end
