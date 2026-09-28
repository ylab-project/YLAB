function limitSlrSection(obj, member, nominal, lm, secmgr, options)
%limitSlrSection - 保有耐力横補剛の断面制約チェック
%
%   limitSlrSection(obj, member, nominal, lm, secmgr, options) は、
%   名目梁の保有耐力横補剛を満たす断面候補に限定する。
%
%   入力引数:
%     obj     - SectionConstraintValidatorインスタンス
%     lm      - 部材長 [nme×1] (mm)
%     member  - 部材情報構造体
%     nominal - 名目部材情報構造体
%     options - オプション構造体
%     secmgr  - SectionManagerインスタンス
%
%   参考:
%     SectionConstraintValidator, limitJbsSection

% 定数
idphase = 999;
nsec = length(obj.idsec2stype);
nme = secmgr.nme;
nmwfs = secmgr.nmewfs;
nlist_ = obj.nlist;
scallop = options.girder_scallop_size;

% 計算の準備
idsec2slist_ = obj.idsec2slist;
idsec2stype_ = obj.idsec2stype;
idme2sec = secmgr.idme2sec;

% 部材関連のデータ準備
idmg2m = member.girder.idme;
idmwfs2m = member.girder.idme(member.girder.section_type == PRM.WFS);
idm2mwfs = zeros(1, nme);
idm2mwfs(member.property.section_type == PRM.WFS) = 1:nmwfs;
slr = genslr(member.girder);
idg2ng = member.girder.idnominal(:,1);
lbn = nominal.girder.stiffening_lb;
iwfs = member.girder.section_type == PRM.WFS;
lbwfs = lbn(idg2ng(iwfs), :);
idmeg = nominal.girder.idmeg;
lgmn = calc_nominal_girder_length(idmeg, lm(member.girder.idme));
lm_nominal(idmg2m) = lgmn;
lmwfs = lm_nominal(idmwfs2m);
slist_type = obj.secList_.section_type;

% 断面リストごとに保有耐力横補剛を満たすH断面だけに限定
isvalid_sec = true(1, nsec);

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
  
  % 制限適用中は全フェーズの有効性フラグ正本を参照
  isvalid = obj.validSectionFlagCell_{idsList};
  
  % OKか判定
  isec_targets = find( ...
    idsec2slist_' == idsList & idsec2stype_' == PRM.WFS);
  
  for isec = isec_targets
    imtargets = find(idme2sec' == isec);
    nmtargets = length(imtargets);
    isvalid_ = true(1, n);
    
    for i = 1:nmtargets
      im = imtargets(i);
      imwfs = idm2mwfs(im);
      lbi = repmat(lbwfs(imwfs, :), n, 1);
      lmi = lmwfs(imwfs) * ones(n, 1);
      slri.istarget = repmat(slr.istarget(imwfs, :), n, 1);
      slri.lb = repmat(slr.lb(imwfs, :), n, 1);
      slri.lbmax = repmat(slr.lbmax(imwfs), n, 1);

      conjbs_ = calc_girder_stiffening(sdimlist, Alist, ...
        Izlist, Zylist, Zpylist, lbi, lmi, Flist, slri);
      isvalid_ = isvalid_ & (conjbs_ <= 0)';
    end
    
    isvalid(isec, :) = isvalid(isec, :) & isvalid_;
  end
  
  % 条件を満たさないH形断面の除外
  obj.validSectionFlagCell_{idsList} = isvalid;
  
  % チェック結果の保存（対象リストのWFS断面だけを評価）
  isvalid_sec(isec_targets) = any(isvalid(isec_targets, :), 2)';
end

% 条件を満たす断面が存在しない
if ~all(isvalid_sec)
  % エラー処理（IDは断面番号）
  ids_text = format_id_list(find(~isvalid_sec));
  throw_err('List', 'limit_slr_section', ids_text);
end

return
end
