function [cphead, cpbody] = write_cell_column_property(com, result)
%write_cell_column_property - 柱断面諸量出力のセル配列を生成
%
%   [cphead, cpbody] = write_cell_column_property(com, result) は、
%   柱断面の諸量（E, G, Io, I, As, An, α, β, κ, 部材長, 剛域,
%   フェイス位置, 結合状態 等）を階・通り・符号ごとに集計した
%   セル配列を生成する。x/y 方向で2行ずつ出力する。
%
%   入力引数:
%     com    - 共通オブジェクト
%     result - 解析結果構造体 (msprop, Iy/Iz, lm, lf, lr, cbs 等)
%
%   出力引数:
%     cphead - ヘッダ部セル配列 [3×27]
%     cpbody - データ部セル配列 [(2*nrow)×28]（最終列は CONT_MARKER）

% 定数
nblx = com.nblx;
nbly = com.nbly;
nblz = com.nblz;
nc = com.nmec;
nfl = com.nfl;
idmc2m = com.member.column.idme;
idm2scb = com.member.property.idseccb;

% 共通配列
column = com.member.column;
secc = com.section.column;
floor = com.floor;
msprop = result.msprop;
Iy = result.Iy;
Iz = result.Iz;
cphiI = result.cphiI;
lm = result.lm;
lfcx = result.lf.columnx;
lfcy = result.lf.columny;
lrcx = result.lr.columnx;
lrcy = result.lr.columny;
cbstiff = result.cbs.stiff;
nominal_column = com.nominal.column;

% 準備計算
idmc2nmc = column.idnominal;
Em = msprop.E;
Gm = msprop.G;

% --- 柱断面 ---
cphead = cell(3,27);
cphead(1,:) = {'階', 'X軸', 'Y軸', '符号', '方', 'E', 'G', 'Io', ...
  'φI', 'I', 'Aso', 'Ano', 'φQ', 'φn', 'As', 'An', 'α', 'αn', ...
  'β', 'κ', '部材長', '剛域', '', 'フェイス位置', '', ...
  '結合状態', ''};
cphead(2,:) = {'', '', '', '', '向', '', '', '', '', '', '', '', ...
  '', '', '', '', '', '', '', '', '', '柱頭', '柱脚', '柱頭', ...
  '柱脚', '柱頭', '柱脚'};
cphead(3,:) = {'', '', '', '', '', 'kN/mm2', 'kN/mm2', 'cm4', '', ...
  'cm4', 'cm2', 'cm2', '', '', 'cm2', 'cm2', '', '', '', '', ...
  'mm', 'mm', 'mm', 'mm', 'mm', 'kNm/rad', 'kNm/rad'};

cpbody = cell(nc*2, size(cphead,2)+1);  % 末尾は marker 列
irow = 0;
iccc = 1:nc;
for i=1:nfl
  ifl = nfl-i+1;
  for iy = 1:nbly
    for ix = 1:nblx
      for iz = 1:nblz
        % 柱脚側で判定する（SS7ルール）
        ic = iccc(column.idfloor==ifl & column.idx(:,1)==ix ...
          & column.idy(:,1)==iy & column.idz(:,1)==iz);
        if isempty(ic)
          continue
        end
        if column.type(ic) == PRM.COLUMN_FOR_BRACE_BODY
          continue
        end
        % 共通
        idm = column.idme(ic);
        lm_ = lm(idm);
        lfcx_ = lfcx(ic,:);
        lfcy_ = lfcy(ic,:);
        iscb_ = idm2scb(idm);
        % 分割部材対応
        if column.type(ic) == PRM.COLUMN_FOR_BRACE_FOUNDATION
          idnmc = idmc2nmc(ic);
          idcc = nominal_column.idmec(idnmc,:);
          idcc = idcc(idcc > 0);
          idmm = idmc2m(idcc);
          lm_ = sum(lm(idmm));
          lfcx_(2) = lfcx(idcc(end),2);
          lfcy_(2) = lfcy(idcc(end),2);
          iscb_ = idm2scb(idmm(end));
        end
        % 剛性表
        write_cpbody
        % 1 柱 = 2 物理行/論理ブロック。x 行（1 行目）に CONT_MARKER
        cpbody{irow*2-1, end} = PRM.CONT_MARKER;
      end
    end
  end
end

