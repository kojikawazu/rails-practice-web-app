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
| 規約本文の変更（`.claude/rules/`） | 原則不要（正本のルールファイルのみ） |
| 規約ファイルの追加・削除・改名・適用範囲変更 | `CLAUDE.md` / `AGENTS.md` 群 / README.md（AI エージェント向けルール表） |
| セットアップ・起動/実行手順・機能概要・技術スタック・開発フェーズ | `README.md` |

該当する変更がない場合はスキップする。

## AI エージェント向け入口の同期

`.claude/rules/` はルール本文の唯一の正本とする。規約ファイルの構成・名称・適用対象を変更した場合は、Claude Code 向けの `CLAUDE.md`、Codex 向けの該当 `AGENTS.md`、README の対応表を同一 PR で同期する。本文だけの変更では、各入口の更新は不要。
