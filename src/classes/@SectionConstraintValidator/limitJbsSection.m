function limitJbsSection(obj, isjbs, options, secmgr)
%limitJbsSection 保有耐力接合(JBS)制限チェック
%   limitJbsSection(obj, isjbs, options, secmgr) は、保有耐力接合の
%   条件を満たす断面のみを有効とします。H形鋼断面に対して接合部の
%   耐力をチェックし、条件を満たさない断面を無効化します。
%
%   入力引数:
%     isjbs - JBS判定対象フラグ配列 [nwfs×nframe]
%     options - オプション構造体（girder_scallop_size等を含む）
%     secmgr - SectionManagerインスタンス（断面性能計算用）
%
%   処理内容:
%     1. 各H形鋼断面リストについて保有耐力接合の判定を実行
%     2. 条件を満たさない断面を無効化
%     3. 全て無効になった場合はエラー
%
%   参考:
%     SectionConstraintValidator, limitSlrSection, limitWtRatioSection

% 定数
idphase = 999;
nsec = length(obj.idsec2stype);
nwfs_ = obj.nwfs;
nlist_ = obj.nlist;
scallop = options.girder_scallop_size;

% 計算の準備
idsec2slist_ = obj.idsec2slist;
idsec2stype_ = obj.idsec2stype;
idsec2wfs_ = obj.idsec2wfs;
slist_type = obj.secList_.section_type;

% 断面リストごとに保有耐力接合(仕口)を満たす断面だけに限定
isvalid_wfs = false(1, nwfs_);

for idsList = 1:nlist_
  % H形鋼のみ
  if slist_type(idsList) ~= PRM.WFS
    continue
  end
  
  % リストの抽出
  sdimlist = secmgr.getDimension(idsList, idphase);
  
  % リストの断面性能計算
  sproplist = calc_secprop(sdimlist, PRM.WFS, scallop);
  Zpylist = sproplist.Zpy;
  Flist = secmgr.getIdSecList2F(idsList);
  
  % リストに対応する断面の抽出と判定
  isvalid = obj.validSectionFlagCell_{idsList};
  isec_targets = 1:nsec;
  isec_targets = isec_targets( ...
    idsec2slist_' == idsList & idsec2stype_' == PRM.WFS);
  
  % OKか判定
  conjbs_ = calc_joint_bearing_strength( ...
    sdimlist, Zpylist, Flist, [], options);
  isvalid_ = (conjbs_ < 0)';
  
  for isec = isec_targets
    isvalid(idsec2wfs_(isec), :) = ...
      isvalid(idsec2wfs_(isec), :) & isvalid_;
  end
  
  % 条件を満たさないH形断面の除外
  obj.validSectionFlagCell_{idsList} = isvalid;
  
  % チェック結果の保存（OKのH形断面を保存）
  tmp = any(isvalid, 2);
  isvalid_wfs(tmp) = tmp(tmp);
end

% 検討対象外の部材はOKとする
isvalid_wfs(~any(isjbs, 2)) = true;

% 条件を満たす断面が存在しない
if ~all(isvalid_wfs)
  % エラー処理
  id = 1:nwfs_;
  id = id(~isvalid_wfs);
  ids_text = format_id_list(id);
  throw_err('Parse', 'limit_jbs_section', ids_text);
end

return
end