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

## `rules-update` の取り込み方針

このリポジトリのルール本文の正本は `.claude/rules/` であり、`rules-update` が前提とする `.github/copilot-instructions.md` / `.github/instructions/` は導入していない。したがって現状では、`rules-update` による Copilot 向けファイル生成を実行しない。スキルで提案される観点を既存の正本へ取り込む場合は、次の手順に従う。

1. `rules-update` を実行する前に、スキルの前提ファイルと、会話・`docs/`・既存ルールから検出した技術スタックを確認する。前提ファイルが無ければ、スキルの手順どおり `project-init` を提案して **rules-update の処理を終了する**。Copilot 向け構成は、ユーザーが `project-init` を承認・完了した後に改めて検討する。
2. スキルが示す生成ルール、または同等の外部ルールを検討材料にする場合、その本文を複製しない。Rails の学習目的、既存のルール、実装との重複・矛盾に加え、`security.md`・`error-handling.md`・`testing.md`・`docs/06-security-specification.md` への影響をレビューし、採用する項目だけを選ぶ。安全対策を弱める・例外化する場合は、理由と代替防御を明記する。
3. 採用項目は責務に応じて `.claude/rules/coding-standards.md`、`ruby.md`、`fullstack.md`、`api.md`、`database.md`、`testing.md` などへ統合する。Nuxt / NestJS / Playwright など、このリポジトリのスタックにない規約は取り込まない。
4. Rails 固有の規約を更新する場合は、Turbo / PRG、セッション / JWT、Active Storage、Service 層、Capybara system spec の境界について、「何をするか」だけでなく「なぜそうするか」を説明できる学習目的を維持する。
5. ルール本文だけの更新では入口ファイルを変更しない。ルールファイルの追加・削除・改名・適用範囲変更を伴う場合だけ、上記の入口同期ルールに従う。将来 Copilot 向け構成を導入する場合も、二つの正本を並存させず、正本の移行・同期方法を先に合意する。
