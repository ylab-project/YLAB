function [head, body] = write_cell_girder_force_list(com, result, icase)
%WRITE_CELL_GIRDER_FORCE_LIST 梁応力表のセル配列を生成
% 概要: 指定ケースの梁応力一覧をセル配列形式で出力
% 構文: [lhead, body] =
%   write_cell_girder_force_list(com, result, icase)
% 入力:
%   com    - 共通データ構造体
%   result - 解析結果構造体（lm, rs0, Mc0を含む）
%   icase  - ケース番号（スカラー整数）
% 出力:
%   head - {2×ncol} ヘッダセル配列
%   body - {nrow×ncol} データセル配列
% See also: write_cell_column_force_list

%% 定数
ng = com.nmeg;
nblx = com.nblx;
nbly = com.nbly;
nstory = com.nstory;

%% 共通配列
girder = com.member.girder;
secg = com.section.girder;
lm = result.lm;
rs0 = result.rs0;
Mc0 = result.Mc0;
nominal_girder = com.nominal.girder;
idnominal = com.member.girder.idnominal;
% story = com.story;
% dnode = result.dnode;
% feqvec = com.feqvec;
% node = com.node;
% n2df = com.node.dof;
% sw = result.sw;

%% ヘッダ定義（層、フレーム、座標、符号、分割、応力値）
head = { ...
  '層', 'ﾌﾚｰﾑ', '軸－軸', '', '符号', '分割', ...
  '部材長', '左端M', '中央M', '右端M', '左端Q', '中央Q', '右端Q'...
  '左端N', '右端N'; ...
  '', '', '', '', '', 'No.', ...
  'mm', 'kNm', 'kNm', 'kNm', 'kN', 'kN', 'kN', ...
  'kN', 'kN'};
ncol = size(head,2);
body = cell(0,ncol);

%% 早期リターン判定
if ng==0 || isempty(lm)
  return
end
if isempty(rs0) || size(rs0,3)<icase
  return
end
if isempty(Mc0) || size(Mc0,2)<icase
  return
end

%% 対象ケースのデータを抽出
rs = rs0(:,:,icase);
Mc = Mc0(:,icase);
body = cell(0,ncol);
iggg = 1:ng;
irow = 0;
processed = false(ng,1);

%% 層ごとに梁を処理（上階から下階へ）
for i = 1:nstory
  ist = nstory-i+1;
  % X方向梁（idir=1）を処理
  idir = 1;
  for iy = 1:nbly
    for ix = 1:nblx
      ig_list = iggg(girder.idstory==ist & girder.idx(:,1)==ix & ...
        girder.idy(:,1)==iy & girder.idir==idir);
      if isempty(ig_list)
        continue;
      end
      for idxIg = 1:numel(ig_list)
        add_row(ig_list(idxIg));
      end
    end
  end
  % Y方向梁（idir=2）を処理
  idir = 2;
  for ix = 1:nblx
    for iy = 1:nbly
      ig_list = iggg(girder.idstory==ist & girder.idx(:,1)==ix & ...
        girder.idy(:,1)==iy & girder.idir==idir);
      if isempty(ig_list)
        continue;
      end
      for idxIg = 1:numel(ig_list)
        add_row(ig_list(idxIg));
      end
    end
  end
end

%% 結果を整形して返却
if irow==0
  body = cell(0,ncol);
else
  body = body(1:irow,:);
end
return

%% ローカル関数
% ローカル関数: 梁部材の行追加（Kブレース判定込み）
  function add_row(ig)
    if processed(ig)
      return
    end
    gtype = girder.type(ig);
    if gtype == PRM.GIRDER_FOR_KBRACE1
      add_kbrace_rows(ig);
      return
    end
    add_single_row(ig);
  end

% ローカル関数: Kブレース通し梁の複数部材を一括追加
  function add_kbrace_rows(ig_left)
    idx_nom = idnominal(ig_left,1);
    if idx_nom<=0 || idx_nom>size(nominal_girder.idmeg,1)
      processed(ig_left) = true;
      return
    end
    idparts = nominal_girder.idmeg(idx_nom,:);
    idparts = idparts(idparts>0);
    axis_from = nominal_girder.coord_name{idx_nom,1};
    axis_to = nominal_girder.coord_name{idx_nom,2};
    has_entry = false;
    for k = 1:numel(idparts)
      ig_part = idparts(k);
      gtype_part = girder.type(ig_part);
      if gtype_part~=PRM.GIRDER_FOR_KBRACE1 && ...
          gtype_part~=PRM.GIRDER_FOR_KBRACE2
        continue;
      end
      add_member_row(ig_part, k, axis_from, axis_to);
      processed(ig_part) = true;
      has_entry = true;
    end
    if ~has_entry
      processed(ig_left) = true;
    end
  end

% ローカル関数: 通常梁の1行追加
  function add_single_row(ig_)
    axis_from = girder.coord_name{ig_,1};
    axis_to = girder.coord_name{ig_,2};
    add_member_row(ig_, 1, axis_from, axis_to);
    processed(ig_) = true;
  end

% ローカル関数: 指定部材の行を追加（分割番号付き）
  function add_member_row(ig_, seq_, axis_from, axis_to)
    irow = irow+1;
    fill_row_from_member(irow, ig_, seq_, axis_from, axis_to);
  end

% ローカル関数: 行データの実際の書き込み（部材情報と応力値）
  function fill_row_from_member(row_idx, ig_, seq_, axis_from, axis_to)
    im = girder.idme(ig_);
    % 位置情報（層、フレーム、座標、符号、分割番号）
    body{row_idx,1} = girder.story_name{ig_};
    body{row_idx,2} = girder.frame_name{ig_};
    body{row_idx,3} = axis_from;
    body{row_idx,4} = axis_to;
    isg = girder.idsecg(ig_);
    body{row_idx,5} = [secg.subindex{isg} secg.name{isg}];
    body{row_idx,6} = seq_;
    % 応力値（部材長、M[kNm]、Q[kN]、N[kN]）
    body{row_idx,7} = sprintf('%.0f', lm(im));
    body{row_idx,8} = sprintf('%.1f', -rs(im,5)*1.d-6);
    body{row_idx,9} = sprintf('%.1f', Mc(ig_)*1.d-6);
    body{row_idx,10} = sprintf('%.1f', -rs(im,11)*1.d-6);
    body{row_idx,11} = sprintf('%.1f', rs(im,3)*1.d-3);
    body{row_idx,12} = '';
    body{row_idx,13} = sprintf('%.1f', rs(im,9)*1.d-3);
    body{row_idx,14} = sprintf('%.1f', rs(im,1)*1.d-3);
    body{row_idx,15} = sprintf('%.1f', rs(im,7)*1.d-3);
  end
end
