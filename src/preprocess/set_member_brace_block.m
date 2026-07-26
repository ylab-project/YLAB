function [member_brace, baseline, node, member_column, member_girder] = ...
  set_member_brace_block(dbc, com, options)
%set_member_brace_block - ブレース配置データの読み込みと処理
%
%   [member_brace, baseline, node, member_column, ...
%     member_girder] = ...
%     set_member_brace_block(dbc, com, options) は、
%   鉛直ブレース配置データを読み込み、ブレース部材テーブルを
%   作成する。K形ブレースの梁分割、梁天端接続時の柱分割、
%   BOTHペアの展開処理も行う。
%
%   入力引数:
%     dbc     - データブロックコントローラ
%     com     - 共通データ構造体
%     options - オプション設定
%
%   出力引数:
%     member_brace  - ブレース部材テーブル
%     baseline      - 更新された通り線データ
%     node          - 更新された節点データ
%     member_column - 更新された柱部材データ
%     member_girder - 更新された梁部材データ

data = dbc.get_data_block('鉛直ブレース配置');
n = size(data,1);

% 共通データの取得
section_brace = com.section.brace;
baseline = com.baseline;
span = com.span;
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

%% ペアの解析（形状と組み合わせて pair 定数を決定）
% SS7の「片(左)/片(右)/両方」は物理位置ベース。YLAB 内部の pair は
% 傾き方向ベース。形状により読み替えが必要（K下は左右反転）。
% pair_map: 行=brace_type (1:X, 2:K上, 3:K下), 列=side (1:左, 2:右)
pair_map = [PRM.BRACE_MEMBER_PAIR_L, PRM.BRACE_MEMBER_PAIR_R; ...
  PRM.BRACE_MEMBER_PAIR_BOTH_L, PRM.BRACE_MEMBER_PAIR_BOTH_R; ...
  PRM.BRACE_MEMBER_PAIR_BOTH_R, PRM.BRACE_MEMBER_PAIR_BOTH_L];
pair = zeros(n,1);
for i=1:n
  val = data{i,7};
  if ismissing(val)
    continue
  end
  switch val
    case "片(左)"
      pair(i) = pair_map(brace_type(i), 1);
    case "片(右)"
      pair(i) = pair_map(brace_type(i), 2);
    case "両方"
      pair(i) = PRM.BRACE_MEMBER_PAIR_BOTH;
  end
end

%% 通し（階方向）の解析
through_floor = zeros(n,1);
if size(data, 2) >= 10
  for i = 1:n
    val = data{i,10};
    if ismissing(string(val))
      continue
    end
    if val == "自動"
      through_floor(i) = PRM.BRACE_THROUGH_AUTO;
    end
  end
end

%% 階番号の取得
idstory = zeros(n,1); idds = 1:com.nstory;
for i=1:n
  idstory(i) = idds(matches(com.story.floor_name, floor_name{i}));
end

% 通り番号・方向の取得
[idx, idy, idz, idir, idzn] = find_idxyz_brace(floor_name, ...
  frame_name, coord_name, com.baseline, com.story);

% 断面番号の取得
idsecb = zeros(n,1); iddd = 1:com.nsecb;
for i=1:n
  id = iddd(matches(section_brace.name, section_name{i}));
  idsecb(i) = id;
end

% 断面タイプの取得
section_type = section_brace.type(idsecb);

%% 多層ブレース判定（通し=自動）
nz_max = size(baseline.z, 1);
for i = 1:n
  if through_floor(i) ~= PRM.BRACE_THROUGH_AUTO
    continue
  end
  % 上方向に走査し梁がなければ延長する。idz(i,2) は X/K上/K下
  % のいずれも多層spanの上端なので形状で分岐しない。
  while idz(i,2) < nz_max
    idg_ = find_idgirder_from_idxyz(idx(i,:), idy(i,:), ...
      idz(i,[2 2]), member_girder, [], baseline);
    if any(idg_ > 0)
      break
    end
    idz(i,2) = idz(i,2) + 1;
  end
  idzn(i,2) = baseline.z.idnominal(idz(i,2));
end

% K形ブレース中間節点配列の初期化
idnode_mid_array = zeros(n,1);

% K形ブレース端点節点の事前計算
id_k_brace = find(brace_type == PRM.BRACE_MEMBER_TYPE_K_UPPER | ...
                  brace_type == PRM.BRACE_MEMBER_TYPE_K_LOWER);
