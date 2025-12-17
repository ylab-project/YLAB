function idmat = extractSectionMaterialId(obj, idsec2slist)
%extractSectionMaterialId 断面の材料IDを抽出（内部使用）
%   idmat = extractSectionMaterialId(obj, idsec2slist) は、
%   断面の材料IDを抽出します。
%
%   入力引数:
%     idsec2slist - [nsec×2] 断面リスト情報
%                   nsec: 全断面数（前提）
%                   列1: 断面リストID (1～nlist)
%                   列2: リスト内インデックス
%
%   出力引数:
%     idmat - [nsec×1] 材料ID配列
%             0: 材料未割当（エラー検出用）
%
%   注意:
%     idsec2slistは全断面を含むことを前提とします。
%
%   参考:
%     extractMemberMaterialId, extractSectionMaterialF

nsec = size(idsec2slist, 1);

% デフォルト材料IDで初期化（必須）
if isempty(obj.idsec2mat_)
  error('SectionPropertyCalculator:NoDefaultMaterialID', ...
    'idsec2mat_が設定されていません');
end
idmat = obj.idsec2mat_;  % デフォルト値を使用

% 各断面リストについて処理（SectionListにある断面を上書き）
nlist_ = obj.nlist;
for ilist = 1:nlist_
  % 該当する断面を特定
  isTarget = (idsec2slist(:,1) == ilist);
  if any(isTarget)
    % リスト内インデックスを取得
    idx_in_list = idsec2slist(isTarget, 2);
    % 有効なインデックス（>0）のみ処理
    valid_idx = (idx_in_list > 0);
    if any(valid_idx)
      % 有効な断面のみ材料IDを設定
      target_rows = find(isTarget);
      valid_rows = target_rows(valid_idx);
      valid_list_idx = idx_in_list(valid_idx);
      % 材料IDを設定
      idmat(valid_rows) = ...
        obj.secList_.idmaterial{ilist}(valid_list_idx);
    end
  end
end

return
end