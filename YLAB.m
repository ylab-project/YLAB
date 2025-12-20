function [exitflag, result, com] = YLAB(varargin)
%YLAB 鋼構造骨組の最適設計プログラム
%
%   局所探索法に基づき、建築基準法に準拠した経済的な断面設計を行う。
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
%     uimode       - ユーザーインターフェースモード（デフォルト: 'CUI'）
%         'GUI'      - 設定ダイアログを表示
%         'CUI'      - コマンドライン引数で実行
%     solutionfile - 初期解として使用する断面リスト（CSV/MAT）
%     optionfile   - 最適化オプションを記述したCSVファイル
%     matfile      - 計算履歴ファイル（中断再開用）
%     trial        - 試行番号（履歴管理用）
%     phase        - 開始フェーズ番号
%     iter         - 開始繰返し番号
%     maxphase     - 最大フェーズ数（計算時間制御）
%     maxiter      - 最大繰返し数（計算時間制御）
%
%   オプションフラグ:
%     -pdf         - PDFレポートを作成
%     -nopdf       - PDFレポートの作成をスキップ（デフォルト）
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
%          'inputfile', 'data/S4.csv', ...
%          'outputfile', 'out/S4_check.csv')
%
%     % 最適化を実行してPDFレポートを作成
%     YLAB('inputfile', 'data/T1R.csv', ...
%          'outputfile', 'out/T1R_opt.csv', '-pdf')
%
%   バージョン確認:
%     YLAB('-version')
%
%   参照:
%     README.md, install.m, build.m
%
%   Copyright (c) Yamakawa Laboratory, Tokyo University of Science.

% このファイルはヘルプ表示専用です。
% 実際の処理は YLAB.p（Pコード）が実行されます。
error('YLAB:helpOnly', ...
  'This file is for help display only. Use YLAB.p for execution.');

end
