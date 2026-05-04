function stgcell = write_cell_girder_stiffening(com, result)
%write_cell_girder_stiffening - 梁横補剛表のセル配列を生成
%
%   stgcell = write_cell_girder_stiffening(com, result) は、保有耐力
%   横補剛の検討結果（Lb, λ, 限界Lb, 必要補剛数 等）を符号別に
%   集計したセル配列をヘッダ・ボディ構造で返す。
%
%   入力引数:
%     com    - 共通オブジェクト
%     result - 解析結果構造体 (slratio, conslr 等)
%
%   出力引数:
%     stgcell - 構造体（head, body フィールド）
%       stgcell.head - ヘッダ部セル配列
%       stgcell.body - データ部セル配列

% 定数
ng = com.nmeg;
nblx = com.nblx;
nbly = com.nbly;
nstory = com.nstory;

% 共通配列
girder = com.member.girder;
secg = com.section.girder;
slratio = result.slratio;
gstype = girder.section_type;
conslr = result.conslr;

% --- ヘッダー ---
head = cell(4,1);
head(1,1:19) = { ...
  '層', 'ﾌﾚｰﾑ', '軸－軸', '', '符号', ...
  '部材長', 'n', '左端', '', '右端', ...
  '', '最大Lb', '等間隔に設ける', '', '', ...
  '端部に設ける', '', '', '判定';};
head(2,8:18) = {'Lb1','Lb2', 'Lb2', 'Lb1', '(入力)', ...
  'λ', '限界Lb', '必要n', 'Myを超える範囲', '', '限界Lb'};
head(4,8:18) = {'mm', 'mm', 'mm', 'mm', 'mm', ...
  '', 'mm', '', 'mm', 'mm', 'mm'};

% --- 保有耐力横補剛 ---
body = cell(ng,16);
if isempty(slratio)
  stgcell.head = head;
  stgcell.body = body;
  return
end
iggg = 1:ng;
irow = 0;
for i = 1:nstory
  ist = nstory-i+1;
  % X方向梁と45度梁を処理
  for iy = 1:nbly
    for ix = 1:nblx
      ig = iggg(girder.idstory==ist & girder.idx(:,1)==ix & ...
        girder.idy(:,1)==iy & ...
        (girder.idir==PRM.X | girder.idir==PRM.XY));
      if isempty(ig) || gstype(ig) ~=PRM.WFS
        continue
      end
      if all(girder.joint(ig,1:2)==PRM.PIN)
        continue
      end
      irow = irow+1;
      print_row
    end
  end
  % Y方向梁を処理（45度梁は既に上で処理済み）
  for ix = 1:nblx
    for iy = 1:nbly
      ig = iggg(girder.idstory==ist & girder.idx(:,1)==ix & ...
        girder.idy(:,1)==iy & girder.idir==PRM.Y);
      if isempty(ig) || gstype(ig) ~=PRM.WFS
        continue
      end
      if all(girder.joint(ig,1:2)==PRM.PIN)
        continue
      end
      irow = irow+1;
      print_row
    end
  end
end
stgcell.head = head;
stgcell.body = body;
return
  function print_row
  %print_row - 1梁分の横補剛検討値を body の現在行に書き出す
    body{irow,1} = girder.story_name{ig};
    body{irow,2} = girder.frame_name{ig};
    body{irow,3} = girder.coord_name{ig,1};
    body{irow,4} = girder.coord_name{ig,2};
    isg = girder.idsecg(ig);
    body{irow,5} = make_section_symbol(secg, isg);
    body{irow,6} = sprintf('%.0f', slratio.lg(ig));
    if slratio.lb(ig,1)~=slratio.lg(ig)
      body{irow,8} = sprintf('%.0f', slratio.lb(ig,1));
    end
    if slratio.lb(ig,2)~=slratio.lg(ig)
      body{irow,11} = sprintf('%.0f', slratio.lb(ig,2));
    end
    body{irow,12} = sprintf('%.0f', slratio.lbmax(ig));
    body{irow,13} = sprintf('%.0f', slratio.lambda(ig));
    body{irow,14} = sprintf('%.0f', slratio.lbreq1(ig));
    % 必要n: 等間隔配置の限界Lbを最大Lbが超える場合は補剛不能を示す *
    nreq_str = sprintf('%d', slratio.nreq(ig));
    if slratio.lbmax(ig) > slratio.lbreq1(ig)
      nreq_str = [nreq_str '*'];
    end
    body{irow,15} = nreq_str;
    body{irow,16} = sprintf('%.0f', slratio.lbmy(ig,1));
    body{irow,17} = sprintf('%.0f', slratio.lbmy(ig,2));
    % 端部 限界Lb: Myを超える範囲にかかる横補剛間隔が限界Lbを超える場合 *
    % 補剛なし（n=0）時は最大Lbを横補剛間隔として評価
    lbreq2_str = sprintf('%.0f', slratio.lbreq2(ig));
    if slratio.lbmax(ig) > slratio.lbreq2(ig)
      lbreq2_str = [lbreq2_str '*'];
    end
    body{irow,18} = lbreq2_str;
    if conslr(ig)<=0
      judgement = 'OK';
    else
      judgement = 'NG';
    end
    body{irow,19} = judgement;
  end

end
