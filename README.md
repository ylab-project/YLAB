# YLAB (Yamakawa Laboratory Optimization Program)

YLABは、東京理科大学 山川研究室で開発された、鋼構造骨組の最適設計プログラムです。局所探索法に基づき、建築基準法に準拠した経済的かつ合理的な断面設計を自動的に行います。

## 特徴

- **鋼構造骨組の断面最適化**: H形鋼、角形鋼管、BRB、矩形RCなど多様な断面に対応。
- **制約条件の自動チェック**: 建築基準法および学会規準に基づく詳細な検証。
- **効率的なアルゴリズム**: 局所探索法（Local Search）による高速な最適化。
- **柔軟な実行環境**: MATLAB環境での実行に加え、スタンドアロンアプリとしての実行も可能。

## インストール

### 1. インストーラーを使用する場合（Windows推奨）

配布されている `build/YLabInstaller.exe` を使用すると、MATLABライセンスがなくても実行可能です。

1. `build/YLabInstaller.exe` を実行します。
2. 画面の指示に従い、インストール先を指定します（デフォルト: `C:\Program Files\TUS\YLAB`）。
3. 必要に応じて MATLAB Runtime が自動的にダウンロード・インストールされます。

### 2. MATLAB環境で使用する場合

ソースコード（またはPコード）を直接MATLABで使用する場合の手順です。

```matlab
% 1. リポジトリのクローン（またはダウンロード）
% git clone ...

% 2. ディレクトリへ移動
cd YLAB

% 3. 環境セットアップ（必須）
install
```

## 実行方法（MATLAB環境）

`YLAB` 関数を使用して最適化やチェックを実行します。

### 基本的な実行例

```matlab
% サンプルモデル（S4）の断面検定のみを実行（CHECKモード）
[exitflag, com, result] = YLAB('exemode','CHECK', ...
  'inputfile','data/S4.csv', ...
  'outputfile','out/S4_output.csv');
```

### 実行モード

| モード | 説明 |
|--------|------|
| `'CHECK'` | 構造計算と制約チェックのみ行います（最適化なし）。 |
| `'OPT'` | 断面最適化を実行します（デフォルト）。 |
| `'GA'` | 遺伝的アルゴリズムによる最適化を実行します。 |
| `'CONVERT'` | SS7データの変換を行います。 |

## ビルド（配布者・管理者向け）

スタンドアロンアプリケーションおよびインストーラーを作成するには、`build.m` を使用します。

### 要件
- MATLAB Compiler
- MATLAB Compiler SDK

### 手順
```matlab
cd YLAB
install  % パス設定
build    % ビルド実行（インストーラー生成）
```

出力先: `build/`
- `YLAB.exe` (または `YLabInstaller.exe` 内に含まれるアプリケーション)
- `YLabInstaller.exe`: 配布用インストーラー

## ディレクトリ構成

```
YLAB/
├── YLAB.p            メインプログラム（実行用Pコード）
├── install.m         環境セットアップ・パス設定
├── build.m           インストーラー作成スクリプト
├── src/              コアロジック・ライブラリ
├── data/             サンプル入力データ (S4, T1Rなど)
├── doc/              ドキュメント・マニュアル
└── build/            ビルド成果物出力先
```

## ライセンスと著作権

**Copyright (c) Yamakawa Laboratory, Tokyo University of Science.**

本プログラムは研究・教育目的で開発されています。
商用利用や無断転載についてはお問い合わせください。