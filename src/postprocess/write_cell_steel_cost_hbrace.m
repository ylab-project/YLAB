function [head, body] = ...
  write_cell_steel_cost_hbrace(com, result, cost)
%write_cell_steel_cost_hbrace - 鉄骨数量（水平ブレース）セル配列を生成
%
%   [head, body] = write_cell_steel_cost_hbrace(
%     com, result, cost) は、
%   SS7積算「部位ごと数量 — 鉄骨」の水平ブレース
%   パートと同様式のセル配列を生成する。
%
%   入力引数:
%     com    - 共通オブジェクト
%     result - 解析結果構造体
%     cost   - 積算データ構造体
%
%   出力引数:
%     head - ヘッダ部セル配列
%     body - データ部セル配列

NCOL = 13;

% 定数・共通配列
nhb = com.nmehb;
nblx = com.nblx;
nbly = com.nbly;
nstory = com.nstory;
hbrace = com.member.horizontal_brace;
sechb = com.section.horizontal_brace;
stype = com.section.property.type;
secdim = result.secdim;
Am = result.msprop.A;
secmgr = com.secmgr;
material = com.material;

% 鉄骨積算データ（cost構造体から取得）
lm_hbr = cost.hbrace.lm;
idsec_hbr = cost.hbrace.idsec;
idmat_hbr = cost.hbrace.idmat;

% ヘッダ
head = cell(2, NCOL);
head(1, :) = {'層', 'X軸', 'Y軸', ...
  'X軸', 'Y軸', '符号', '種類', ...
  '鉄骨断面', 'A', '材料', ...
  '単位重量', 'L', 'W'''};
head(2, 8:NCOL) = {'mm', 'cm2', '', 'kg/m', 'm', 't'};

% ボディ
body = cell(nhb, NCOL);
ibbb = 1:nhb;
irow = 0;
isprinted = false(1, nhb);

for i = 1:nstory
  ist = nstory - i + 1;
  for iy = 1:nbly
    for ix = 1:nblx
      ibs = ibbb( ...
        hbrace.idstory == ist ...
        & hbrace.idx(:,1) == ix ...
        & hbrace.idy(:,1) == iy);
      if isempty(ibs)
        continue
      end
      for ib = ibs
        print_row(ib);
        ibpair = hbrace.idpair(ib);
        if ibpair > 0
          print_row(ibpair);
        end
      end
    end
  end
end

body = body(1:irow, :);

return

  function print_row(ib_)
    if isprinted(ib_)
      return
    end
    isprinted(ib_) = true;

    is = idsec_hbr(ib_);
    if is == 0
      return
    end
    stype_ = stype(is);
    isb = hbrace.idsechb(ib_);
    idslist = secdim(is, 6);
    idsection = secdim(is, 7);

    idm = hbrace.idme(ib_);
    L_mm = lm_hbr(ib_);

    A_ = Am(idm) * 1e-2;
    L_ = L_mm * 1e-3;
    W_t = Am(idm) * L_mm * PRM.RHOS * 1e-9;
    uw = Am(idm) * PRM.RHOS * 1e-3;

    sl = secmgr.secList.list{idslist};
    type_name = sl.type{idsection};
    if stype_ == PRM.TB
      dim_sym = type_name;
    else
      dim_sym = sl.symbol{idsection};
    end
    mat_name = material.name{idmat_hbr(ib_)};

    irow = irow + 1;
    body{irow, 1} = hbrace.story_name{ib_};
    body{irow, 2} = hbrace.xcoord_name{ib_, 1};
    body{irow, 3} = hbrace.ycoord_name{ib_, 1};
    body{irow, 4} = hbrace.xcoord_name{ib_, 2};
    body{irow, 5} = hbrace.ycoord_name{ib_, 2};
    body{irow, 6} = sechb.name{isb};
    body{irow, 7} = type_name;
    body{irow, 8} = format_steel_cost_dim( ...
      stype_, secdim(is, :), dim_sym);
    body{irow, 9} = sprintf('%.2f', A_);
    body{irow, 10} = mat_name;
    body{irow, 11} = sprintf('%.2f', uw);
    body{irow, 12} = sprintf('%.3f', L_);
    body{irow, 13} = sprintf('%.3f', W_t);
  end
end
