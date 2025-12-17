# YLAB Section Manager Refactoring

## 概要
YLAB（Yamakawa Laboratory Optimization Program）は、局所探索法（Local Search Method）に基づく鋼構造骨組の最適設計プログラムです。構造解析と最適化アルゴリズムを組み合わせ、建築基準法に準拠した経済的な断面設計を行います。

本リポジトリは、YLABのSection Manager機能を責務分離の原則に基づいてリファクタリングしているプロジェクトです。

## 主な機能
- 鋼構造骨組の断面最適化
- 建築基準法に基づく制約条件の自動チェック
- 多様な断面形状のサポート（H形鋼、角形鋼管、BRB、矩形RC）
- 局所探索法による効率的な最適化
- 詳細な計算書の出力

## ディレクトリ構成

```
single_brace/
├── src/              ソースコードのルート
│   ├── analysis/     構造解析・制約評価
│   ├── classes/      MATLABクラス（@-dir形式）
│   ├── lsr/          局所探索法アルゴリズム
│   ├── postprocess/  結果出力・レポート生成
│   ├── preprocess/   前処理・データ準備
│   ├── util/         汎用ユーティリティ
│   └── YLAB.m        メインプログラム
├── data/             入力データ（CSV形式）
├── doc/              設計例・参考資料
├── memo/             開発メモ・設計文書
├── test/             テストコード
├── out/              出力ファイル
├── install.m         セットアップ関数
└── runYLAB.m         実行スクリプト
```

## 実行方法

### セットアップ
```matlab
% MATLABでパス設定
install
```

### 基本的な実行
```matlab
% 対話型実行
runYLAB

% コマンド実行（例：S4モデルのチェック）
[exitflag, com, result] = YLAB('exemode','CHECK', ...
  'inputfile','data/S4.csv', ...
  'outputfile','out/S4_output.csv');
```

### 実行モード
- **CHECK**: 構造計算のみ（最適化なし）
- **OPTIMIZE**: 断面最適化を実行
- **GA**: 遺伝的アルゴリズムによる最適化

## 入力データ形式

### モデルデータ（CSV）
入力CSVファイルには以下の情報を含めます：
- 節点座標
- 部材接続情報
- 荷重条件
- 材料特性
- 設計条件

### サンプルデータ
- `data/T1R.csv`: 基本的な骨組モデル
- `data/S4.csv`: 4層骨組モデル
- `data/KG01.csv`: RC柱を含むモデル
- `data/UN02G.csv`: ブレース付き骨組モデル

## 出力ファイル

### 計算結果
- `out/*_output.csv`: 最適化結果の断面リスト
- `out/*_report.xlsx`: 詳細な計算書（Excel形式）
- `out/*_model.mat`: 解析モデルデータ

### ログファイル
- `out/*_log.txt`: 実行ログ
- `out/*_error.txt`: エラーログ

## 主要な設定パラメータ

### PRM.m（定数定義）
```matlab
% 断面タイプ
PRM.WFS = 1;   % H形鋼
PRM.HSS = 2;   % 角形鋼管
PRM.RCRS = 3;  % RC角形柱
PRM.BRB = 4;   % 座屈拘束ブレース

% 材料定数
PRM.Es = 205000;  % ヤング係数 [N/mm²]
```

## YLAB関数の戻り値

```matlab
[exitflag, com, result] = YLAB(...)
```

- **exitflag**: 実行結果フラグ
  - 1: 正常終了
  - 0: エラー終了
  - -1: ユーザーによる中断
  
- **com**: 共通オブジェクト構造体
  - `com.secmgr`: 断面管理オブジェクト
  - `com.material`: 材料データ
  - `com.member`: 部材データ
  - `com.section`: 断面データ
  
- **result**: 最適化結果
  - `result.x`: 最適設計変数
  - `result.fval`: 目的関数値
  - `result.iteration`: 反復回数

## システム要件

### 必須環境
- MATLAB R2019b以降
- Optimization Toolbox
- Statistics and Machine Learning Toolbox（GA使用時）

