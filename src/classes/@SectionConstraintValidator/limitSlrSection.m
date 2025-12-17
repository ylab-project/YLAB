function limitSlrSection(obj, member, options, secmgr)
%limitSlrSection 細長比制限チェック
%   limitSlrSection(obj, member, options, secmgr) は、保有耐力横補剛を
%   満たすH形断面のみを有効とします。細長比（Slenderness Ratio）と
%   横補剛の条件をチェックします。
%
%   入力引数:
%     member - 部材情報構造体
%     options - オプション構造体（girder_scallop_size等を含む）
%     secmgr - SectionManagerインスタンス（断面性能計算用）
%
%   処理内容:
%     1. 各H形鋼断面リストについて細長比と横補剛の判定を実行
%     2. 条件を満たさない断面を無効化
%     3. 全て無効になった場合はエラー
%
%   参考:
%     SectionConstraintValidator, limitJbsSection, limitWtRatioSection

% 定数
idphase = 999;
nsec = length(obj.idsec2stype);
nwfs_ = obj.nwfs;
nme = secmgr.nme;
nmwfs = secmgr.nmewfs;
nlist_ = obj.nlist;
scallop = options.girder_scallop_size;

% 計算の準備
idsec2slist_ = obj.idsec2slist;
idsec2stype_ = obj.idsec2stype;
idme2sec = secmgr.idme2sec;
idsec2wfs_ = obj.idsec2wfs;

% 部材関連のデータ準備
idmg2m = member.girder.idme;
idmwfs2m = member.girder.idme(member.girder.section_type == PRM.WFS);
idm2mwfs = zeros(1, nme);
idm2mwfs(member.property.section_type == PRM.WFS) = 1:nmwfs;
slr = genslr(member.girder);
lbg = member.girder.stiffening_lb;
lgm_nominal = member.girder.lm_nominal;
lm_nominal(idmg2m) = lgm_nominal;
lbwfs = lbg(idmwfs2m, :);
lmwfs = lm_nominal(idmwfs2m);
slist_type = obj.secList_.section_type;

% 断面リストごとに保有耐力横補剛を満たすH断面だけに限定
isvalid_wfs = false(1, nwfs_);

for idsList = 1:nlist_
  % H形鋼のみ
  if slist_type(idsList) ~= PRM.WFS
    continue
  end
  
  % リストの抽出
  sdimlist = secmgr.getDimension(idsList, idphase);
  n = size(sdimlist, 1);
  
  % リストの断面性能計算
  sproplist = calc_secprop(sdimlist, PRM.WFS, scallop);
  Alist = sproplist.A;
  Izlist = sproplist.Iz;
  Zylist = sproplist.Zy;
  Zpylist = sproplist.Zpy;
  Flist = secmgr.getIdSecList2F(idsList);
  
  % リストに対応するH形断面番号の抽出
  isvalid = obj.extractValidSectionFlags(idsList, idphase);
  
  % OKか判定
  isec_targets = 1:nsec;
  isec_targets = isec_targets( ...
    idsec2slist_' == idsList & idsec2stype_' == PRM.WFS);
  
  for isec = isec_targets
    imtargets = 1:nme;
    imtargets = imtargets(idme2sec' == isec);
    nmtargets = length(imtargets);
    isvalid_ = true(1, n);
    
    for i = 1:nmtargets
      im = imtargets(i);
      imwfs = idm2mwfs(im);
      lbi = repmat(lbwfs(imwfs, :), n, 1);
      lmi = lmwfs(imwfs) * ones(n, 1);
      slri.istarget = repmat(slr.istarget(imwfs, :), n, 1);
      slri.lb = repmat(slr.lb(imwfs, :), n, 1);
      
      conjbs_ = calc_girder_stiffening( ...
        sdimlist, Alist, Izlist, Zylist, Zpylist, ...
        lbi, lmi, Flist, slri);
      isvalid_ = isvalid_ & (conjbs_ <= 0)';
    end
    
    isvalid(idsec2wfs_(isec), :) = ...
      isvalid(idsec2wfs_(isec), :) & isvalid_;
  end
  
  % 条件を満たさないH形断面の除外
  obj.validSectionFlagCell_{idsList} = isvalid;
  
  % チェック結果の保存（OKのH形断面を保存）
  tmp = any(isvalid, 2);
  isvalid_wfs(tmp) = tmp(tmp);
end

% 条件を満たす断面が存在しない
if ~all(isvalid_wfs)
  % エラー処理
  id = 1:nwfs_;
  id = id(~isvalid_wfs);
  ids_text = format_id_list(id);
  throw_err('Parse', 'limit_slr_section', ids_text);
end

return
end