idnode_k_R_far_src = zeros(n, 1);
if ~isempty(id_k_brace)
  % K形ブレース端点節点番号を一括取得（梁側と反対側の4節点）
  [idnode_k_L, idnode_k_R, idnode_k_L_far, idnode_k_R_far] = ...
    get_kbrace_endpoint_nodes(id_k_brace, node);
  idnode_k_R_far_src(id_k_brace) = idnode_k_R_far;
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

    % 反対側端点（K上形：下階柱脚、K下形：上階柱頭）
    idnode_L_far_ = idnode_k_L_far(ik);
    idnode_R_far_ = idnode_k_R_far(ik);

    % ペアに応じた節点割り当て
    % idnode1 は常に下、idnode2 は常に上とする:
    %   K上: far=下柱脚, mid=上梁中央 → idnode1=far, idnode2=mid
    %   K下: far=上柱頭, mid=下梁中央 → idnode1=mid, idnode2=far
    % 左右の選択（BOTH_L/BOTH_R）は shape と pair で決定:
    %   K上 BOTH_L=左(L_far), BOTH_R=右(R_far)
    %   K下 BOTH_L=右(R_far), BOTH_R=左(L_far)
    is_k_lower_ = brace_type(i) == PRM.BRACE_MEMBER_TYPE_K_LOWER;
    switch pair(i)
      case PRM.BRACE_MEMBER_PAIR_BOTH_L
        if is_k_lower_
          idnode1(i) = idnode_mid;
          idnode2(i) = idnode_R_far_;
        else
          idnode1(i) = idnode_L_far_;
          idnode2(i) = idnode_mid;
        end
      case PRM.BRACE_MEMBER_PAIR_BOTH_R
        if is_k_lower_
          idnode1(i) = idnode_mid;
          idnode2(i) = idnode_L_far_;
        else
          idnode1(i) = idnode_R_far_;
          idnode2(i) = idnode_mid;
        end
      case PRM.BRACE_MEMBER_PAIR_BOTH
        % BOTH展開前は左側を設定（expand_brace_pair_both_func で
        % K上→BOTH_L、K下→BOTH_R に対応）
        if is_k_lower_
          idnode1(i) = idnode_mid;
          idnode2(i) = idnode_L_far_;
        else
          idnode1(i) = idnode_L_far_;
          idnode2(i) = idnode_mid;
        end
    end
  end
end

%% X形ブレースの節点接続処理
for i=1:n
  if brace_type(i) == PRM.BRACE_MEMBER_TYPE_X
    % X形は通常の対角接続
    switch pair(i)
      case PRM.BRACE_MEMBER_PAIR_L
        idnode1(i) = find_idnode_from_idxyz(idx(i,1), ...
          idy(i,1), idz(i,1), node);
        idnode2(i) = find_idnode_from_idxyz(idx(i,2), ...
          idy(i,2), idz(i,2), node);
      case PRM.BRACE_MEMBER_PAIR_R
        idnode1(i) = find_idnode_from_idxyz(idx(i,2), ...
          idy(i,2), idz(i,1), node);
        idnode2(i) = find_idnode_from_idxyz(idx(i,1), ...
          idy(i,1), idz(i,2), node);
      case PRM.BRACE_MEMBER_PAIR_BOTH
        % BOTH展開前は左側のみ設定
        idnode1(i) = find_idnode_from_idxyz(idx(i,1), ...
          idy(i,1), idz(i,1), node);
        idnode2(i) = find_idnode_from_idxyz(idx(i,2), ...
          idy(i,2), idz(i,2), node);
    end
  end
end

%% 梁天端接続時の柱分割処理
pos_brace_fg = options.position_brace_foundation_girder;
if pos_brace_fg == PRM.BRACE_FOUNDATION_GIRDER_TOP && any(idz(:,1)==1 ...
    & (brace_type == PRM.BRACE_MEMBER_TYPE_X ...
    | brace_type == PRM.BRACE_MEMBER_TYPE_K_UPPER))
  [baseline, node, member_column] = ...
    split_column_for_brace_at_girder_top_func(baseline, node, ...
      member_column, member_girder);

  % 柱分割後、ブレースの idnode1（下端）を分割点に置き換え
  % idnode1 は常に下端なので、K上/X形 ともに idnode1 を置換するだけでよい
  for i=1:n
    if idz(i,1) == 1 ...
        && (brace_type(i) == PRM.BRACE_MEMBER_TYPE_K_UPPER ...
        || brace_type(i) == PRM.BRACE_MEMBER_TYPE_X)
      % 左側物理位置: X形 PAIR_L, K上 BOTH_L, BOTH（未展開）
      is_left_pos = pair(i) == PRM.BRACE_MEMBER_PAIR_L ...
        || pair(i) == PRM.BRACE_MEMBER_PAIR_BOTH_L ...
        || pair(i) == PRM.BRACE_MEMBER_PAIR_BOTH;
      if is_left_pos
        idc_L = find(member_column.idx(:,1) == idx(i,1) & ...
                     member_column.idy(:,1) == idy(i,1) & ...
                     member_column.type == PRM.COLUMN_FOR_BRACE_BODY, 1);
        if ~isempty(idc_L)
          idnode1(i) = member_column.idnode1(idc_L);
        end
      end
      % 右側物理位置: X形 PAIR_R, K上 BOTH_R
      if pair(i) == PRM.BRACE_MEMBER_PAIR_R ...
          || pair(i) == PRM.BRACE_MEMBER_PAIR_BOTH_R
        idc_R = find(member_column.idx(:,1) == idx(i,2) ...
          & member_column.idy(:,1) == idy(i,2) ...
          & member_column.type == PRM.COLUMN_FOR_BRACE_BODY, 1);
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

