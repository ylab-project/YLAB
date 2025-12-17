function limitWtRatioSection(obj, section, options, secmgr)
%limitWtRatioSection 幅厚比制限チェック
%   limitWtRatioSection(obj, section, options, secmgr) は、幅厚比を
%   満たす断面のみを有効とします。WFS断面とHSS断面に対して幅厚比
%   チェックを実行します。
%
%   入力引数:
%     section - 断面情報構造体
%     options - オプション構造体
%     secmgr - SectionManagerインスタンス（断面性能計算用）
%
%   処理内容:
%     1. 各断面リストについて幅厚比の判定を実行
%     2. 条件を満たさない断面を無効化
%
%   参考:
%     SectionConstraintValidator, limitJbsSection, limitSlrSection

% 定数
idphase = 999;
nwfs_ = obj.nwfs;

% 計算の準備
girder_rank = section.girder.rank(section.girder.type == PRM.WFS);
girder_idslist = section.girder.id_section_list( ...
  section.girder.type == PRM.WFS);

% 断面リストごとに幅厚比を満たす断面だけに限定
for idsList = 1:obj.nlist
  % リストの抽出
  sdimlist = secmgr.getDimension(idsList, idphase);
  n = size(sdimlist, 1);
  
  % リストに対応する断面番号の抽出
  isvalid = obj.extractValidSectionFlags(idsList, idphase);
  
  % 断面種別ごと
  switch obj.secList_.section_type(idsList)
    case PRM.WFS
      % --- WFS ---
      isSN = secmgr.getIdSecList2isSN(idsList);
      isSNH = isSN & options.consider_SNH_WTRATIO;
      
      F = secmgr.getIdSecList2F(idsList);
      H = sdimlist(:, 1);
      B = sdimlist(:, 2);
      tw = sdimlist(:, 3);
      tf = sdimlist(:, 4);
      
      conwt = ones(n, nwfs_);
      for irank = 1:4
        [~, ~, conwt_] = wtratioH(H, B, tw, tf, F, irank, isSNH);
        for i = 1:nwfs_
          if girder_rank(i) == irank && girder_idslist(i) == idsList
            conwt(:, i) = conwt_;
          end
        end
      end
      isvalid_ = conwt' <= 0;
      obj.validSectionFlagCell_{idsList} = isvalid & isvalid_;
      
    case PRM.HSS
      % --- HSS ---
      F = secmgr.getIdSecList2F(idsList);
      D = sdimlist(:, 1);
      t = sdimlist(:, 2);
      
      % 幅厚比を満たさない断面の除外
      [~, conwt] = wtratioBox(D, t, F, options.coptions.rank_column);
      isvalid_ = conwt' <= 0;
      obj.validSectionFlagCell_{idsList} = isvalid & isvalid_;
  end
end

return
end