function [head, body] = write_cell_steel_cost_girder(com, result)
%write_cell_steel_cost_girder - 鉄骨数量（大梁）セル配列を生成
%
%   [head, body] = write_cell_steel_cost_girder(
%     com, result) は、SS7積算「部位ごと数量 — 鉄骨」
%   の大梁パートと同様式のセル配列を生成する。
%   通し梁（isthrough）は1行にまとめて出力する。
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
ng = com.nmeg;
nstory = com.nstory;
girder = com.member.girder;
secg = com.section.girder;
stype = com.section.property.type;
idsecg2sec = com.section.girder.idsec;
secdim = result.secdim;
lm_weight = result.lm_weight;
Am = result.msprop.A;
secmgr = com.secmgr;
material = com.material;
nmg = com.nominal.girder;
nng = size(nmg, 1);

% 鉄骨積算データの算出
[~, ~, idsec_gir, idmat_gir] = calc_steel_cost_girder( ...
  girder, stype, idsecg2sec, secdim, ...
  lm_weight, Am, secmgr);

% ヘッダ
head = cell(2, NCOL);
head(1, :) = {'層', 'ﾌﾚｰﾑ', '軸-軸', '', ...
  '符号', '部位', '種類', '鉄骨断面', ...
  'A', '材料', '単位重量', 'L', 'W'''};
head(2, 8:NCOL) = {'mm', 'cm2', 'ﾌﾗﾝｼﾞ/ｳｪﾌﾞ', 'kg/m', 'm', 't'};

% ボディ（nominal_girder単位でループ）
body = cell(ng, NCOL);
irow = 0;

for i = 1:nstory
  ist = nstory - i + 1;
  for ing = 1:nng
    if nmg.idstory(ing) ~= ist
      continue
    end
    idmeg_ = nmg.idmeg(ing, :);
    ncol_ = nnz(idmeg_);
    ids = idmeg_(1:ncol_);

    % 通し梁: 1行にまとめて出力
    if nmg.isthrough(ing) && ncol_ > 1
      ig1 = ids(1);
      if idsec_gir(ig1) == 0
        continue
      end
      is = idsec_gir(ig1);
      stype_ = stype(is);
      idsg = girder.idsecg(ig1);
      idm1 = girder.idme(ig1);
      idslist = secdim(is, 6);
      idsection = secdim(is, 7);
      A_ = Am(idm1) * 1e-2;
      uw = Am(idm1) * PRM.RHOS * 1e-3;

      % L, W' を全要素で合算
      L_ = 0; W_t = 0;
      for j = 1:ncol_
        idm = girder.idme(ids(j));
        L_ = L_ + lm_weight(idm) * 1e-3;
        W_t = W_t + Am(idm) * lm_weight(idm) * PRM.RHOS * 1e-9;
      end

      sl = secmgr.secList.list{idslist};
      sym = sl.symbol{idsection};
      type_name = normalize_ss7_steel_type_name(sl.type{idsection});
      mat_name = material.name{idmat_gir(ig1)};

      irow = irow + 1;
      body{irow, 1} = nmg.story_name{ing};
      body{irow, 2} = nmg.frame_name{ing};
      body(irow, 3:4) = nmg.coord_name(ing, :);
      body{irow, 5} = secg.full_name{idsg};
      body{irow, 6} = '－';
      body{irow, 7} = type_name;
      body{irow, 8} = format_steel_cost_dim(stype_, secdim(is, :), sym);
      body{irow, 9} = sprintf('%.2f', A_);
      body{irow, 10} = mat_name;
      body{irow, 11} = sprintf('%.2f', uw);
      body{irow, 12} = sprintf('%.3f', L_);
      body{irow, 13} = sprintf('%.3f', W_t);
    else
      % 通し梁でない: 要素ごとに出力
      for j = 1:ncol_
        ig = ids(j);
        gtype = girder.type(ig);
        if gtype == PRM.GIRDER_FOR_KBRACE2
          continue
        end
        if idsec_gir(ig) == 0
          continue
        end

        is = idsec_gir(ig);
        stype_ = stype(is);
        idsg = girder.idsecg(ig);
        idm = girder.idme(ig);
        idslist = secdim(is, 6);
        idsection = secdim(is, 7);
        A_ = Am(idm) * 1e-2;
        uw = Am(idm) * PRM.RHOS * 1e-3;
        L_ = lm_weight(idm) * 1e-3;
        W_t = Am(idm) * lm_weight(idm) * PRM.RHOS * 1e-9;

        % K形ブレース梁: ペア梁の長さ・重量を合算
        if gtype == PRM.GIRDER_FOR_KBRACE1
          ig_pair = girder.idconnected_girder(ig);
          if ig_pair > 0
            idm2 = girder.idme(ig_pair);
            L_ = L_ + lm_weight(idm2) * 1e-3;
            W_t = W_t + Am(idm2) * lm_weight(idm2) * PRM.RHOS * 1e-9;
          end
        end

        sl = secmgr.secList.list{idslist};
        sym = sl.symbol{idsection};
        type_name = normalize_ss7_steel_type_name(sl.type{idsection});
        mat_name = material.name{idmat_gir(ig)};

        irow = irow + 1;
        body{irow, 1} = nmg.story_name{ing};
        body{irow, 2} = nmg.frame_name{ing};
        body(irow, 3:4) = nmg.coord_name(ing, :);
        body{irow, 5} = secg.full_name{idsg};
        body{irow, 6} = '－';
        body{irow, 7} = type_name;
        body{irow, 8} = format_steel_cost_dim(stype_, secdim(is, :), sym);
        body{irow, 9} = sprintf('%.2f', A_);
        body{irow, 10} = mat_name;
        body{irow, 11} = sprintf('%.2f', uw);
        body{irow, 12} = sprintf('%.3f', L_);
        body{irow, 13} = sprintf('%.3f', W_t);
      end
    end
  end
end

body = body(1:irow, :);

return
end