%% 基礎梁接続フラグの設定
onfg = false(n, 2);
for i = 1:n
  % 端点1側（下端）の接続梁を検索
  idg_ = find_idgirder_from_idxyz(idx(i,:), idy(i,:), ...
    idz(i,[1 1]), member_girder, [], baseline);
  idg_ = idg_(idg_ > 0);
  for k = 1:length(idg_)
    if member_girder.isfg(idg_(k))
      onfg(i,1) = true; break
    end
  end
  % 端点2側（上端）の接続梁を検索
  idg_ = find_idgirder_from_idxyz(idx(i,:), idy(i,:), ...
    idz(i,[2 2]), member_girder, [], baseline);
  idg_ = idg_(idg_ > 0);
  for k = 1:length(idg_)
    if member_girder.isfg(idg_(k))
      onfg(i,2) = true; break
    end
  end
end

%% ブレース部材テーブルの作成
cxl = zeros(n,3);
cyl = zeros(n,3);
type = brace_type;
idpair = (1:n)';
member_brace = table(floor_name, frame_name, coord_name, ...
  section_name, section_type, type, pair, idpair, idstory, ...
  idir, idx, idy, idz, idzn, idsecb, idnode1, idnode2, onfg, ...
  cxl, cyl, idvar, through_floor);

%% BOTHペアの展開処理
if any(pair == PRM.BRACE_MEMBER_PAIR_BOTH)
  member_brace = expand_brace_pair_both_func(member_brace);

  % BOTH_R展開後の柱分割点への節点置換（1階X形）
  if pos_brace_fg == PRM.BRACE_FOUNDATION_GIRDER_TOP
    nb_ = size(member_brace, 1);
    for ib_ = 1:nb_
      if member_brace.idz(ib_,1) ~= 1
        continue
      end
      if member_brace.type(ib_) ~= PRM.BRACE_MEMBER_TYPE_X
        continue
      end
      if member_brace.pair(ib_) ~= PRM.BRACE_MEMBER_PAIR_R
        continue
      end
      % PAIR_R（X形右側対角）のidnode1（下端）を右柱分割点に置換
      idc_ = find(member_column.idx(:,1) == member_brace.idx(ib_,2) ...
        & member_column.idy(:,1) == member_brace.idy(ib_,2) ...
        & member_column.type == PRM.COLUMN_FOR_BRACE_BODY, 1);
      if ~isempty(idc_)
        member_brace.idnode1(ib_) = member_column.idnode1(idc_);
      end
    end
  end
end

