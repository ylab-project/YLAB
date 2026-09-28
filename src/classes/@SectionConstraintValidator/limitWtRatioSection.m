function limitWtRatioSection(obj, section, options, secmgr)
%limitWtRatioSection - 幅厚比制限チェック
%
%   limitWtRatioSection(obj, section, options, secmgr) は、H形鋼の
%   梁断面、角形鋼管の柱断面およびH形鋼の柱断面について幅厚比の判定
%   を行い、条件を満たさない断面を無効化する（obj.validSectionFlagCell_
%   を更新）。H形鋼の柱は梁と同じ断面リストの候補を柱の部材種別と
%   柱用の制限値で判定する。
%
%   入力引数:
%     obj     - SectionConstraintValidator インスタンス
%     section - 断面情報構造体
%     options - オプション構造体
%     secmgr  - SectionManager インスタンス（断面性能計算用）
%
%   備考:
%     関連: SectionConstraintValidator, limitJbsSection,
%           limitSlrSection

% 定数
idphase = 999;

% 計算の準備。H形鋼リストの利用断面は梁と柱をまとめ、部材の区分で
% 制限値の表を選ぶ。角形鋼管リストの利用断面は柱だけ
is_h_girder = section.girder.type == PRM.WFS;
is_h_column = PRM.list_type_of_section_type(section.column.type) ...
  == PRM.WFS;
h_isec = [section.girder.idsec(is_h_girder); ...
  section.column.idsec(is_h_column)];
h_rank = [section.girder.rank(is_h_girder); ...
  section.column.rank(is_h_column)];
h_idslist = [section.girder.id_section_list(is_h_girder); ...
  section.column.id_section_list(is_h_column)];
h_mtype = [PRM.GIRDER*ones(nnz(is_h_girder), 1); ...
  PRM.COLUMN*ones(nnz(is_h_column), 1)];
is_hss = section.column.type == PRM.HSS;
hss_isec = section.column.idsec(is_hss);
hss_rank = section.column.rank(is_hss);
hss_idslist = section.column.id_section_list(is_hss);

% 断面リストごとに幅厚比を満たす断面だけに限定
for idsList = 1:obj.nlist
  % リストの抽出
  sdimlist = secmgr.getDimension(idsList, idphase);

  % 制限適用中は全フェーズの有効性フラグ正本を参照
  isvalid = obj.validSectionFlagCell_{idsList};

  % 断面種別ごと
  switch obj.secList_.section_type(idsList)
    case PRM.WFS
      % --- H形鋼リスト ---
      isSNH = secmgr.getIdSecList2isSN(idsList) ...
        & options.consider_SNH_WTRATIO;
      F = secmgr.getIdSecList2F(idsList);
      H = sdimlist(:, 1);
      B = sdimlist(:, 2);
      tw = sdimlist(:, 3);
      tf = sdimlist(:, 4);

      % 部材の区分と部材種別ごとに、その利用断面の行だけを更新する。
      % FDは制約がないため対象外
      for mtype = [PRM.GIRDER PRM.COLUMN]
        for irank = 1:3
          match = h_mtype == mtype & h_rank == irank ...
            & h_idslist == idsList;
          if ~any(match)
            continue
          end
          [~, ~, conwt_] = wtratioH(H, B, tw, tf, F, irank, isSNH, mtype);
          isec_ = h_isec(match);
          isvalid(isec_, :) = isvalid(isec_, :) & (conwt_(:)' <= 0);
        end
      end

    case PRM.HSS
      % --- 角形鋼管リスト ---
      F = secmgr.getIdSecList2F(idsList);
      D = sdimlist(:, 1);
      t = sdimlist(:, 2);

      % 部材種別ごとに、その柱断面の行だけを更新する
      for irank = 1:3
        match = hss_rank == irank & hss_idslist == idsList;
        if ~any(match)
          continue
        end
        [~, conwt_] = wtratioBox(D, t, F, irank);
        isec_ = hss_isec(match);
        isvalid(isec_, :) = isvalid(isec_, :) & (conwt_(:)' <= 0);
      end
  end
  obj.validSectionFlagCell_{idsList} = isvalid;
end

return
end
