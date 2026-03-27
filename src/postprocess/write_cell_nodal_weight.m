function [nwhead, nwbody] = write_cell_nodal_weight(com, result)
%write_cell_nodal_weight - 節点重量表のセル配列を生成（2行/節点）

% 定数
nn = com.nnode;
nblx = com.nblx;
nbly = com.nbly;
nstory = com.nstory;

% 共通配列
feqvec = result.felement(:,1);
fnode = com.fnode(:,1);
faddnode = com.faddnode(:,1);
node = com.node;
n2df = com.node.dof;
sw = result.sw;

% KBRACE-MID節点の自重をグリッド節点に再配分
[feqvec, fg_, fw_, fc_, f_] = redistribute_kbrace_mid(...
  com, feqvec, sw.fg, sw.fw, sw.fc, sw.f);
sw.fg = fg_;
sw.fw = fw_;
sw.fc = fc_;
sw.f = f_;

% --- 節点重量表（SS7互換: 2行/節点） ---
nwhead = {'X軸', 'Y軸', '層', '床自重', '梁自重', '壁自重', '特殊荷重', ...
  '柱自重', '補正', 'ﾌﾚｰﾑ外', '基礎重量', '合計', '概算軸力', ...
  '概算軸力TL'; '', '', '', 'kN', 'kN', 'kN', 'kN', 'kN', ...
  'kN', 'kN', 'kN', 'kN', 'kN', 'kN'};
ncol = 15; % 14データ列 + <RE>列
nwbody = cell(nn*2, ncol);
innn = 1:nn;
irow = 0;
for iy = 1:nbly
  for ix = 1:nblx
    for i = 1:nstory
      ist = nstory-i+1;
      in = innn(node.idx==ix & node.idy==iy & node.idstory==ist);
      % ブレース用柱分割節点をスキップ
      in = in(node.type(in) ~= PRM.NODE_BRACE_FOR_COLUMN);
      if isempty(in)
        continue
      end
      % 同一化された節点はスキップ
      if node.idrep(in) > 0
        continue
      end
      idf = n2df(in,3);
      floor_ = feqvec(idf) * 1.d-3;
      nf_ = (fnode(idf)+faddnode(idf)) * 1.d-3;
      total_ = (feqvec(idf)+sw.f(idf)) * 1.d-3 - nf_;
      % 1行目: 節点名 + 床自重 + 小計
      irow = irow + 1;
      nwbody{irow,1} = node.xname{in};
      nwbody{irow,2} = node.yname{in};
      nwbody{irow,3} = node.zname{in};
      nwbody{irow,4} = fmt(floor_);
      nwbody{irow,12} = fmt(floor_);
      % 2行目: 各自重 + 合計 + <RE>
      irow = irow + 1;
      nwbody{irow,5} = fmt(sw.fg(idf)*1.d-3);
      nwbody{irow,6} = fmt(sw.fw(idf)*1.d-3);
      nwbody{irow,8} = fmt(sw.fc(idf)*1.d-3);
      nwbody{irow,12} = fmt(total_);
      nwbody{irow,ncol} = '<RE>';
    end
  end
end
nwbody = nwbody(1:irow,:);

return
end

function s = fmt(v)
%fmt - 0は空欄、それ以外は小数1桁で書式化
  if abs(v) < 0.05
    s = '';
  else
    s = sprintf('%.1f', v);
  end

  return
end
