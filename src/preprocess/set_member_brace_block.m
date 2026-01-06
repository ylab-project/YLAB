function [member_brace, baseline, node, member_column, member_girder] = ...
  set_member_brace_block(dbc, com, options)
% ブレース配置データの読み込みと処理
%
% 入力:
%   dbc: データブロックコントローラ
%   com: 共通データ構造体
%   options: オプション設定
%
% 出力:
%   member_brace: ブレース部材テーブル
%   baseline: 更新された通り線データ
%   node: 更新された節点データ
%   member_column: 更新された柱部材データ
%   member_girder: 更新された梁部材データ

data = dbc.get_data_block('鉛直ブレース配置');
n = size(data,1);

% 共通データの取得
section_brace = com.section.brace;
baseline = com.baseline;
node = com.node;
member_column = com.member.column;
member_girder = com.member.girder;

% 階名、架構名、座標名の取得
floor_name = cell(n,1);
frame_name = cell(n,1);
coord_name = cell(n,2);
for i=1:n
  floor_name{i} = tochar(data{i,1});
  frame_name{i} = tochar(data{i,2});
  coord_name(i,:) = tochar(data(i,3:4));
end

% 断面名の取得
section_name = cell(n,1);
for i=1:n
  section_name{i} = tochar(data{i,5});
end

%% ブレースタイプの解析
brace_type = zeros(n,1);
for i=1:n
  val = data{i,6};
  if ismissing(val)
    continue
  end
  switch val
    case "X形"
      brace_type(i) = PRM.BRACE_MEMBER_TYPE_X;
    case "K上形"
      brace_type(i) = PRM.BRACE_MEMBER_TYPE_K_UPPER;
    case "K下形"
      brace_type(i) = PRM.BRACE_MEMBER_TYPE_K_LOWER;
  end
end

%% ペアの解析
pair = zeros(n,1);
for i=1:n
  val = data{i,7};
  if ismissing(val)
    continue
  end
  switch val
    case "片(左)"
      pair(i) = PRM.BRACE_MEMBER_PAIR_L;
    case "片(右)"
      pair(i) = PRM.BRACE_MEMBER_PAIR_R;
    case "両方"
      pair(i) = PRM.BRACE_MEMBER_PAIR_BOTH;
  end
end

%% 階番号の取得
idstory = zeros(n,1); idds = 1:com.nstory;
for i=1:n
  idstory(i) = idds(matches(com.story.floor_name, floor_name{i}));
end

% 通り番号・方向の取得
[idx, idy, idz, idir, idzn] = find_idxyz_brace(...
  floor_name, frame_name, coord_name, com.baseline, com.story);

% 断面番号の取得
idsecb = zeros(n,1); iddd = 1:com.nsecb;
for i=1:n
  id = iddd(matches(section_brace.name, section_name{i}));
  idsecb(i) = id;
end

% 断面タイプの取得
section_type = section_brace.type(idsecb);

% K形ブレース中間節点配列の初期化
idnode_mid_array = zeros(n,1);

% K形ブレース端点節点の事前計算
id_k_brace = find(brace_type == PRM.BRACE_MEMBER_TYPE_K_UPPER | ...
                  brace_type == PRM.BRACE_MEMBER_TYPE_K_LOWER);
if ~isempty(id_k_brace)
  % K形ブレース端点節点番号を一括取得（梁側と反対側の4節点）
  [idnode_k_L, idnode_k_R, idnode_k_L_far, idnode_k_R_far] = ...
    get_kbrace_endpoint_nodes(id_k_brace, node);
end

% K形ブレース用梁分割処理
if any(brace_type == PRM.BRACE_MEMBER_TYPE_K_UPPER | ...
       brace_type == PRM.BRACE_MEMBER_TYPE_K_LOWER)
  [idnode_mid_array, baseline, node, member_girder] = ...
    split_girder_for_kbrace_func(baseline, node, member_girder);