### 推奨環境
- メモリ: 8GB以上
- プロセッサ: 4コア以上

## テスト

### テスト実行方法

```bash
# 全テスト実行
matlab -batch "install(isTest=true); test_run"

# システムテストのみ（4つのデータファイルを自動テスト）
matlab -batch "install(isTest=true); test_systemYLAB"

# 個別テスト実行例
matlab -batch "install(isTest=true); test_unitSectionPropertyCalculator"
```

### テスト構成

YLABテストスイートは3つのレベルで構成：

#### 単体テスト（unit）
- 個別クラス・メソッドの動作検証
- モックデータ使用可
- エッジケース（空配列、範囲外等）を網羅
- 例：`test_unitIdMapper.m`、`test_unitSectionPropertyCalculator.m`

#### 統合テスト（integration）
- 複数クラスの連携検証
- 実データ構造に準拠したテストデータ使用
- 新旧実装の比較を含む
- 例：`test_integrationSectionManager.m`

#### システムテスト（system）
- エンドツーエンドの動作確認
- 実際のデータファイル使用（T1R.csv、S4.csv、KG01.csv、UN02G.csv）
- 最終出力（CSVファイル）の検証
- `test_systemYLAB`で全データファイルを自動テスト

### テスト作成指針

#### データ構造の一致性確認
- モックデータは実データ構造を正確に再現
- 配列の列数・行数を実データと一致させる
- 例：WFS断面のsecdimは7列（実寸4列＋未使用1列＋公称値2列）

#### マジックナンバーの排除
```matlab
% 悪い例
val = secdim(:,6);  % 6の意味が不明

% 良い例  
val = secdim(:,6);  % 6列目: H公称値
```

#### テスト失敗時の対応
```matlab
if ~isequal(expected, actual)
  fprintf('期待値: %s\n', mat2str(expected));
  fprintf('実際値: %s\n', mat2str(actual));
  fprintf('差異: %s\n', mat2str(expected - actual));
end
```

### 参照データ

`test/reference_outputs/`に正しい出力の基準データを保存：

#### フル最適化参照データ
- `T1R_output.csv`: 基本モデルの正しい出力
- `S4_output.csv`: 4層モデルの正しい出力
- `KG01_output.csv`: RCRS断面を含むモデルの正しい出力
- `UN02G_output.csv`: ブレース要素を含むモデルの正しい出力

#### 1-iteration参照データ（高速テスト用）  
- `T1R_mit1_output.csv`: T1Rモデルの1-iteration結果
- `S4_mit1_output.csv`: S4モデルの1-iteration結果

### 1-iterationシステムテスト
```bash
matlab -batch "install(isTest=true); test_system1iteration"
```
- **目的**: 最適化の基本動作を高速に確認
- **特徴**:
  - 1-iteration（1回反復）で実行するため高速（数秒で完了）
  - 最適化されたCSV比較処理
    - `detectImportOptions`で読み込み設定を最適化
    - string配列変換で`ismissing`を効率的に適用
    - 可変長CSV対応（パディング処理）
  - 差異表示機能（最大10件の差異を詳細表示）
- **実行オプション**:
  - `maxiter`: 最大iteration数を制限
  - `maxphase`: 最大フェーズ数を制限
  - **注意**: 両方のオプションが必須

**重要**: これらのファイルは絶対に上書き・変更しないこと

## トラブルシューティング

### よくある問題

#### パスが通らない場合
```matlab
% installを再実行
clear all
install
```

#### メモリ不足エラー
大規模モデルの場合、MATLABのメモリ設定を調整：
```matlab
% Java heap memoryを増やす
com.mathworks.services.Prefs.setIntegerPref('JavaMemHeapMax', 2048);
```

## ライセンス
本プログラムは山川研究室の内部利用を目的としています。

## 参考文献
- 建築物の構造関係技術基準解説書
- 鋼構造設計規準（日本建築学会）

## 関連ドキュメント
- [CLAUDE.md](CLAUDE.md) - 開発ガイドライン・コーディング規約
- [TODO.md](TODO.md) - 開発タスク・リファクタリング進捗
