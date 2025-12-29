# Deprecated Methods Archive

**作成日**: 2025-12-29
**削除予定日**: 2026-01-12（2週間後）

## 理由

Phase 5.0 移行完了により、これらのメソッドは新実装に完全に置き換えられました。

## 含まれるメソッド

60個の `deprecated_*.m` ファイル

## 使用禁止

**これらのメソッドは使用しないでください。** 新実装（プロパティまたは新メソッド）を使用してください。

## 新旧対応表（主要なもの）

| 旧メソッド | 新実装 |
|----------|--------|
| `deprecated_get_idwfs2slist()` | `idwfs2slist` プロパティ |
| `deprecated_get_idhss2slist()` | `idhss2slist` プロパティ |
| `deprecated_get_idbrbs2slist()` | `idbrbs2slist` プロパティ |
| `deprecated_get_idwfs2repwfs()` | `idwfs2repwfs` プロパティ |
| `deprecated_get_idhss2rephss()` | `idhss2rephss` プロパティ |
| `deprecated_get_isVarofSlist()` | IdMapper経由でアクセス |
| `deprecated_get_nxvar()` | `nxvar` プロパティ |

## 削除スケジュール

- **2025-12-29**: archive に移動
- **観察期間**: 2週間（外部依存の確認）
- **2026-01-12**: 完全削除予定（問題がなければ）
