function limitWtRatioSection(obj, section, options, secmgr)
%limitWtRatioSection - 幅厚比制限チェック
%
%   limitWtRatioSection(obj, section, options, secmgr) は、WFS断面
%   およびHSS断面について幅厚比の判定を行い、条件を満たさない断面
%   を無効化する（obj.validSectionFlagCell_ を更新）。
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

% 計算の準備（判定対象はH形鋼の梁断面と角形鋼管の柱断面）
is_girder = section.girder.type == PRM.WFS;
girder_isec = section.girder.idsec(is_girder);
girder_rank = section.girder.rank(is_girder);
girder_idslist = section.girder.id_section_list(is_girder);
is_column = section.column.type == PRM.HSS;
column_isec = section.column.idsec(is_column);
column_rank = section.column.rank(is_column);
column_idslist = section.column.id_section_list(is_column);

% 断面リストごとに幅厚比を満たす断面だけに限定
for idsList = 1:obj.nlist
  % リストの抽出
  sdimlist = secmgr.getDimension(idsList, idphase);

  % 制限適用中は全フェーズの有効性フラグ正本を参照
  isvalid = obj.validSectionFlagCell_{idsList};

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

      % 部材種別ごとに、その種別の梁断面の行だけを更新する
      for irank = 1:4
        match = (girder_rank == irank) & (girder_idslist == idsList);
        if ~any(match)
          continue
        end
        [~, ~, conwt_] = wtratioH(H, B, tw, tf, F, irank, isSNH);
        isec_ = girder_isec(match);
        isvalid(isec_, :) = isvalid(isec_, :) & (conwt_(:)' <= 0);
      end

    case PRM.HSS
      % --- HSS ---
      F = secmgr.getIdSecList2F(idsList);
      D = sdimlist(:, 1);
      t = sdimlist(:, 2);

      % 部材種別ごとに、その種別の柱断面の行だけを更新する
      for irank = 1:4
        match = (column_rank == irank) & (column_idslist == idsList);
        if ~any(match)
          continue
        end
        [~, conwt_] = wtratioBox(D, t, F, irank);
        isec_ = column_isec(match);
        isvalid(isec_, :) = isvalid(isec_, :) & (conwt_(:)' <= 0);
      end
  end
  obj.validSectionFlagCell_{idsList} = isvalid;
end

return
end
