function fval = objective_lsr_xvar(xvar, com, options)
%objective_lsr_xvar - 設計変数のみから目的関数を評価する
%
%   fval = objective_lsr_xvar(xvar, com, options) は、設計変数から
%   断面寸法を写像し、対応する座標と柱分割を確定する。
%   objective_lsr を実行して目的関数値を返す。写像済み断面を持たない
%   境界で使用する。
%
%   入力引数:
%     xvar    - 設計変数ベクトル
%     com     - 断面管理と入力柱を含む共通データ
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

secdim = com.secmgr.findNearestSection(xvar, options);
com = update_frame_data(secdim, com, options);
fval = objective_lsr(secdim, com.secmgr, com.node, com.section, ...
  com.member, com.floor);

return
end
