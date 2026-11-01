function idmat = extractMemberMaterialId(obj, idsec2slist, member)
%extractMemberMaterialId - 部材の材料IDを抽出（内部使用）
%   idmat = extractMemberMaterialId(obj, idsec2slist, member) は、
%   部材の材料IDを抽出します。
%
%   入力引数:
%     obj - 断面特性と材料を参照する計算オブジェクト
%     idsec2slist - [nsec×2] 断面リスト情報
%                   nsec: 全断面数（前提）
%     member - 現在の解析部材。property.idsecは各部材の断面番号
%
%   出力引数:
%     idmat - [nme×1] 材料ID配列
%             nme: 全部材数
%             0: 材料未割当（エラー検出用）
%
%   注意:
%     idsec2slistは全断面を含むことを前提とします。
%
%   参考:
%     extractSectionMaterialId, extractMemberMaterialF

% 断面の材料IDを取得
idsec2mat = obj.extractSectionMaterialId(idsec2slist);

% 部材から断面へのマッピング
idme2sec = member.property.idsec;
nme = length(idme2sec);

% 部材の材料IDを設定
idmat = zeros(nme, 1);  % 0で初期化（エラー検出用）
if ~isempty(idsec2mat) && ~isempty(idme2sec)
  valid_idx = (idme2sec > 0) & (idme2sec <= length(idsec2mat));
  if any(valid_idx)
    idmat(valid_idx) = idsec2mat(idme2sec(valid_idx));
  end
end

return
end