return
%--------------------------------------------------------------------------
  function write_cpbody
  %write_cpbody - 1柱分の断面諸量を cpbody の現在行(2行)に書き出す
  %
  %   write_cpbody は、外側スコープの irow をインクリメントし、
  %   現在の柱 ic の x/y 方向諸量を cpbody{irow*2-1, :} (x行) と
  %   cpbody{irow*2, :} (y行) に書き出す。
  %
  %   入力引数:
  %     なし（外側スコープの ic, idm, lm_, lfcx_, lfcy_, iscb_,
  %     ifl, msprop, Iy, Iz, cphiI, lrcx, lrcy, cbstiff,
  %     column, secc, floor, Em, Gm を参照）
  %
  %   出力引数:
  %     なし（外側の cpbody と irow を更新）
    irow = irow+1;
    floor_name = floor.name{ifl};
    cpbody{irow*2-1,1} = floor_name;
    cpbody(irow*2-1,2:3) = column.coord_name(ic,1:2);
    idsc = column.idsecc(ic);
    cpbody{irow*2-1,4} = make_section_symbol(secc, idsc);
    cpbody(irow*2-1:irow*2,5) = {'x'; 'y'};
    cpbody{irow*2-1,6} = Em(idm)*1.d-3;
    cpbody{irow*2-1,7} = sprintf('%.2f', Gm(idm)*1.d-3);
    cpbody{irow*2-1,8} = sprintf('%.0f', msprop.Iy(idm)*1.d-4);
    cpbody{irow*2,8} = sprintf('%.0f', msprop.Iz(idm)*1.d-4);
    cpbody{irow*2-1,9} = sprintf('%.3f', cphiI(ic,1));
    cpbody{irow*2,9} = sprintf('%.3f', cphiI(ic,2));
    cpbody{irow*2-1,10} = sprintf('%.0f', Iy(idm)*1.d-4);
    cpbody{irow*2,10} = sprintf('%.0f', Iz(idm)*1.d-4);
    As = sprintf('%.2f', msprop.Asy(idm)*1.d-2);
    An = sprintf('%.2f', msprop.A(idm)*1.d-2);
    cpbody(irow*2-1:irow*2,11) = {As; As};
    cpbody{irow*2-1,12} = An;
    cpbody{irow*2-1,13} = 1;
    cpbody{irow*2,13} = 1;
    cpbody{irow*2-1,14} = 1;
    cpbody(irow*2-1:irow*2,15) = {As; As};
    cpbody{irow*2-1,16} = An;
    cpbody(irow*2-1:irow*2,17) = {1; 1};
    cpbody{irow*2-1,18} = 1;
    cpbody(irow*2-1:irow*2,19) = {1; 1};
    kappa_ = get_kappa(secc.type(idsc));
    cpbody(irow*2-1:irow*2,20) = {kappa_; kappa_};
    cpbody{irow*2-1,21} = sprintf('%.0f', lm_);
    cpbody(irow*2-1:irow*2,22) = ...
      {sprintf('%.0f', lrcx(ic,2)); sprintf('%.0f', lrcy(ic,2))};
    cpbody(irow*2-1:irow*2,23) = ...
      {sprintf('%.0f', lrcx(ic,1)); sprintf('%.0f', lrcy(ic,1))};
    cpbody(irow*2-1:irow*2,24) = ...
      {sprintf('%.0f', lfcx_(2)); sprintf('%.0f', lfcy_(2))};
    cpbody(irow*2-1:irow*2,25) = ...
      {sprintf('%.0f', lfcx_(1)); sprintf('%.0f', lfcy_(1))};
    % column.joint(ic,:) 1:X柱脚, 2:X柱頭, 3:Y柱脚, 4:Y柱頭
    for jxy=1:2
      for kbt=1:2
        jjj = jxy*2+kbt-2;
        switch column.joint(ic,jjj)
          case PRM.PIN
            cpbody{irow*2+jxy-2,28-kbt} = "ピン";
          case PRM.FIX
            cpbody{irow*2+jxy-2,28-kbt} = "剛接";
        end
      end
    end
    if iscb_>0
      kcb = cbstiff(iscb_);
      cpbody(irow*2-1:irow*2,27) = ...
        {sprintf('%.0f', kcb*1.d-6); sprintf('%.0f', kcb*1.d-6)};
    end
    return
  end

  function kappa = get_kappa(stype)
  %get_kappa - 断面種別に応じたせん断形状係数を返す
  %
  %   kappa = get_kappa(stype) は、断面種別 stype に応じて
  %   せん断形状係数 κ を返す。RC矩形断面（PRM.RCRS）は 1.2、
  %   それ以外は 1 を返す。
  %
  %   入力引数:
  %     stype - 断面種別コード
  %
  %   出力引数:
  %     kappa - せん断形状係数
    if stype == PRM.RCRS
      kappa = 1.2;
    else
      kappa = 1;
    end

    return
  end
end
