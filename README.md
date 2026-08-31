# YLAB (Yamakawa Laboratory Optimization Program)

YLABは、東京理科大学山川研究室で開発している建築骨組の断面設計プログラムです。MATLAB上で断面最適化を実行できます。

## 主な機能

- 局所探索法による断面最適化
- 指定断面に対する断面検定
- 計算結果CSV、実行ログ、任意指定によるPDF計算書の出力

## 配布形式と要件

実行の入口はPコードの `YLAB.p` です。`YLAB.m` は `help YLAB` 用のコメントを保持するスタブであり、直接実行されません。補助処理のMATLABソースと一部のPコードは `src/` に含まれます。

通常の実行にはMATLABが必要です。機能によって次の製品も必要になります。

| 機能 | 追加要件 |
|---|---|
| PDF計算書の作成（`-pdf`） | MATLAB Report Generator |
| GAによる最適化（`-alg:GA`） | Global Optimization Toolbox |
| スタンドアロンアプリのビルド | MATLAB Compiler |

既定の最適化は並列プールを使用します。並列プールを利用できない環境では `-sequential` を指定してください。

## セットアップ

リポジトリをcloneして、そのディレクトリをMATLABで開きます。

```powershell
git clone https://github.com/ylab-project/YLAB.git
cd YLAB
```

MATLABで次を実行し、YLABと必要なサブディレクトリをパスへ追加します。

```matlab
install
```

`install` は `restoredefaultpath` を実行してからYLABのパスを追加します。現在のMATLABセッションに独自のパス設定がある場合は、その影響を確認してから実行してください。

インストール後はバージョン情報を表示して起動を確認できます。

```matlab
YLAB('-version')
```

## 実行方法

### GUI

引数なしで実行すると設定ダイアログが開きます。

```matlab
YLAB
```

### CUI

CUIではキーと値のペア、およびフラグを指定します。

```matlab
[exitflag, result, com] = YLAB('param1', value1, ...)
```

主な引数は次のとおりです。CUIで計算または変換を実行する場合は `inputfile` と `outputfile` を指定します。

| 引数 | 設定値 | 説明 |
|---|---|---|
| `inputfile` | ファイルパス | 入力CSV |
| `outputfile` | ファイルパス | 結果CSVの出力先 |
| `exemode` | `'OPT'`、`'CHECK'`、`'CONVERT'` | 最適化、断面検定、SS7荷重データ変換。既定値は `'OPT'` |
| `uimode` | `'CUI'`、`'GUI'` | 実行UI。引数を指定した場合の既定値は `'CUI'` |
| `solutionfile` | ファイルパス | 初期解として読み込むCSVまたはMATファイル |
| `optionfile` | ファイルパス | 最適化オプションCSV |

主なフラグは次のとおりです。

| フラグ | 説明 |
|---|---|
| `-pdf` | PDF計算書を作成する |
| `-nopdf` | PDF計算書を作成しない。既定の動作 |
| `-nopreprocess` | 断面リストの事前処理を無効にする |
| `-sequential` | 並列計算を無効にする |
| `-alg:LSR`、`-alg:LSFR`、`-alg:LSR_LSFR`、`-alg:GA` | 最適化アルゴリズムを指定する |
| `-version` | バージョンと実行環境を表示して終了する |

再開用引数などを含む全項目は、MATLABで `help YLAB` を実行して確認してください。

### 断面検定

```matlab
YLAB('exemode', 'CHECK', ...
  'inputfile', 'data/S4.csv', ...
  'outputfile', 'out/S4_check.csv');
```

### 断面最適化

```matlab
YLAB('inputfile', 'data/T1R.csv', ...
  'outputfile', 'out/T1R_opt.csv');
```

PDF計算書も作成する場合は、末尾に `'-pdf'` を追加します。出力先ディレクトリが存在しない場合はYLABが作成します。

## 入力データと出力

`data/` にはS4、T1、T1Rなどのサンプル入力があります。入力CSVの構成は [YLAB入力データ仕様書](doc/入力データ仕様.md) を参照してください。

計算を実行すると、指定した結果CSVと実行ログが出力先に作成されます。エラーが発生した場合はエラー情報ファイルも同じ出力先に作成されます。`-pdf` を指定した場合はPDF計算書が追加されます。

## スタンドアロンアプリのビルド

配布者または管理者がスタンドアロンアプリとインストーラーを作成する場合は、リポジトリのルートで次を実行します。

```matlab
build
```

`build.m` は `YLAB.p` を入口としてビルドし、成果物を `build/` に作成します。生成物を配布する場合は、ビルドに使用したMATLABライセンスの条件を事前に確認してください。

## ディレクトリ構成

```text
YLAB/
├── YLAB.p       実行用Pコード
├── YLAB.m       help表示用スタブ
├── install.m    MATLABパス設定
├── build.m      スタンドアロンビルド
├── src/         補助処理のMATLABソースとPコード
├── data/        サンプル入力
└── doc/         入力仕様とサンプルモデル資料
```

## 著作権と利用条件

Copyright (c) Yamakawa Laboratory, Tokyo University of Science.

本リポジトリには、利用許諾条件を定めるライセンスファイルは含まれていません。利用または再配布については開発者へお問い合わせください。
