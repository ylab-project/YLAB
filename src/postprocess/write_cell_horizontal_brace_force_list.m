function [hbflhead, hbflbody] = ...
  write_cell_horizontal_brace_force_list(com, result, icase)
% 水平ブレース応力表のセル配列を生成する
%
% 指定した荷重ケースに対する水平ブレース応力表のヘッダと本体データを
% セル配列形式で生成する。出力は層別・通り別に整理され、
% CSV出力やExcel出力に適した形式となっている。
%
%% Syntax
%   [hbflhead, hbflbody] = write_cell_horizontal_brace_force_list(com, result, icase)
%
%% Inputs
%   com    - 構造解析モデルデータ（struct）
%            .nmehb: 水平ブレース総数
%            .nblx: X方向通り数
%            .nbly: Y方向通り数
%            .nstory: 層数
%            .member.horizontal_brace: 水平ブレース部材情報
%            .section.horizontal_brace: 水平ブレース断面情報
%   result - 解析結果データ（struct）
%            .lm: 部材長配列（mm）
%            .rs0: 部材応力配列（N, kN·m, kN·m）
%   icase  - 荷重ケース番号（integer）
%
%% Outputs
%   hbflhead - ヘッダ部のセル配列（2×8 cell）
%              {'層', 'X軸', 'Y軸', 'X軸', 'Y軸', '符号', '部材長', 'N'}
%              および単位行
%   hbflbody - データ部のセル配列（nhb×8 cell）
%              各行: [層名, X軸始点, Y軸始点, X軸終点, Y軸終点, 断面符号, 部材長(mm), 軸力(kN)]
%
%% Example
%   >> [header, body] = write_cell_horizontal_brace_force_list(com, result, 1);
%   >> disp(header)
%   >> disp(body(1:3, :))  % 最初の3行を表示

% 定数
nhb = com.nmehb;
nblx = com.nblx;
nbly = com.nbly;
nstory = com.nstory;

% 共通配列
hbrace = com.member.horizontal_brace;
sechb = com.section.horizontal_brace;
lm = result.lm;
rs = result.rs0(:,:,icase);

% --- 水平ブレース応力表（ヘッダ） ---
hbflhead = cell(2,8);
hbflhead(1,1:8) = { ...
  '層', 'X軸', 'Y軸', 'X軸', 'Y軸', '符号', '部材長', 'N'};
hbflhead(2,7:8) = { ...
  'mm','kN'};

% --- 水平ブレース応力表（本体） ---
hbflbody = cell(nhb,8);
ibbb = 1:nhb;
irow = 0;
isprinted = false(1,nhb);
for i = 1:nstory
  ist = nstory-i+1;
  for iy = 1:nbly
    for ix = 1:nblx
      ibs = ibbb(hbrace.idstory==ist & ...
        hbrace.idx(:,1)==ix & hbrace.idy(:,1)==iy);
      if isempty(ibs)
        continue
      end
      for ib=ibs
        print_row(ib);
        ibpair = hbrace.idpair(ib);
        if(ibpair>0)
          print_row(ibpair);
        end
      end
    end
  end
end
return
%------------------------------------------------------------------------
  function print_row(ib_)
    if (isprinted(ib_))
      return
    end
    isprinted(ib_) = true;
    irow = irow+1;
    hbflbody{irow,1} = hbrace.story_name{ib_};
    hbflbody{irow,2} = hbrace.xcoord_name{ib_,1};
    hbflbody{irow,3} = hbrace.ycoord_name{ib_,1};
    hbflbody{irow,4} = hbrace.xcoord_name{ib_,2};
    hbflbody{irow,5} = hbrace.ycoord_name{ib_,2};
    isb = hbrace.idsechb(ib_);
    hbflbody{irow,6} = sechb.name{isb};
    im = hbrace.idme(ib_);
    hbflbody{irow,7} = sprintf('%.0f', lm(im));
    hbflbody{irow,8} = sprintf('%.1f', rs(im,1)*1.d-3);
  end
end
