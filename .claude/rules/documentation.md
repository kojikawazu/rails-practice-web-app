---
description: ドキュメント更新・設計書管理（影響マップ + opt-out 完了条件）
globs: 
---

# ドキュメント

コード変更がドキュメント（CLAUDE.md / README.md / docs/）と乖離しないことを構造的に担保する。

## 完了条件（opt-out）

変更は、下記「影響マップ」の対応ドキュメントを**同一 PR 内で更新する**ことを完了条件とする。

- 更新不要と判断した場合は、**PR 説明にその理由を明記する**（省略＝未対応とみなす）。
- この乖離チェックは `/self-review` と `/pr-create` の確認対象に含まれる。

## 影響マップ（変更種別 → 更新必須ドキュメント）

「どのドキュメントだっけ？」を考えさせないための逆引き表。

| 変更種別 | 更新必須ドキュメント |
|---|---|
| ルーティング・コントローラー・API レスポンス | `docs/07-api-specification.md` |
| モデル・マイグレーション・ActiveRecord スキーマ | `docs/05-data-specification.md` |
| 認証・認可・CORS・シークレット・セキュリティ対策 | `docs/06-security-specification.md` |
| 機能追加・変更、画面・View | `docs/03-functional-specification.md` |
| テスト（RSpec / request spec / system spec / FactoryBot） | `docs/08-test-specification.md` |
| 構成・ディレクトリ・Gem 追加/変更・依存関係 | `docs/09-architecture-specification.md` |
| 開発ルール・規約・ワークフロー変更 | `CLAUDE.md` / `.claude/rules/` |
| セットアップ・起動/実行手順・機能概要・技術スタック・開発フェーズ | `README.md` |

該当する変更がない場合はスキップする。
