function fval = objective_lsr_xvar(xvar, secmgr, node, section, ...
  member, floor, options)
%objective_lsr_xvar - 設計変数のみから目的関数を評価する
%
%   fval = objective_lsr_xvar(xvar, secmgr, node, section, member,
%   floor, options) は、設計変数から断面寸法を写像し、得られた断面で
%   objective_lsr を実行して目的関数値を返す。写像済み断面を持たない
%   境界で使用する。
%
%   入力引数:
%     xvar    - 設計変数ベクトル
%     secmgr  - SectionManager オブジェクト
%     node    - 節点データ構造体
%     section - 断面データ構造体
%     member  - 部材データ構造体
%     floor   - 床データ構造体
%     options - 計算オプション構造体
%
%   出力引数:
%     fval    - 総コスト [スカラ]
%
%   備考:
%     - xvar は正規化せず、渡された評価点のまま写像する。
%     - 目的関数値のみを返す。詳細集計や積算が必要な境界は、
%       写像済み断面から objective_lsr を直接呼ぶ。
%     - 関連関数: objective_lsr

secdim = secmgr.findNearestSection(xvar, options);
fval = objective_lsr(secdim, secmgr, node, section, member, floor);

return
end
