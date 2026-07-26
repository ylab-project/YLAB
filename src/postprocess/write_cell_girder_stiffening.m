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
nstory = com.nstory;

% 共通配列
girder = com.member.girder;
nominal_girder = com.nominal.girder;
secg = com.section.girder;
slratio = result.slratio;
gstype = girder.section_type;
conslr = result.conslr;

% --- ヘッダー ---
head = cell(4,1);
head(1,1:19) = {'層', 'ﾌﾚｰﾑ', '軸－軸', '', '符号', '部材長', ...
  'n', '左端', '', '右端', '', '最大Lb', '等間隔に設ける', ...
  '', '', '端部に設ける', '', '', '判定';};
head(2,8:18) = {'Lb1','Lb2', 'Lb2', 'Lb1', '(入力)', ...
  'λ', '限界Lb', '必要n', 'Myを超える範囲', '', '限界Lb'};
head(4,8:18) = {'mm', 'mm', 'mm', 'mm', 'mm', '', 'mm', ...
  '', 'mm', 'mm', 'mm'};

% --- 保有耐力横補剛 ---
body = cell(ng, 19);
if isempty(slratio)
  stgcell.head = head;
  stgcell.body = body;
  return
end
segments = make_report_segments();
if ~isempty(segments)
  sort_key = vertcat(segments.sort_key);
  [~, iord] = sortrows(sort_key);
  segments = segments(iord);
end
irow = 0;
for iseg = 1:numel(segments)
  seg = segments(iseg);
  ids = seg.ids;
  ig = seg.ig_ref;
  ing = seg.ing;
  coord1 = seg.coord1;
  coord2 = seg.coord2;
  if gstype(ig) ~= PRM.WFS
    continue
  end
  if ~any(any(girder.slr_is_target(ids, :)))
    continue
  end
  irow = irow + 1;
  print_row