end

% 節点番号配列の初期化
idnode1 = zeros(n,1);
idnode2 = zeros(n,1);

%% K形ブレースの節点接続処理
if ~isempty(id_k_brace)
  for ik = 1:length(id_k_brace)
    i = id_k_brace(ik);
    idnode_mid = idnode_mid_array(i);

    % K形ブレース：反対側端点→中間→梁側端点
    idnode_L1 = idnode_k_L_far(ik);  % 反対側端点（K上形：下階柱脚、K下形：上階柱頭）
    idnode_R2 = idnode_k_R(ik);       % 梁側端点（K上形：上階、K下形：下階）

    % ペアに応じた節点割り当て
    switch pair(i)
      case PRM.BRACE_MEMBER_PAIR_L
        idnode1(i) = idnode_L1;
        idnode2(i) = idnode_mid;
      case PRM.BRACE_MEMBER_PAIR_R
        idnode1(i) = idnode_mid;
        idnode2(i) = idnode_R2;
      case PRM.BRACE_MEMBER_PAIR_BOTH
        % BOTH展開前は左側のみ設定
        idnode1(i) = idnode_L1;
        idnode2(i) = idnode_mid;
    end
  end
end

%% X形ブレースの節点接続処理
for i=1:n
  if brace_type(i) == PRM.BRACE_MEMBER_TYPE_X
    % X形は通常の対角接続
    switch pair(i)
      case PRM.BRACE_MEMBER_PAIR_L
        idnode1(i) = find_idnode_from_idxyz(...
          idx(i,1), idy(i,1), idz(i,1), node);
        idnode2(i) = find_idnode_from_idxyz(...
          idx(i,2), idy(i,2), idz(i,2), node);
      case PRM.BRACE_MEMBER_PAIR_R
        idnode1(i) = find_idnode_from_idxyz(...
          idx(i,2), idy(i,2), idz(i,1), node);
        idnode2(i) = find_idnode_from_idxyz(...
          idx(i,1), idy(i,1), idz(i,2), node);
      case PRM.BRACE_MEMBER_PAIR_BOTH
        % BOTH展開前は左側のみ設定
        idnode1(i) = find_idnode_from_idxyz(...
          idx(i,1), idy(i,1), idz(i,1), node);
        idnode2(i) = find_idnode_from_idxyz(...
          idx(i,2), idy(i,2), idz(i,2), node);
    end
  end
end

%% 梁天端接続時の柱分割処理
if options.position_brace_foundation_girder ...
    == PRM.BRACE_FOUNDATION_GIRDER_TOP ...
    && any(idz(:,1)==1)
  [baseline, node, member_column] = ...
    split_column_for_brace_at_girder_top_func(...
      baseline, node, member_column, member_girder);

  % 柱分割後、ブレースの節点を分割点に置き換え
  % 1階K上形とX形が対象
  for i=1:n
    if idz(i,1) == 1 && (brace_type(i) == PRM.BRACE_MEMBER_TYPE_K_UPPER || ...
                         brace_type(i) == PRM.BRACE_MEMBER_TYPE_X)
      % 左柱の分割点を検索
      if pair(i) == PRM.BRACE_MEMBER_PAIR_L || ...
         pair(i) == PRM.BRACE_MEMBER_PAIR_BOTH
        idc_L = find(member_column.idx(:,1) == idx(i,1) & ...
                     member_column.idy(:,1) == idy(i,1) & ...
                     member_column.type == PRM.COLUMN_FOR_BRACE2, 1);
        if ~isempty(idc_L)
          idnode1(i) = member_column.idnode1(idc_L);
        end
      end
      % 右柱の分割点を検索
      if pair(i) == PRM.BRACE_MEMBER_PAIR_R
        idc_R = find(member_column.idx(:,1) == idx(i,2) & ...
                     member_column.idy(:,1) == idy(i,2) & ...
                     member_column.type == PRM.COLUMN_FOR_BRACE2, 1);
        if ~isempty(idc_R)
          idnode1(i) = member_column.idnode1(idc_R);
        end
      end
    end
  end