return

  function [baseline, node, member_column] = ...
      split_column_for_brace_at_girder_top_func(baseline, node, ...
        member_column, member_girder_arg)
    %split_column_for_brace_at_girder_top_func - 梁天端接続時の柱分割
    %
    %   [baseline, node, member_column] = ...
    %     split_column_for_brace_at_girder_top_func(
    %       baseline, node, member_column, ...
    %       member_girder_arg) は、
    %   1階ブレース（X形・K上形）が梁天端に接続する場合、
    %   柱を分割して接続節点を作成する。
    %
    %   入力引数:
    %     baseline         - 通り線データ
    %     node             - 節点データ
    %     member_column    - 柱部材データ
    %     member_girder_arg - 梁部材データ
    %
    %   出力引数:
    %     baseline      - 更新された通り線データ
    %     node          - 更新された節点データ
    %     member_column - 更新された柱部材データ

    nnode = size(node,1);
    member_girder = member_girder_arg;
    % ダミーZ通りの追加（ブレース接合部用）
    baseline.z = [baseline.z; baseline.z(1,:)];
    nz = size(baseline.z,1);
    baseline.z.id(nz) = nz;
    baseline.z.idstory(nz) = nz;
    baseline.z.isdummy(nz) = true;
    baseline.z.idnominal(nz) = 1;
    baseline.z.name(nz) = strcat(baseline.z.name(nz),'-BRACE-JOINT');

    % 対象ブレースの抽出（1階のX形・K上形のみ）
    id_target_brace = find(idz(:,1)==1 ...
      & (brace_type == PRM.BRACE_MEMBER_TYPE_X ...
      | brace_type == PRM.BRACE_MEMBER_TYPE_K_UPPER));
    ntarget = length(id_target_brace);

    % 追加節点が取り付く基礎梁を保持する
    idfg = find_idgirder_from_idxyz(idx(id_target_brace,:), ...
      idy(id_target_brace,:), idz(id_target_brace,[1 1]), ...
      member_girder, [], baseline);
    % 配列の事前確保（各ブレース最大2柱を上界として確保し末尾で切詰）
    iac_all = zeros(ntarget*2, 1);
    idnode_template_all = zeros(ntarget*2, 1);
    idfg_all = zeros(ntarget*2, 1);
    idz_target_all = zeros(ntarget*2, 1);

    icnt = 0;
    for ib=1:ntarget
      tid_ = id_target_brace(ib);
      pair_type = pair(tid_);

      if brace_type(tid_) == PRM.BRACE_MEMBER_TYPE_K_UPPER
        % K上形：pairに応じて分割対象の柱を決定（SS7整合）
        % 左柱分割: BOTH_L（片(左)）または BOTH（両方）
        if pair_type == PRM.BRACE_MEMBER_PAIR_BOTH_L ...
            || pair_type == PRM.BRACE_MEMBER_PAIR_BOTH
          iac_L = find_idcolumn_from_idxyz(idx(tid_,[1 1]), ...
            idy(tid_,[1 1]), [idz(tid_,1), idz(tid_,1)+1], member_column);
          icnt = icnt + 1;
          iac_all(icnt) = iac_L;
          idnode_template_all(icnt) = member_column.idnode1(iac_L);
          idfg_all(icnt) = idfg(ib);
          idz_target_all(icnt) = idz(tid_, 1);
        end
        % 右柱分割: BOTH_R（片(右)）または BOTH（両方）
        if pair_type == PRM.BRACE_MEMBER_PAIR_BOTH_R ...
            || pair_type == PRM.BRACE_MEMBER_PAIR_BOTH
          iac_R = find_idcolumn_from_idxyz(idx(tid_,[2 2]), ...
            idy(tid_,[2 2]), [idz(tid_,1), idz(tid_,1)+1], member_column);
          icnt = icnt + 1;
          iac_all(icnt) = iac_R;
          idnode_template_all(icnt) = member_column.idnode1(iac_R);
          idfg_all(icnt) = idfg(ib);
          idz_target_all(icnt) = idz(tid_, 1);
        end
      else
        % X形：ペアに応じた柱を分割
        if pair_type == PRM.BRACE_MEMBER_PAIR_L
          iac_L = find_idcolumn_from_idxyz(idx(tid_,[1 1]), ...
            idy(tid_,[1 1]), [idz(tid_,1), idz(tid_,1)+1], member_column);
          icnt = icnt + 1;
          iac_all(icnt) = iac_L;
          idnode_template_all(icnt) = member_column.idnode1(iac_L);
          idfg_all(icnt) = idfg(ib);
          idz_target_all(icnt) = idz(tid_, 1);
        elseif pair_type == PRM.BRACE_MEMBER_PAIR_R
          iac_R = find_idcolumn_from_idxyz(idx(tid_,[2 2]), ...
            idy(tid_,[2 2]), [idz(tid_,1), idz(tid_,1)+1], member_column);
          icnt = icnt + 1;
          iac_all(icnt) = iac_R;
          idnode_template_all(icnt) = member_column.idnode1(iac_R);
          idfg_all(icnt) = idfg(ib);
          idz_target_all(icnt) = idz(tid_, 1);
        elseif pair_type == PRM.BRACE_MEMBER_PAIR_BOTH
          % BOTH：左右両方の柱を分割
          iac_L = find_idcolumn_from_idxyz(idx(tid_,[1 1]), ...
            idy(tid_,[1 1]), [idz(tid_,1), idz(tid_,1)+1], member_column);
          iac_R = find_idcolumn_from_idxyz(idx(tid_,[2 2]), ...
            idy(tid_,[2 2]), [idz(tid_,1), idz(tid_,1)+1], member_column);
          icnt = icnt + 1;
          iac_all(icnt) = iac_L;
          idnode_template_all(icnt) = member_column.idnode1(iac_L);
          idfg_all(icnt) = idfg(ib);
          idz_target_all(icnt) = idz(tid_, 1);
          icnt = icnt + 1;
          iac_all(icnt) = iac_R;
          idnode_template_all(icnt) = member_column.idnode1(iac_R);
          idfg_all(icnt) = idfg(ib);
          idz_target_all(icnt) = idz(tid_, 1);
        end
      end
    end

    % 使用分に切詰
    iac_all = iac_all(1:icnt);
    idnode_template_all = idnode_template_all(1:icnt);
    idfg_all = idfg_all(1:icnt);
    idz_target_all = idz_target_all(1:icnt);

    % Z座標の計算
    zcoord_all = member_girder.level(idfg_all);

    % 重複する柱・Z座標の統合（同一位置の節点は1つだけ作成）
    [~, idu2o, ~] = unique([iac_all zcoord_all],'rows','stable');

    if isempty(idu2o)
      return
    end

    iac = iac_all(idu2o);
    idnode_template = idnode_template_all(idu2o);
    zcoord = zcoord_all(idu2o);
    idfg_brace_top = idfg_all(idu2o);
    idz_brace_top = idz_target_all(idu2o);


    % 追加節点の作成
    add_node = node(idnode_template,:);
    add_node.idz(:) = nz;
    % dzは柱脚節点からコピー
    add_node.dz = node.dz(member_column.idnode1(iac));
    add_node.idfg_brace_top = idfg_brace_top;
    add_node.idz_brace_top = idz_brace_top;
    zstandard = baseline.z.coord_standard(idz_brace_top);
    add_node.z = zstandard + add_node.dz + zcoord(:);
    add_node.z_standard = zstandard + add_node.dz;
    add_node.type(:) = PRM.NODE_BRACE_FOR_COLUMN;
    add_node.zname(:) = baseline.z.name(nz);

    % 柱の分割（下側：FOUNDATION、上側：BODY）
    add_column = member_column(iac,:);
    add_column.type(:) = PRM.COLUMN_FOR_BRACE_FOUNDATION;
    add_column.idnode2 = (1:length(iac))' + nnode;
    add_column.idz(:,2) = nz;
    member_column.idnode1(iac) = (1:length(iac))' + nnode;
    member_column.idz(iac,1) = nz;
    member_column.type(iac) = PRM.COLUMN_FOR_BRACE_BODY;

    % 結果の更新
    node = [node; add_node];
    member_column = [member_column; add_column];

    return
  end

  function [idnode_mid_array, baseline, node, member_girder] = ...
      split_girder_for_kbrace_func(baseline, node, member_girder)
    %split_girder_for_kbrace_func - K形ブレース用梁分割処理
    %
    %   [idnode_mid_array, baseline, node, ...
    %     member_girder] = ...
    %     split_girder_for_kbrace_func(
    %       baseline, node, member_girder) は、
    %   K形ブレースの中間節点を確保する。梁中点位置に既存節点があれば
    %   それを採用し、なければ中間節点を新規生成して梁を2分割する。
    %
    %   入力引数:
    %     baseline      - 通り線データ
    %     node          - 節点データ
    %     member_girder - 梁部材データ
    %
    %   出力引数:
    %     idnode_mid_array - K形ブレース中間節点番号 [n x 1]
    %     baseline         - 更新された通り線データ
    %     node             - 更新された節点データ
    %     member_girder    - 更新された梁部材データ

    nnode = size(node,1);

    % K形ブレース対象の抽出
    iab = find(brace_type == PRM.BRACE_MEMBER_TYPE_K_UPPER | ...
               brace_type == PRM.BRACE_MEMBER_TYPE_K_LOWER);
    na = length(iab);

    % 中間節点配列の事前確保（既存節点採用分・新規生成分を統合）
    idnode_mid_array = zeros(n,1);

    % K形中央位置は標準座標で判定する。採用後の解析座標は、
    % 既存の node.x/y/z をそのまま使う。
    coord_std = calc_baseline_coord_std(span);
    cx_std = coord_std.x;
    cy_std = coord_std.y;
    match_tol = 1;

    % K形中央の標準座標（全K形ブレース分）
    x_mid_std_all = (cx_std(idx(iab,1)) + cx_std(idx(iab,2))) / 2;
    y_mid_std_all = (cy_std(idy(iab,1)) + cy_std(idy(iab,2))) / 2;

    % 節点の標準座標（通りに載らない節点は NaN で比較対象外）
    node_x_std = nan(size(node.idx));
    node_y_std = nan(size(node.idy));
    valid_x = node.idx > 0 & node.idx <= length(cx_std);
    valid_y = node.idy > 0 & node.idy <= length(cy_std);
    node_x_std(valid_x) = cx_std(node.idx(valid_x));
    node_y_std(valid_y) = cy_std(node.idy(valid_y));
    is_active_node = node.idrep == 0 & node.type ~= PRM.NODE_ABSORBED;

    % 中点位置に既存節点があるブレースを先行判定する
    for ia=1:na
      tid = iab(ia);
      z_mid = (node.z(idnode_k_L(ia)) + node.z(idnode_k_R(ia))) / 2;
      if brace_type(tid) == PRM.BRACE_MEMBER_TYPE_K_UPPER
        idz_mid = idz(tid,2);
      else
        idz_mid = idz(tid,1);
      end
      in = find(is_active_node & node.idz == idz_mid ...
        & abs(node_x_std - x_mid_std_all(ia)) <= match_tol ...
        & abs(node_y_std - y_mid_std_all(ia)) <= match_tol ...
        & abs(node.z - z_mid) <= match_tol, 1);
      if ~isempty(in)
        idnode_mid_array(tid) = in;
      end
    end

    % 新規中間節点が必要なブレースのみ抽出。全て既存節点で
    % カバーされる場合は以降の処理を行わずに戻る。
    ia_new = find(idnode_mid_array(iab) == 0);
    if isempty(ia_new)
      return
    end
    iab_new = iab(ia_new);
    na_new = length(iab_new);

    % 対象梁の取得と方向の判定（新規生成対象のみ）
    idg = zeros(na_new,1);
    girder_idir = zeros(na_new,1);
    for ia=1:na_new
      tid = iab_new(ia);
      % K上形：上階の梁、K下形：下階の梁を取得
      if brace_type(tid) == PRM.BRACE_MEMBER_TYPE_K_UPPER
        idz_girder = idz(tid,[2 2]);  % 上階
      else
        idz_girder = idz(tid,[1 1]);  % 下階
      end
      idg_ = find_idgirder_from_idxyz(idx(tid,:), idy(tid,:), ...
        idz_girder, member_girder, [], baseline);
      if numel(idg_) ~= 1 || idg_ <= 0
        error('K形ブレース対象梁を一意に特定できません。');
      end
      idg(ia) = idg_;
      girder_idir(ia) = member_girder.idir(idg(ia));
    end

    % K形ブレース左右端点節点の取得（新規生成対象のみ）
    idnode_k_L_ = idnode_k_L(ia_new);
    idnode_k_R_ = idnode_k_R(ia_new);

    % 中間節点の解析座標を標準位置から補間する。
    [x_mid, y_mid, z_mid, dz_mid, zs_mid] = ...
      calc_kbrace_mid_node_coord(idnode_k_L_, idnode_k_R_, ...
      girder_idir, x_mid_std_all(ia_new), y_mid_std_all(ia_new), ...
      node);

    % 重複する中間節点の統合（同一位置は1つだけ作成）
    [~, idu2o, ido2u] = unique([idnode_k_L_ idnode_k_R_], ...
      'rows', 'stable');

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
    addnode.z_standard = zs_mid(idu2o);
    addnode.dz = dz_mid(idu2o);

    % 通り線情報の設定とダミー通りの作成
    for iu=1:length(idu2o)
      tid = iab_new(idu2o(iu));
      if girder_idir_unique(iu) == PRM.X
        % X方向梁：X方向にダミー通り追加
        baseline.x = [baseline.x; baseline.x(idx(tid,1),:)];
        nx = size(baseline.x,1);
        baseline.x.id(nx) = nx;
        baseline.x.isdummy(nx) = true;
        baseline.x.name(nx) = strcat(baseline.x.name(idx(tid,1)), ...
          '-KBRACE-MID');
        baseline.x.coord(nx) = addnode.x(iu);
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
        baseline.y.name(ny) = strcat(baseline.y.name(idy(tid,1)), ...
          '-KBRACE-MID');
        baseline.y.coord(ny) = addnode.y(iu);
        addnode.idy(iu) = ny;
        addnode.yname(iu) = baseline.y.name(ny);
      end

      addnode.zname(iu) = baseline.z.name(addnode.idz(iu));
    end

    addnode.type(:) = PRM.NODE_BRACE_FOR_GIRDER;

    % 分割梁兄弟ポインタの初期化（既存梁は全て0）
    member_girder.idsplit = zeros(size(member_girder,1), 1);

    % 梁の分割（元の梁→KBRACE1左側、新規梁→KBRACE2右側）
    idg_unique = idg(idu2o);
    addgirder = member_girder(idg_unique,:);
    addgirder.type = repmat(PRM.GIRDER_FOR_KBRACE2, length(idg_unique), 1);
    addgirder.idnode1 = idnode_mid;

    % 新規梁（KBRACE2、右側）の通り情報を中間節点に合わせる
    for iu=1:length(idu2o)
      if girder_idir_unique(iu) == PRM.X
        % X方向梁：始点X通りをダミー通りに更新
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
      if girder_idir_unique(iu) == PRM.X
        % X方向梁：終点X通りをダミー通りに更新
        member_girder.idx(ig,2) = addnode.idx(iu);
        member_girder.coord_name{ig,2} = addnode.xname{iu};
      else
        % Y方向梁：終点Y通りを中間節点のダミー通りに更新
        member_girder.idy(ig,2) = addnode.idy(iu);
        member_girder.coord_name{ig,2} = addnode.yname{iu};
      end
    end

    % 既存節点採用分は冒頭で設定済み、新規生成分のみ追加で代入
    idnode_mid_array(iab_new) = idnode_mid(ido2u);

    % 分割梁兄弟ポインタのセット
    nmg_orig = size(member_girder, 1);
    member_girder.idsplit(idg_unique) = nmg_orig + (1:length(idg_unique))';
    addgirder.idsplit = idg_unique;

    % 結果の更新
    node = [node; addnode];
    member_girder = [member_girder; addgirder];

    % 梁の追加でH形梁の連番が変わるため、変換表を作り直す。
    % set_member_girder_block で設定された値は分割前のもの。
    is_wfs_ = member_girder.section_type == PRM.WFS;
    idmewfs_ = zeros(size(member_girder,1),1);
    idmewfs_(is_wfs_) = 1:sum(is_wfs_);
    member_girder.idmewfs = idmewfs_;

    return
  end

  function [x_mid, y_mid, z_mid, dz_mid, zs_mid] = ...
      calc_kbrace_mid_node_coord(idnode_left, idnode_right, ...
      girder_idir_list, x_mid_std, y_mid_std, node_data)
    %calc_kbrace_mid_node_coord - K形中間節点の解析座標を補間

    n_mid = length(idnode_left);
    x_mid = zeros(n_mid,1);
    y_mid = zeros(n_mid,1);
    z_mid = zeros(n_mid,1);
    dz_mid = zeros(n_mid,1);
    zs_mid = zeros(n_mid,1);
    zero_tol = 1e-9;
    t_tol = 1e-9;

    for i_mid=1:n_mid
      nL = idnode_left(i_mid);
      nR = idnode_right(i_mid);
      if girder_idir_list(i_mid) == PRM.X
        p_std = x_mid_std(i_mid);
        a_struct = node_data.x(nL);
        b_struct = node_data.x(nR);
      else
        p_std = y_mid_std(i_mid);
        a_struct = node_data.y(nL);
        b_struct = node_data.y(nR);
      end
      denom = b_struct - a_struct;
      if abs(denom) <= zero_tol
        error('K形ブレース中間節点の補間軸長がゼロです。');
      end
      t = (p_std - a_struct) / denom;
      if t < -t_tol || t > 1 + t_tol
        error('K形ブレース中間節点が対象梁範囲外です。');
      end
      lerp = @(a, b) a + t*(b - a);
      x_mid(i_mid) = lerp(node_data.x(nL), node_data.x(nR));
      y_mid(i_mid) = lerp(node_data.y(nL), node_data.y(nR));
      z_mid(i_mid) = lerp(node_data.z(nL), node_data.z(nR));
      dz_mid(i_mid) = lerp(node_data.dz(nL), node_data.dz(nR));
      zs_mid(i_mid) = lerp(node_data.z_standard(nL), ...
        node_data.z_standard(nR));
    end

    return
  end

  function tb_out = expand_brace_pair_both_func(tb_in)
    %expand_brace_pair_both_func - BOTHペアの展開処理
    %
    %   tb_out = expand_brace_pair_both_func(tb_in) は、
    %   ペアが"両方"のブレースを左右2本に展開する。
    %   K上形は BOTH_L+BOTH_R、K下形は BOTH_R+BOTH_L、
    %   X形は PAIR_L+PAIR_R に展開する。
    %
    %   入力引数:
    %     tb_in  - ブレース部材テーブル
    %
    %   出力引数:
    %     tb_out - 展開後のブレース部材テーブル

    expand_idx = find(tb_in.pair == PRM.BRACE_MEMBER_PAIR_BOTH);

    if isempty(expand_idx)
      tb_out = tb_in;
      return
    end

    % 展開対象のブレースタイプと中間節点配列を事前取得
    brace_type_expand = brace_type(expand_idx);
    idnode_mid_array_expand = idnode_mid_array(expand_idx);

    % 元のテーブルのペアを更新（K形はBOTH_L/R、X形はPAIR_L/R）
    for ie = 1:length(expand_idx)
      if brace_type_expand(ie) == PRM.BRACE_MEMBER_TYPE_K_UPPER
        % K上形は左側がBOTH_L（下柱→中間、／）
        tb_in.pair(expand_idx(ie)) = PRM.BRACE_MEMBER_PAIR_BOTH_L;
      elseif brace_type_expand(ie) == PRM.BRACE_MEMBER_TYPE_K_LOWER
        % K下形は左側がBOTH_R（中間→上柱頭(L_far)、＼）
        tb_in.pair(expand_idx(ie)) = PRM.BRACE_MEMBER_PAIR_BOTH_R;
      else
        % X形は左側がPAIR_L（通常の対角、／）
        tb_in.pair(expand_idx(ie)) = PRM.BRACE_MEMBER_PAIR_L;
      end
    end

    % 追加する右側ブレースのテーブル作成
    tb_add = tb_in(expand_idx,:);
    ntb_add = numel(expand_idx);
    tb_in.idpair(expand_idx) = (n + (1:ntb_add))';

    % 追加ブレースの節点接続処理
    for ie = 1:ntb_add
      % K上形の場合
      if brace_type_expand(ie) == PRM.BRACE_MEMBER_TYPE_K_UPPER
        % 右側：下柱脚→中間節点（BOTH_R、node1=下柱脚）
        tb_add.pair(ie) = PRM.BRACE_MEMBER_PAIR_BOTH_R;
        idnode_mid_ = idnode_mid_array_expand(ie);
        tb_add.idnode2(ie) = idnode_mid_;
        i_src = expand_idx(ie);
        % 既定: 右脚基部は反対側遠端節点（R_far）
        tb_add.idnode1(ie) = idnode_k_R_far_src(i_src);
        is_fg_top_ = pos_brace_fg == PRM.BRACE_FOUNDATION_GIRDER_TOP ...
          && tb_add.idz(ie, 1) == 1;
        if is_fg_top_
          % 基礎梁上端＋1層目は柱分割BODY柱下端を優先
          idc_right = find(member_column.idx(:,1) == tb_add.idx(ie,2) ...
            & member_column.idy(:,1) == tb_add.idy(ie,2) ...
            & member_column.type == PRM.COLUMN_FOR_BRACE_BODY, 1);
          if ~isempty(idc_right)
            tb_add.idnode1(ie) = member_column.idnode1(idc_right);
          end
        end

      % K下形の場合
      elseif brace_type_expand(ie) == PRM.BRACE_MEMBER_TYPE_K_LOWER
        % 右側：中間→上柱頭(R_far)（BOTH_L、／）
        tb_add.pair(ie) = PRM.BRACE_MEMBER_PAIR_BOTH_L;
        idnode_mid_ = idnode_mid_array_expand(ie);
        tb_add.idnode1(ie) = idnode_mid_;
        tb_add.idnode2(ie) = find_idnode_from_idxyz(tb_add.idx(ie,2), ...
          tb_add.idy(ie,2), tb_add.idz(ie,2), node);

      % X形の場合
      else
        % 右側：右下→左上（PAIR_R、＼）
        tb_add.pair(ie) = PRM.BRACE_MEMBER_PAIR_R;
        tb_add.idnode1(ie) = find_idnode_from_idxyz(tb_add.idx(ie,2), ...
          tb_add.idy(ie,2), tb_add.idz(ie,1), node);
        tb_add.idnode2(ie) = find_idnode_from_idxyz(tb_add.idx(ie,1), ...
          tb_add.idy(ie,1), tb_add.idz(ie,2), node);
      end
    end

    % 元のテーブルと追加テーブルを結合
    tb_out = [tb_in; tb_add];

    return
  end

  function [idnode_L, idnode_R, idnode_L_far, idnode_R_far] = ...
      get_kbrace_endpoint_nodes(ib, node_data)
    %get_kbrace_endpoint_nodes - K形ブレース端点節点番号の取得
    %
    %   [idnode_L, idnode_R, idnode_L_far, ...
    %     idnode_R_far] = ...
    %     get_kbrace_endpoint_nodes(ib, node_data) は、
    %   K形ブレースの梁側端点と反対側端点（柱脚/柱頭）の
    %   4節点番号を返す。
    %
    %   入力引数:
    %     ib        - K形ブレースのインデックス配列
    %     node_data - 節点データ
    %
    %   出力引数:
    %     idnode_L     - 左側梁側端点の節点番号
    %     idnode_R     - 右側梁側端点の節点番号
    %     idnode_L_far - 左側反対側端点の節点番号
    %     idnode_R_far - 右側反対側端点の節点番号

    n_brace = length(ib);
    id_k_upper = (brace_type(ib) == PRM.BRACE_MEMBER_TYPE_K_UPPER);

    % 梁側端点（中間節点がある階）
    idz_for_endpoint = zeros(n_brace,1);
    idz_for_endpoint(id_k_upper) = idz(ib(id_k_upper),2);  % K上形：上階
    idz_for_endpoint(~id_k_upper) = idz(ib(~id_k_upper),1); % K下形：下階
    idnode_L = find_idnode_from_idxyz(idx(ib,1), idy(ib,1), ...
      idz_for_endpoint, node_data);
    idnode_R = find_idnode_from_idxyz(idx(ib,2), idy(ib,2), ...
      idz_for_endpoint, node_data);

    % 反対側端点（柱脚/柱頭）
    idz_for_far = zeros(n_brace,1);
    idz_for_far(id_k_upper) = idz(ib(id_k_upper),1);   % K上形：下階
    idz_for_far(~id_k_upper) = idz(ib(~id_k_upper),2);  % K下形：上階
    idnode_L_far = find_idnode_from_idxyz(idx(ib,1), idy(ib,1), ...
      idz_for_far, node_data);
    idnode_R_far = find_idnode_from_idxyz(idx(ib,2), idy(ib,2), ...
      idz_for_far, node_data);

    return
  end
end
