function limitJbsSection(obj, isjbs, nominal_girder, ...
  section_girder, section_column, secmgr, options, apply_filter)
%limitJbsSection - 保有耐力接合(JBS)制限チェック
%
%   limitJbsSection(obj, isjbs, nominal_girder,
%     section_girder, section_column, secmgr,
%     options) は、保有耐力接合の条件を満たす断面
%   のみを有効とする。H形鋼断面に対して接合部の
%   耐力をチェックし、条件を満たさない断面を無効化
%   する。最も有利な柱（最大値）でもNGとなる梁断面
%   を除外する。絞り込みはJBS対象（isjbs）の名目梁が
%   使う断面に限り、ピン接合等で対象外の梁だけが使う
%   断面は制限しない（SS7は端部ピンを検討しない）。
%
%   入力引数:
%     obj            - SectionConstraintValidatorオブジェクト
%     isjbs          - JBS判定対象フラグ [nng×2]
%     nominal_girder - 名目梁テーブル
%     section_girder - 梁断面構造体
%     section_column - 柱断面構造体
%     secmgr         - SectionManagerインスタンス
%     options        - オプション構造体
%     apply_filter   - 候補リスト更新フラグ（省略時true）
%
%   参考:
%     SectionConstraintValidator, limitSlrSection

% 定数
if nargin < 8
  apply_filter = true;
end

idphase = 999;
nwfs_ = obj.nwfs;
nlist_ = obj.nlist;
scallop = options.girder_scallop_size;

% 計算の準備
slist_type = obj.secList_.section_type;

% WFS断面番号のマッピング
wfs_mask = section_girder.type == PRM.WFS;
idsecg2wfs = zeros(length(wfs_mask), 1);
idsecg2wfs(wfs_mask) = 1:nwfs_;
wfs_slist = obj.idsec2slist(find(wfs_mask));

% 名目梁 → WFS断面番号
ng_wfs = idsecg2wfs(nominal_girder.idsecg);

% JBS対象の名目梁が使うWFS断面。対象外（ピン接合等）の梁だけが
% 使う断面は絞り込み対象にしない
jbs_wfs = unique(ng_wfs(any(isjbs, 2) & ng_wfs > 0));

% HSS柱候補の最大値を計算（最大柱でもNGなら除外）
% HSS柱がない場合は柱側制約なしとして [] を渡す
hss_secc = section_column.type == PRM.HSS;
hss_lists = unique(obj.idsec2slist(section_column.idsec(hss_secc)));
has_hss_col = ~isempty(hss_lists);
max_sigu = 0;
max_m_num = 0;
for ii = 1:length(hss_lists)
  il_ = hss_lists(ii);
  sdim_ = secmgr.getDimension(il_, idphase);
  D_ = sdim_(:, 1);
  t_ = sdim_(:, 2);
  Fc_ = secmgr.getIdSecList2F(il_);
  % STD式用: F値からσuを導出
  sigu_ = zeros(size(Fc_));
  sigu_(Fc_ == 235 | Fc_ == 295) = 400;
  sigu_(Fc_ == 325) = 490;
  max_sigu = max(max_sigu, max(sigu_));
  % AIJ式用: m_num = 4*t*sqrt((D-2t)*F)
  m_num_ = 4 * t_ .* sqrt((D_ - 2*t_) .* Fc_);
  max_m_num = max(max_m_num, max(m_num_));
end

% 断面リストごとに保有耐力接合(仕口)を満たす断面だけに限定
isvalid_wfs = false(1, nwfs_);

for idsList = 1:nlist_
  % H形鋼のみ
  if slist_type(idsList) ~= PRM.WFS
    continue
  end

  % リストに対応するWFS断面と仕口対象断面の抽出
  iwfs_targets = find(wfs_slist == idsList);
  iwfs_jbs = intersect(iwfs_targets, jbs_wfs);
  if isempty(iwfs_jbs)
    continue
  end

  % リストの抽出
  sdimlist = secmgr.getDimension(idsList, idphase);

  % リストの断面性能計算
  sproplist = calc_secprop(sdimlist, PRM.WFS, scallop);
  Zpylist = sproplist.Zpy;
  Flist = secmgr.getIdSecList2F(idsList);
  gradelist = secmgr.getIdSecList2Grade(idsList);

  % リストの有効性フラグ正本
  isvalid = obj.validSectionFlagCell_{idsList};

  % OKか判定（最大柱でもNGなら除外。HSS柱なしは[]で柱制約なし）
  nsec_ = size(sdimlist, 1);
  if options.jbs_mu_formula == PRM.JBS_AIJ
    if has_hss_col
      col_arg = max_m_num * ones(nsec_, 2);
    else
      col_arg = [];
    end
    conjbs_ = calc_joint_bearing_strength_aij(sdimlist, ...
      Zpylist, Flist, gradelist, col_arg, [], options);
  else
    if has_hss_col
      col_arg = max_sigu * ones(nsec_, 2);
    else
      col_arg = [];
    end
    conjbs_ = calc_joint_bearing_strength_std(sdimlist, ...
      Zpylist, Flist, gradelist, col_arg, [], options);
  end
  isvalid_ = (conjbs_ < 0)';

  for iwfs = iwfs_jbs'
    isvalid(iwfs, :) = isvalid(iwfs, :) & isvalid_;
  end

  % 条件を満たさないH形断面の除外
  if apply_filter
    obj.validSectionFlagCell_{idsList} = isvalid;
  end

  % チェック結果の保存（対象リストのWFS断面だけを評価）
  tmp = any(isvalid(iwfs_targets, :), 2);
  isvalid_wfs(iwfs_targets) = tmp(:)';
end

% JBS非対象/未使用の名目梁に対応するWFS断面はOKとする
valid_ng = ng_wfs > 0;
used_wfs = false(1, nwfs_);
used_wfs(ng_wfs(valid_ng)) = true;
nojbs = valid_ng & ~any(isjbs, 2);
isvalid_wfs(ng_wfs(nojbs)) = true;
isvalid_wfs(~used_wfs) = true;

% 条件を満たす断面が存在しない
if ~all(isvalid_wfs)
  % エラー処理
  id = 1:nwfs_;
  id = id(~isvalid_wfs);
  ids_text = format_id_list(id);
  throw_err('List', 'limit_jbs_section', ids_text);
end

return
end