end
stgcell.head = head;
stgcell.body = body;
return
  function print_row
  %print_row - 1梁分の横補剛検討値を body の現在行に書き出す
    body{irow,1} = girder.story_name{ig};
    body{irow,2} = girder.frame_name{ig};
    body{irow,3} = coord1;
    body{irow,4} = coord2;
    isg = girder.idsecg(ig);
    body{irow,5} = make_section_symbol(secg, isg);
    % slratio と conslr はH形梁のみを対象とし、その連番で
    % インデックスされる。梁番号から変換して引く。
    iwfs = girder.idmewfs(ig);
    lg_ = slratio.lg(iwfs);
    nreq_ = slratio.nreq(iwfs);
    lbreq1_ = slratio.lbreq1(iwfs);
    lbmy_ = slratio.lbmy(iwfs, :);
    lbmax_raw_ = slratio.lbmax(iwfs);
    [lb1_, is_lb1_full] = normalize_full_length_interval( ...
      slratio.lb(iwfs, 1), lg_);
    [lb2_, is_lb2_full] = normalize_full_length_interval( ...
      slratio.lb(iwfs, 2), lg_);
    lbmax_ = normalize_full_length_interval(lbmax_raw_, lg_);
    [n_, lb_report_, has_report_lb_] = ...
      get_stiffening_lb_report(nominal_girder, ing, slratio.n(iwfs));
    body{irow,6} = fmt_ceil_abs(lg_, 0);
    if has_report_lb_
      body{irow,7} = sprintf('%.0f', n_);
      body{irow,8} = fmt_ceil_abs(lb_report_(1), 0);
      if lb_report_(1) < lbmy_(1)
        body{irow,9} = fmt_ceil_abs(lb_report_(2), 0);
      end
      if lb_report_(4) < lbmy_(2)
        body{irow,10} = fmt_ceil_abs(lb_report_(3), 0);
      end
      body{irow,11} = fmt_ceil_abs(lb_report_(4), 0);
    else
      % 自動認識の横補剛数 = 補剛区間数 - 1（SS7計算編3.5）
      % n=0 は空白表示とする
      nbrace_ = nominal_girder.nstiff(ing) - 1;
      if nbrace_ > 0
        body{irow,7} = sprintf('%.0f', nbrace_);
      end
      if ~is_lb1_full
        body{irow,8} = fmt_ceil_abs(lb1_, 0);
      end
      if ~is_lb2_full
        body{irow,11} = fmt_ceil_abs(lb2_, 0);
      end
    end
    body{irow,12} = fmt_ceil_abs(lbmax_, 0);
    body{irow,13} = sprintf('%.0f', slratio.lambda(iwfs));
    % 必要n=0 の場合、等間隔配置の限界LbはSS7に合わせて空白
    if nreq_ > 0
      body{irow,14} = fmt_ceil_abs(lbreq1_, 0);
    end
    % 必要n: 最大Lbが限界Lbを超える場合は補剛不能を示す *
    nreq_str = sprintf('%d', nreq_);
    if nreq_ > 0 && lbmax_raw_ > lbreq1_
      nreq_str = [nreq_str '*'];
    end
    body{irow,15} = nreq_str;
    body{irow,16} = fmt_ceil_abs(lbmy_(1), 0);
    body{irow,17} = fmt_ceil_abs(lbmy_(2), 0);
    % 端部 限界Lb: 端部配置で満足しない場合のみ補剛不能を示す *
    lbreq2_str = fmt_ceil_abs(slratio.lbreq2(iwfs), 0);
    if ~slratio.isOkEnd(iwfs)
      lbreq2_str = [lbreq2_str '*'];
    end
    body{irow,18} = lbreq2_str;
    if conslr(iwfs)<=0
      judgement = 'OK';
    else
      judgement = 'NG';
    end
    body{irow,19} = judgement;
  end

  function segments = make_report_segments()
  %make_report_segments - 名目梁単位の帳票表示単位を作成する
    template = struct('ing', 0, 'ids', [], 'ig_ref', 0, ...
      'coord1', '', 'coord2', '', 'sort_key', zeros(1, 6));
    segments = repmat(template, ng, 1);
    nseg = 0;
    nng = size(nominal_girder, 1);
    % 名目梁1本を1行とする。通し梁は元梁境界で分けず、K形分割の
    % 中間節点も表に出さない
    for ing_ = 1:nng
      ids_all = nominal_girder.idmeg(ing_, :);
      ids_all = ids_all(ids_all > 0);
      if isempty(ids_all)
        continue
      end
      nseg = nseg + 1;
      segments(nseg) = make_segment(ing_, ids_all);
    end
    segments = segments(1:nseg);

    return
  end

  function segment = make_segment(ing_, ids_)
  %make_segment - 1つの帳票表示単位を作成する
    ig_ref_ = ids_(1);
    segment.ing = ing_;
    segment.ids = ids_;
    segment.ig_ref = ig_ref_;
    segment.coord1 = girder.coord_name{ids_(1), 1};
    segment.coord2 = girder.coord_name{ids_(end), 2};
    segment.sort_key = get_sort_key(ig_ref_);

    return
  end

  function sort_key = get_sort_key(ig_)
  %get_sort_key - 既存の物理梁順に合わせる並び替えキーを返す
    story_key = nstory - girder.idstory(ig_);
    if girder.idir(ig_) == PRM.X
      dir_key = 1;
      major_key = girder.idy(ig_, 1);
      minor_key = girder.idx(ig_, 1);
    else
      dir_key = 2;
      major_key = girder.idx(ig_, 1);
      minor_key = girder.idy(ig_, 1);
    end
    sort_key = [story_key, dir_key, major_key, minor_key, ...
      girder.idz(ig_, 1), ig_];

    return
  end

  function [len, is_full_length] = normalize_full_length_interval( ...
    len, full_len)
  %normalize_full_length_interval - 全長相当の補剛間隔を部材長へ寄せる
    is_full_length = abs(len - full_len) < 1;
    if is_full_length
      len = full_len;
    end

    return
  end

end
