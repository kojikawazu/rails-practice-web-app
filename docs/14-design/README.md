# 開発設計実装方針（Rails Task Web App）

> 本文書群は本リポジトリ（Rails トレーニング用モノレポ）の**設計方針（HOW / WHY）**をまとめたものである。
> 「何を作るか（WHAT）」を定義する仕様書（`docs/03`〜`docs/09`）とは役割を分け、
> ここでは**採用したパターン・規約・その理由**を扱う（仕様書の表を丸写しせず補完する）。

本リポジトリは **2 つの Rails 8.1 アプリ**で構成される。

- `rails-task-fullstack-web-app/` — MVC（ERB + Turbo / Stimulus）+ セッション認証のフルスタック版。
- `rails-task-api-web-app/` — `rails new --api` の API モード + JWT 認証の API 版。

ミドルウェア（PostgreSQL 16 / MinIO）は `docker-compose` で起動し、**Rails 本体はローカル実行**する。本番デプロイは対象外。

本方針は読みやすさのためトピック別に分割している。全体像はこの目次から辿ること。

## 目次

| ファイル | 内容 |
|---|---|
| [01-development-flow.md](01-development-flow.md) | 開発フロー・Git運用方針 |
| [02-documentation.md](02-documentation.md) | ドキュメント方針 |
| [03-frontend.md](03-frontend.md) | フロントエンド（View 層）設計方針 |
| [04-api-backend.md](04-api-backend.md) | Controller / Model / Service 設計方針 |
| [05-testing.md](05-testing.md) | テスト方針・エラーハンドリング方針 |
| [06-database.md](06-database.md) | DB（ActiveRecord）設計方針 |
| [07-cicd-infra.md](07-cicd-infra.md) | CI/CD・ローカルインフラ方針 |
| [08-security.md](08-security.md) | セキュリティ設計方針 |

## 全体

- Ruby / Rails の規約（命名・ディレクトリ構成）に従う。
- RuboCop（`rubocop-rails-omakase`）でコード品質を自動で担保する。
- 設定値・シークレットは環境変数（`.env`）で管理し、コードにハードコードしない。
- 詳細な開発ルールは `.claude/rules/` に正本があり、本方針はそれと整合させる。