end

%% 断面変数配列の取得
mvar = PRM.MAX_NSVAR;
idvar = zeros(n,mvar);
for i=1:n
  idvar(i,:) = section_brace.idvar(idsecb(i),:);
end

%% ブレース部材テーブルの作成
cxl = zeros(n,3);
cyl = zeros(n,3);
type = brace_type;
idpair = (1:n)';
member_brace = table(floor_name, frame_name, coord_name, ...
  section_name, section_type, type, pair, idpair, ...
  idstory, idir, idx, idy, idz, idzn, idsecb, idnode1, idnode2, ...
  cxl, cyl, idvar);

%% BOTHペアの展開処理
if any(pair == PRM.BRACE_MEMBER_PAIR_BOTH)
  member_brace = expand_brace_pair_both_func(member_brace);
end

%% 方向余弦の計算（ベクトル化）
n_final = size(member_brace, 1);
an = zeros(n_final, 1);
[member_brace.cyl, member_brace.cxl] = ystar(...
  node.x(member_brace.idnode1), ...
  node.y(member_brace.idnode1), ...
  node.z(member_brace.idnode1), ...
  node.x(member_brace.idnode2), ...
  node.y(member_brace.idnode2), ...
  node.z(member_brace.idnode2), an);

return

  function [baseline, node, member_column] = ...
      split_column_for_brace_at_girder_top_func(...
        baseline, node, member_column, member_girder_arg)
    %% 梁天端接続時の柱分割処理
    % 1階ブレース（X形・K上形）が梁天端に接続する場合、柱を分割して接続節点を作成

    nnode = size(node,1);
    member_girder = member_girder_arg;
    section_girder = com.section.girder;

    % ダミーZ通りの追加（ブレース接合部用）
    baseline.z = [baseline.z; baseline.z(1,:)];
    nz = size(baseline.z,1);
    baseline.z.id(nz) = nz;
    baseline.z.idstory(nz) = nz;
    baseline.z.isdummy(nz) = true;
    baseline.z.idnominal(nz) = 1;
    baseline.z.name(nz) = strcat(baseline.z.name(nz),'-BRACE-JOINT');

    % 対象ブレースの抽出（1階のX形・K上形のみ）
    id_target_brace = find(...
      idz(:,1)==1 & ...
      (brace_type == PRM.BRACE_MEMBER_TYPE_X | ...
       brace_type == PRM.BRACE_MEMBER_TYPE_K_UPPER));
    ntarget = length(id_target_brace);

    % 基礎梁の取得と成（梁天端位置計算用）
    idfg = find_idgirder_from_idxyz(...
      idx(id_target_brace,:), idy(id_target_brace,:), ...
      idz(id_target_brace,[1 1]), member_girder);
    idsfg = member_girder.idsecg(idfg);
    Dtarget = section_girder.dimension(idsfg,2);

    % 対象柱数の計算（K上形は2本、X形は1本）
    n_k_upper = sum(brace_type(id_target_brace) ...
      == PRM.BRACE_MEMBER_TYPE_K_UPPER);
    n_x = ntarget - n_k_upper;
    ncolumn = n_k_upper * 2 + n_x;

    % 配列の事前確保
    iac_all = zeros(ncolumn, 1);
    idnode_template_all = zeros(ncolumn, 1);
    Dtarget_all = zeros(ncolumn, 1);

    icnt = 0;
    for ib=1:ntarget
      tid_ = id_target_brace(ib);
      pair_type = pair(tid_);

      if brace_type(tid_) == PRM.BRACE_MEMBER_TYPE_K_UPPER
        % K上形：左右両方の柱を分割
        iac_L = find_idcolumn_from_idxyz(...
          idx(tid_,[1 1]), idy(tid_,[1 1]), ...
          idz(tid_,:), member_column);
        iac_R = find_idcolumn_from_idxyz(...
          idx(tid_,[2 2]), idy(tid_,[2 2]), ...
          idz(tid_,:), member_column);
        icnt = icnt + 1;
        iac_all(icnt) = iac_L;
        idnode_template_all(icnt) = member_column.idnode1(iac_L);
        Dtarget_all(icnt) = Dtarget(ib);
        icnt = icnt + 1;
        iac_all(icnt) = iac_R;
        idnode_template_all(icnt) = member_column.idnode1(iac_R);
        Dtarget_all(icnt) = Dtarget(ib);
      else
        % X形：ペアに応じた柱のみ分割
        if pair_type == PRM.BRACE_MEMBER_PAIR_L
          iac_L = find_idcolumn_from_idxyz(...
            idx(tid_,[1 1]), idy(tid_,[1 1]), ...
            idz(tid_,:), member_column);
          icnt = icnt + 1;
          iac_all(icnt) = iac_L;
          idnode_template_all(icnt) = member_column.idnode1(iac_L);
          Dtarget_all(icnt) = Dtarget(ib);
        elseif pair_type == PRM.BRACE_MEMBER_PAIR_R
          iac_R = find_idcolumn_from_idxyz(...
            idx(tid_,[2 2]), idy(tid_,[2 2]), ...
            idz(tid_,:), member_column);
          icnt = icnt + 1;
          iac_all(icnt) = iac_R;
          idnode_template_all(icnt) = member_column.idnode1(iac_R);
          Dtarget_all(icnt) = Dtarget(ib);
        end
      end
    end

    % Z座標の計算
    zcoord_all = Dtarget_all / 2;

    % 重複する柱・Z座標の統合（同一位置の節点は1つだけ作成）
    [~, idu2o, ~] = unique([iac_all zcoord_all],'rows','stable');

    if isempty(idu2o)
      error('YLAB:PreprocessError', ...
        '梁天端接続ブレース処理でエラー: 対象節点が見つかりません (ntarget=%d)', ntarget);
    end

    iac = iac_all(idu2o);
    idnode_template = idnode_template_all(idu2o);
    zcoord = zcoord_all(idu2o);

    % 追加節点の作成
    add_node = node(idnode_template,:);
    
    add_node.idz(:) = nz;
    add_node.z = zcoord(:);
    % dzは柱脚節点からコピー
    add_node.dz = node.dz(member_column.idnode1(iac));
    add_node.type(:) = PRM.NODE_BRACE_FOR_COLUMN;
    add_node.zname(:) = baseline.z.name(nz);

    % 柱の分割（下側：BRACE1、上側：BRACE2）
    add_column = member_column(iac,:);
    add_column.type(:) = PRM.COLUMN_FOR_BRACE1;
    add_column.idnode2 = (1:length(iac))' + nnode;
    add_column.idz(:,2) = nz;
    member_column.idnode1(iac) = (1:length(iac))' + nnode;
    member_column.idz(iac,1) = nz;
    member_column.type(iac) = PRM.COLUMN_FOR_BRACE2;

    % 結果の更新
    node = [node; add_node];
    member_column = [member_column; add_column];

    return
  end

  function [idnode_mid_array, baseline, node, member_girder] = ...
      split_girder_for_kbrace_func(...
        baseline, node, member_girder)
    %% K形ブレース用梁分割処理
    % 梁中点に中間節点を作成し、梁を2分割（KBRACE1, KBRACE2）

    nnode = size(node,1);

    % K形ブレース対象の抽出
    iab = find(brace_type == PRM.BRACE_MEMBER_TYPE_K_UPPER | ...
               brace_type == PRM.BRACE_MEMBER_TYPE_K_LOWER);
    na = length(iab);

    % 対象梁の取得と方向の判定
    idg = zeros(na,1);
    girder_idir = zeros(na,1);
    for ia=1:na
      tid = iab(ia);
      % K上形：上階の梁、K下形：下階の梁を取得
      if brace_type(tid) == PRM.BRACE_MEMBER_TYPE_K_UPPER
        idz_girder = idz(tid,[2 2]);  % 上階
      else
        idz_girder = idz(tid,[1 1]);  % 下階
      end
      idg(ia) = find_idgirder_from_idxyz(...
        idx(tid,:), idy(tid,:), idz_girder, ...
        member_girder);
      girder_idir(ia) = member_girder.idir(idg(ia));
    end

    % K形ブレース左右端点節点の取得（親スコープから）
    idnode_k_L_ = idnode_k_L;
    idnode_k_R_ = idnode_k_R;

    % 中間節点座標の計算（梁中点）
    x_mid = (node.x(idnode_k_L_)+node.x(idnode_k_R_))/2;
    y_mid = (node.y(idnode_k_L_)+node.y(idnode_k_R_))/2;
    z_mid = (node.z(idnode_k_L_)+node.z(idnode_k_R_))/2;
    dz_mid = (node.dz(idnode_k_L_)+node.dz(idnode_k_R_))/2;

    % 重複する中間節点の統合（同一位置は1つだけ作成）
    [~, idu2o, ido2u] = unique([idnode_k_L_ idnode_k_R_], 'rows', 'stable');

    % ユニーク梁の方向
    girder_idir_unique = girder_idir(idu2o);

    % 中間節点番号の割り当て
    idnode_mid = (1:length(idu2o))' + nnode;

    % テンプレート節点の取得（通り線上の既存節点）
    ian = idnode_k_L_(idu2o);
    addnode = node(ian,:);

    % 中間節点座標の設定
    addnode.x = x_mid(idu2o);
    addnode.y = y_mid(idu2o);
    addnode.z = z_mid(idu2o);
    addnode.dz = dz_mid(idu2o);

    % 通り線情報の設定とダミー通りの作成
    % 45度梁（PRM.XY）はX方向ダミー通りで代表させる
    for iu=1:length(idu2o)
      tid = iab(idu2o(iu));
      if girder_idir_unique(iu) == PRM.X || girder_idir_unique(iu) == PRM.XY
        % X方向梁・45度梁：X方向にダミー通り追加、Y通りは元のまま
        baseline.x = [baseline.x; baseline.x(idx(tid,1),:)];
        nx = size(baseline.x,1);
        baseline.x.id(nx) = nx;
        baseline.x.isdummy(nx) = true;
        baseline.x.name(nx) = ...
          strcat(baseline.x.name(idx(tid,1)),'-KBRACE-MID');
        addnode.idx(iu) = nx;
        addnode.xname(iu) = baseline.x.name(nx);

        addnode.idy(iu) = idy(tid,1);
        addnode.yname(iu) = baseline.y.name(idy(tid,1));
      else
        % Y方向梁：X通りは元のまま、Y方向にダミー通り追加
        addnode.idx(iu) = idx(tid,1);
        addnode.xname(iu) = baseline.x.name(idx(tid,1));

        baseline.y = [baseline.y; baseline.y(idy(tid,1),:)];
        ny = size(baseline.y,1);
        baseline.y.id(ny) = ny;
        baseline.y.isdummy(ny) = true;
        baseline.y.name(ny) = ...
          strcat(baseline.y.name(idy(tid,1)),'-KBRACE-MID');
        addnode.idy(iu) = ny;
        addnode.yname(iu) = baseline.y.name(ny);
      end

      addnode.zname(iu) = baseline.z.name(addnode.idz(iu));
    end

    addnode.type(:) = PRM.NODE_BRACE_FOR_GIRDER;

    % 梁の分割（元の梁→KBRACE1左側、新規梁→KBRACE2右側）
    idg_unique = idg(idu2o);
    addgirder = member_girder(idg_unique,:);
    addgirder.type = repmat(PRM.GIRDER_FOR_KBRACE2, length(idg_unique), 1);
    addgirder.idnode1 = idnode_mid;

    % 新規梁（KBRACE2、右側）の通り情報を中間節点に合わせる
    for iu=1:length(idu2o)
      if girder_idir_unique(iu) == PRM.X || girder_idir_unique(iu) == PRM.XY
        % X方向梁・45度梁：始点X通りを中間節点のダミー通りに更新
        addgirder.idx(iu,1) = addnode.idx(iu);
        addgirder.coord_name{iu,1} = addnode.xname{iu};
      else
        % Y方向梁：始点Y通りを中間節点のダミー通りに更新
        addgirder.idy(iu,1) = addnode.idy(iu);
        addgirder.coord_name{iu,1} = addnode.yname{iu};
      end
    end

    member_girder.idnode2(idg_unique) = idnode_mid;
    member_girder.type(idg_unique) = PRM.GIRDER_FOR_KBRACE1;

    % 元の梁（KBRACE1、左側）の通り情報を中間節点に合わせる
    for iu=1:length(idu2o)
      ig = idg_unique(iu);
      if girder_idir_unique(iu) == PRM.X || girder_idir_unique(iu) == PRM.XY
        % X方向梁・45度梁：終点X通りを中間節点のダミー通りに更新
        member_girder.idx(ig,2) = addnode.idx(iu);
        member_girder.coord_name{ig,2} = addnode.xname{iu};
      else
        % Y方向梁：終点Y通りを中間節点のダミー通りに更新
        member_girder.idy(ig,2) = addnode.idy(iu);
        member_girder.coord_name{ig,2} = addnode.yname{iu};
      end
    end

    % 中間節点配列の作成（親スコープ配列に格納）
    idnode_mid_array = zeros(n,1);
    idnode_mid_array(iab) = idnode_mid(ido2u);

    % 結果の更新
    node = [node; addnode];
    member_girder = [member_girder; addgirder];

    return
  end

  function tb_out = expand_brace_pair_both_func(tb_in)
    %% BOTHペアの展開処理（テーブルベース）
    % "両方"を左右2本のブレースに展開
    %   K上形→BOTH_L+BOTH_R, K下形→BOTH_R+BOTH_L, X形→BOTH_L+BOTH_R
    expand_idx = find(...
      tb_in.pair == PRM.BRACE_MEMBER_PAIR_BOTH);

    if isempty(expand_idx)
      tb_out = tb_in;
      return
    end

    % 展開対象のブレースタイプと中間節点配列を事前取得
    brace_type_expand = brace_type(expand_idx);
    idnode_mid_array_expand = idnode_mid_array(expand_idx);

    % 元のテーブルのペアを更新（K上形→BOTH_L、K下形→BOTH_R、X形→BOTH_L）
    for ie = 1:length(expand_idx)
      if brace_type_expand(ie) == ...
          PRM.BRACE_MEMBER_TYPE_K_UPPER
        % K上形は左側がBOTH_L（下柱→中間）
        tb_in.pair(expand_idx(ie)) = ...
          PRM.BRACE_MEMBER_PAIR_BOTH_L;
      elseif brace_type_expand(ie) == ...
          PRM.BRACE_MEMBER_TYPE_K_LOWER
        % K下形は左側がBOTH_R（上柱→中間、逆V字）
        tb_in.pair(expand_idx(ie)) = ...
          PRM.BRACE_MEMBER_PAIR_BOTH_R;
      else
        % X形は左側がBOTH_L（通常の対角）
        tb_in.pair(expand_idx(ie)) = ...
          PRM.BRACE_MEMBER_PAIR_BOTH_L;
      end
    end

    % 追加する右側ブレースのテーブル作成
    tb_add = tb_in(expand_idx,:);
    ntb_add = numel(expand_idx);
    tb_in.idpair(expand_idx) = (n + (1:ntb_add))';

    % 追加ブレースの節点接続処理
    for ie = 1:ntb_add
      % K上形の場合
      if brace_type_expand(ie) == ...
          PRM.BRACE_MEMBER_TYPE_K_UPPER
        % 右側：中間→上側節点（BOTH_R）
        tb_add.pair(ie) = PRM.BRACE_MEMBER_PAIR_BOTH_R;
        idnode_mid_ = idnode_mid_array_expand(ie);
        tb_add.idnode1(ie) = idnode_mid_;
        % idnode_k_Rを上端に持つ柱の下端を取得
        idc_right = find(member_column.idnode2 == idnode_k_R(ie), 1);
        if ~isempty(idc_right)
          tb_add.idnode2(ie) = member_column.idnode1(idc_right);
        else
          tb_add.idnode2(ie) = idnode_k_R(ie);
        end

      % K下形の場合
      elseif brace_type_expand(ie) == ...
          PRM.BRACE_MEMBER_TYPE_K_LOWER
        % 右側：中間→下柱（BOTH_L）
        tb_add.pair(ie) = PRM.BRACE_MEMBER_PAIR_BOTH_L;
        idnode_mid_ = idnode_mid_array_expand(ie);
        tb_add.idnode1(ie) = idnode_mid_;
        tb_add.idnode2(ie) = find_idnode_from_idxyz(...
          tb_add.idx(ie,2), tb_add.idy(ie,2), ...
          tb_add.idz(ie,2), node);

      % X形の場合
      else
        % 右側：右上→左下（BOTH_R）
        tb_add.pair(ie) = PRM.BRACE_MEMBER_PAIR_BOTH_R;
        tb_add.idnode1(ie) = find_idnode_from_idxyz(...
          tb_add.idx(ie,2), tb_add.idy(ie,2), ...
          tb_add.idz(ie,1), node);
        tb_add.idnode2(ie) = find_idnode_from_idxyz(...
          tb_add.idx(ie,1), tb_add.idy(ie,1), ...
          tb_add.idz(ie,1), node);
      end
    end

    % 元のテーブルと追加テーブルを結合
    tb_out = [tb_in; tb_add];
  end

  function [idnode_L, idnode_R, idnode_L_far, idnode_R_far] = ...
      get_kbrace_endpoint_nodes(ib, node_data)
    % K形ブレース端点節点番号の取得
    % 梁側端点と反対側端点（柱脚/柱頭）の4節点を返す

    n_brace = length(ib);
    id_k_upper = ...
      (brace_type(ib) == PRM.BRACE_MEMBER_TYPE_K_UPPER);

    % 梁側端点（中間節点がある階）
    idz_for_endpoint = zeros(n_brace,1);
    idz_for_endpoint(id_k_upper) = idz(ib(id_k_upper),2);  % K上形：上階
    idz_for_endpoint(~id_k_upper) = idz(ib(~id_k_upper),1); % K下形：下階
    idnode_L = find_idnode_from_idxyz(...
      idx(ib,1), idy(ib,1), idz_for_endpoint, node_data);
    idnode_R = find_idnode_from_idxyz(...
      idx(ib,2), idy(ib,2), idz_for_endpoint, node_data);

    % 反対側端点（柱脚/柱頭）
    idz_for_far = zeros(n_brace,1);
    idz_for_far(id_k_upper) = idz(ib(id_k_upper),1);   % K上形：下階
    idz_for_far(~id_k_upper) = idz(ib(~id_k_upper),2);  % K下形：上階
    idnode_L_far = find_idnode_from_idxyz(...
      idx(ib,1), idy(ib,1), idz_for_far, node_data);
    idnode_R_far = find_idnode_from_idxyz(...
      idx(ib,2), idy(ib,2), idz_for_far, node_data);
  end
end
