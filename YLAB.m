function [exitflag, result, com] = YLAB(varargin) %#ok<STOUT>
%YLAB 鋼構造骨組の最適設計プログラム
%
%   局所探索法に基づき建物の断面設計を行う。
%
%   構文:
%     [exitflag, result, com] = YLAB('param1', value1, ...)
%
%   入力引数:
%     inputfile    - 入力データのCSVファイルパス（必須）
%     outputfile   - 結果を出力するCSVファイルパス（必須）
%     exemode      - 実行モード（デフォルト: 'OPT'）
%         'OPT'      - 最適化実行
%         'CHECK'    - 断面検定のみ（最適化なし）
%         'CONVERT'  - SS7形式への荷重データ変換
%     uimode       - UIモード（デフォルト: 'CUI'）
%         'GUI'      - 設定ダイアログを表示
%         'CUI'      - コマンドライン引数で実行
%     solutionfile - 初期解の断面リスト（CSV/MAT）
%     optionfile   - オプションを記述したCSVファイル
%     matfile      - 計算履歴ファイル（中断再開用）
%     lsfr_diagnostic_file - LSFR反復診断情報の保存先MATファイル
%     trial        - 試行番号（履歴管理用）
%     phase        - 開始フェーズ番号
%     iter         - 開始繰返し番号
%     maxphase     - 最大フェーズ数（計算時間制御）
%     maxiter      - 最大繰返し数（計算時間制御）
%
%   オプションフラグ:
%     -pdf         - PDFレポートを作成
%     -nopdf       - PDFレポートの作成をスキップ（デフォルト）
%     -nopreprocess - 断面リスト事前処理を無効化
%     -sequential  - 並列計算を無効化（プロファイリング用）
%     -alg:LSR      - 全PhaseでLSRを使用
%     -alg:LSFR     - 全PhaseでLSFRを使用（デフォルト）
%     -alg:LSR_LSFR - Phase 1はLSR、以降はLSFR
%     -alg:GA       - GAを使用
%     -dev         - 開発者モード（GUIで起動）
%     -version     - バージョン情報を表示して終了
%
%   出力引数:
%     exitflag     - 実行結果フラグ（0以上: 正常、負: エラー）
%     result       - 結果要約構造体
%     com          - 共通オブジェクト構造体
%
%   出力ファイル:
%     *_output.csv   - 最適化結果の断面リスト
%     *-*.pdf        - 詳細な計算書（-pdf指定時）
%     *.log          - 実行ログ
%
%   例:
%     % GUIモード（設定ダイアログを表示）
%     YLAB
%     YLAB('uimode', 'GUI')  % 上と同じ
%
%     % 結果確認のみ
%     YLAB('exemode', 'CHECK', ...
%       'inputfile', 'data/S4.csv', ...
%       'outputfile', 'out/S4_check.csv')
%
%     % 最適化を実行してPDFレポートを作成
%     YLAB('inputfile', 'data/T1R.csv', ...
%       'outputfile', 'out/T1R_opt.csv', '-pdf')
%
%     % 断面リスト事前処理を無効化して確認
%     YLAB('exemode', 'CHECK', ...
%       'inputfile', 'data/S4.csv', ...
%       'outputfile', 'out/S4_check.csv', '-nopreprocess')
%
%   バージョン確認:
%     YLAB('-version')
%
%   参照:
%     README.md, install.m, build.m
%
%   Copyright (c) Yamakawa Laboratory, Tokyo University of Science.

% このファイルはヘルプ表示専用です。
% 実際の処理はYLAB.p（Pコード）が実行されます。
error('YLAB:helpOnly', ...
  'This file is for help display only. Use YLAB.p for execution.');

end
