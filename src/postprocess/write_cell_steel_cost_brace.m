function [head, body] = write_cell_steel_cost_brace(com, result, cost)
%write_cell_steel_cost_brace - 鉄骨数量（鉛直ブレース）セル配列を生成
%
%   [head, body] = write_cell_steel_cost_brace(
%     com, result, cost) は、
%   SS7積算「部位ごと数量 — 鉄骨」の鉛直ブレース
%   パートと同様式のセル配列を生成する。
%   SS7積算マニュアル 4.4.5「鉛直ブレース」に対応。
%   引張ブレース(TB)を含む。
%   メーカー製品(4.4.6)は対象外。
%   K形・X形は2本合計の長さ・重量を1行で出力する。
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
nstory = com.nstory;
nblx = com.nblx;
nbly = com.nbly;
brace = com.member.brace;
secb = com.section.brace;
stype = com.section.property.type;
secdim = result.secdim;
Am = result.msprop.A;
nominal_brace = com.nominal.brace;
nnb = com.num.nominal_brace;
secmgr = com.secmgr;
material = com.material;

% 鉄骨積算データ（cost構造体から取得）
idsec_brc = cost.brace.idsec;
idmat_brc = cost.brace.idmat;
lm_brace_cost = cost.brace.lm;

% ヘッダ
head = cell(2, NCOL);
head(1, :) = {'階', 'ﾌﾚｰﾑ', '軸-軸', '', '符号', 'ﾀｲﾌﾟ', '種類', ...
  '鉄骨断面', 'A', '材料', '単位重量', 'L', 'W'''};
head(2, 8:NCOL) = {'mm', 'cm2', '', 'kg/m', 'm', 't'};

% ボディ
body = cell(nnb, NCOL);
irow = 0;

ids_story = nominal_brace.idstory;
idx_nom = nominal_brace.idx;
idy_nom = nominal_brace.idy;
idir_nom = nominal_brace.idir;

for ist = nstory:-1:1
  % X通りブレース（Y→X順）
  for iy = 1:nbly
    for ix = 1:nblx
      inb_list = find(ids_story == ist & idx_nom(:,1) == ix ...
        & idy_nom(:,1) == iy & idir_nom == PRM.X);
      for inb = inb_list'
        add_row(inb);
      end
    end
  end
  % Y通りブレース（X→Y順）
  for ix = 1:nblx
    for iy = 1:nbly
      inb_list = find(ids_story == ist & idx_nom(:,1) == ix ...
        & idy_nom(:,1) == iy & idir_nom == PRM.Y);
      for inb = inb_list'
        add_row(inb);
      end
    end
  end
end

body = body(1:irow, :);

return

  function add_row(inb)
  %add_row - 1名目ブレース分の body 行を追記
  %
  %   add_row(inb) は、名目ブレース番号 inb に対応する
  %   body 行を1行追記する。積算対象外（idsec=0）と
  %   メーカー製品（BRB, OTS）はスキップする。
  %   K形・X形は2本合計の L・W を1行に出力する。
  %
  %   入力引数:
  %     inb - 名目ブレース番号
    ibij = nominal_brace.idmeb(inb, :);
    nz_cols = find(ibij > 0);
    npair = length(nz_cols);
    ib1 = ibij(nz_cols(1));

    % 積算対象外（idsec未設定）はスキップ
    if idsec_brc(ib1) == 0
      return
    end

    is = idsec_brc(ib1);
    stype_ = stype(is);

    % メーカー製品（BRB, OTS）は別セクション（4.4.6）で出力するためスキップ
    if ismember(stype_, [PRM.BRB, PRM.OTS])
      return
    end

    idsb = brace.idsecb(ib1);
    idslist = secdim(is, 6);
    idsection = secdim(is, 7);

    idm1 = brace.idme(ib1);
    A_ = Am(idm1) * 1e-2;
    uw = Am(idm1) * PRM.RHOS * 1e-3;
    L_total = lm_brace_cost(ib1) * 1e-3;
    W_total = Am(idm1) * lm_brace_cost(ib1) * PRM.RHOS * 1e-9;

    % 2本目があれば合算
    if npair >= 2
      ib2 = ibij(nz_cols(2));
      idm2 = brace.idme(ib2);
      L_total = L_total + lm_brace_cost(ib2) * 1e-3;
      W_total = W_total + Am(idm2) * lm_brace_cost(ib2) * PRM.RHOS * 1e-9;
    end

    % タイプ名
    switch brace.type(ib1)
      case PRM.BRACE_MEMBER_TYPE_X
        if npair == 2
          type_name_brace = 'Ｘ';
        elseif brace.pair(ib1) == PRM.BRACE_MEMBER_PAIR_L
          type_name_brace = '／';
        else
          type_name_brace = '＼';
        end
      case PRM.BRACE_MEMBER_TYPE_K_UPPER
        type_name_brace = 'K上';
      case PRM.BRACE_MEMBER_TYPE_K_LOWER
        type_name_brace = 'K下';
      otherwise
        type_name_brace = '';
    end

    sl = secmgr.secList.list{idslist};
    type_name = normalize_ss7_steel_type_name(sl.type{idsection});
    if stype_ == PRM.TB
      dim_sym = sl.label{idsection};
    else
      dim_sym = sl.symbol{idsection};
    end
    mat_name = material.name{idmat_brc(ib1)};

    irow = irow + 1;
    body{irow, 1} = nominal_brace.floor_name{inb};
    body{irow, 2} = nominal_brace.frame_name{inb, 1};
    body(irow, 3:4) = nominal_brace.coord_name(inb, 1:2);
    body{irow, 5} = secb.name{idsb};
    body{irow, 6} = type_name_brace;
    body{irow, 7} = type_name;
    body{irow, 8} = format_steel_cost_dim(stype_, secdim(is, :), dim_sym);
    body{irow, 9} = sprintf('%.2f', A_);
    body{irow, 10} = mat_name;
    body{irow, 11} = sprintf('%.2f', uw);
    body{irow, 12} = sprintf('%.3f', L_total);
    body{irow, 13} = sprintf('%.3f', W_total);
  end
end
