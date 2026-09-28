function limitJbsSection(obj, isjbs, nominal_girder, ...
  section_girder, section_column, member, secmgr, options, apply_filter)
%limitJbsSection - 保有耐力接合(JBS)制限チェック
%
%   limitJbsSection(obj, isjbs, nominal_girder,
%     section_girder, section_column, member, secmgr,
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
%     member         - 柱形状と梁端節点を含む部材情報
%     secmgr         - SectionManagerインスタンス
%     options        - オプション構造体
%     apply_filter   - 候補リスト更新フラグ（省略時true）
%
%   参考:
%     SectionConstraintValidator, limitSlrSection

% 定数
if nargin < 9
  apply_filter = true;
end

idphase = 999;
nsec = length(obj.idsec2stype);
nlist_ = obj.nlist;
scallop = options.girder_scallop_size;

% 計算の準備
slist_type = obj.secList_.section_type;
idsec2slist_ = obj.idsec2slist;

% JBS対象の名目梁が使うH形鋼の梁断面（断面番号）。対象外
% （ピン接合等）の梁だけが使う断面は絞り込み対象にしない
idsecg_jbs = nominal_girder.idsecg(any(isjbs, 2));
idsecg_jbs = idsecg_jbs(section_girder.type(idsecg_jbs) == PRM.WFS);
is_jbs_sec = false(1, nsec);
is_jbs_sec(section_girder.idsec(idsecg_jbs)) = true;

% 梁端に接続する上下の柱形状から式の適用範囲を決める
[ng_node1, ng_node2] = get_nominal_girder_end_nodes( ...
  member.girder, nominal_girder.idmeg);
is_tube = is_tube_column_end(member, ng_node1, ng_node2);

% 最も有利な柱候補でもNGとなる梁を除外するための上限
% 引張強さは対象の全鋼柱、mファクター分子は角形鋼管だけから求める
istarget = ismember(section_column.type, [PRM.HSS PRM.CWFS PRM.CWFSI]);
col_lists = unique(idsec2slist_(section_column.idsec(istarget)));
max_sigu = inf;
max_m_num = inf;
if ~isempty(col_lists)
  max_sigu = 0;
end
for ii = 1:length(col_lists)
  il_ = col_lists(ii);
  Fc_ = secmgr.getIdSecList2F(il_);
  sigu_ = zeros(size(Fc_));
  sigu_(Fc_ == 235 | Fc_ == 295) = 400;
  sigu_(Fc_ == 325) = 490;
  max_sigu = max(max_sigu, max(sigu_));
end
hss_lists = unique(idsec2slist_( ...
  section_column.idsec(section_column.type == PRM.HSS)));
if ~isempty(hss_lists)
  max_m_num = 0;
end
for ii = 1:length(hss_lists)
  il_ = hss_lists(ii);
  sdim_ = secmgr.getDimension(il_, idphase);
  Fc_ = secmgr.getIdSecList2F(il_);
  m_num_ = 4 * sdim_(:,2) .* sqrt((sdim_(:,1)-2*sdim_(:,2)) .* Fc_);
  max_m_num = max(max_m_num, max(m_num_));
end
% 断面リストごとに保有耐力接合(仕口)を満たす断面だけに限定
% JBS対象外の断面（非対象の梁だけが使う断面・未使用断面・梁以外）はOK
isvalid_sec = ~is_jbs_sec;

for idsList = 1:nlist_
  % H形鋼のみ
  if slist_type(idsList) ~= PRM.WFS
    continue
  end

  % リストに対応するJBS対象断面の抽出
  isec_jbs = find(is_jbs_sec & idsec2slist_(:)' == idsList);
  if isempty(isec_jbs)
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

  % 同じリストの候補は、対象端に接続する柱形状ごとに一度だけ検定する
  % 両方の柱形状に接続する断面には、それぞれの検定結果を適用する
  n = size(sdimlist, 1);
  for is_tube_ = [false true]
    isec_targets = intersect(isec_jbs, section_girder.idsec( ...
      nominal_girder.idsecg(any(isjbs & is_tube == is_tube_, 2))));
    if isempty(isec_targets)
      continue
    end
    conjbs_ = calc_joint_bearing_strength(sdimlist, Zpylist, ...
      Flist, gradelist, max_sigu*ones(n, 2), max_m_num*ones(n, 2), ...
      repmat(is_tube_, n, 2), [], options);
    isvalid(isec_targets, :) = isvalid(isec_targets, :) & (conjbs_ < 0)';
  end
  % 条件を満たさないH形断面の除外
  if apply_filter
    obj.validSectionFlagCell_{idsList} = isvalid;
  end

  % チェック結果の保存（JBS対象の断面だけを評価）
  isvalid_sec(isec_jbs) = any(isvalid(isec_jbs, :), 2)';
end

% 条件を満たす断面が存在しない
if ~all(isvalid_sec)
  % エラー処理（IDは断面番号）
  ids_text = format_id_list(find(~isvalid_sec));
  throw_err('List', 'limit_jbs_section', ids_text);
end

return
end
