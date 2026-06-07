# Rails Task Web App

[![CI](https://github.com/kojikawazu/rails-task-web-app/actions/workflows/ci.yml/badge.svg)](https://github.com/kojikawazu/rails-task-web-app/actions/workflows/ci.yml)

## Overview

Railsトレーニング用プロジェクト。同じドメイン（タスク管理）で2つの構成を構築し、差分で学ぶ。

| プロジェクト | ディレクトリ | 構成 |
|---|---|---|
| Project 1: フルスタック | `rails-task-fullstack-web-app/` | ERB/View込みのフルスタック |
| Project 2: APIモード | `rails-task-api-web-app/` | JSON APIのみ |

## Tech Stack

| カテゴリ | 技術 |
|---|---|
| 言語 | Ruby |
| フレームワーク | Ruby on Rails |
| データベース | PostgreSQL 16（Docker） |
| テスト | RSpec, FactoryBot, Shoulda Matchers |

## Setup

> **注意**: 現在は設計フェーズです。以下のセットアップ手順は Day 1（環境構築）で実際のファイル（`docker-compose.yml`, `.env.example` 等）を作成した後に実行可能になります。

### 前提条件

- Ruby (rbenv 推奨)
- Rails
- Docker / Docker Compose
- Git

### セットアップ手順（Day 1 で実施予定）

1. `.env.example` をコピーして `.env` を作成（PostgreSQL と MinIO の接続情報）
2. `docker compose up -d` で PostgreSQL と MinIO を起動（MinIO はバケットも自動作成）
3. `rails new` でプロジェクト作成（`-d postgresql`）
4. `rails db:create && rails db:migrate`
5. `rails server` → `http://localhost:3000` で動作確認

> **画像ストレージ（MinIO）**: フルスタック版のタスク画像添付は Active Storage + MinIO（S3 互換）を使う。`docker compose up -d` で MinIO（API: `http://localhost:9000` / コンソール: `http://localhost:9001`）が起動し、`createbuckets` コンテナがバケットを作成する。認証情報は `.env`（`MINIO_ROOT_USER` / `AWS_ACCESS_KEY_ID` 等）で管理し、ローカルでサムネイル生成するには ImageMagick または libvips が必要。

## Directory Structure

```
rails-task-web-app/
├── .github/workflows/ci.yml       # GitHub Actions（テスト CI）
├── CLAUDE.md
├── README.md
├── docker-compose.yml             # PostgreSQL + MinIO コンテナ定義
├── .env                           # DB接続情報・MinIO 認証情報（git管理外）
├── .env.example                   # 環境変数テンプレート
├── docs/                          # 仕様書・モック画面
│   ├── mockups/                   # HTMLモック画面
│   └── design/                    # 設計方針
├── rails-task-fullstack-web-app/  # Project 1: フルスタック
└── rails-task-api-web-app/        # Project 2: APIモード
```

## Test / CI

GitHub Actions（`.github/workflows/ci.yml`）で、`main` への push と全 PR で**両プロジェクトのテスト**を自動実行する（デプロイは対象外）。

| ジョブ | 内容 |
|---|---|
| `Test (matrix)` | 両アプリで Minitest（`bin/rails test`）+ RSpec（`bundle exec rspec`） |
| `System (:js)` | フルスタック版の JS system spec（`rspec --tag js`、headless Chrome） |

ローカル実行:

```bash
docker compose up -d                          # PostgreSQL 起動
cd rails-task-fullstack-web-app
bundle exec rails db:test:prepare
bundle exec rspec                             # 通常スイート（JS 除外）
bundle exec rspec --tag js                    # JS system spec（要 Chrome）
```

> 仕様書・ドキュメント（`**.md` / `docs/`）のみの変更では CI はスキップされる（`paths-ignore`）。

## Docs

仕様書は `docs/` 配下に番号付きで整理しています。

### よくある探し物（クイックリンク）

| 知りたいこと | 参照先 |
|---|---|
| **コンテナ構成・アーキテクチャ**（Docker で何が動く？ Rails はコンテナ？） | [docs/09-architecture-specification.md](docs/09-architecture-specification.md) |
| **インフラ・ポート番号**（PostgreSQL 5434 / MinIO 9000・9001 など） | [docs/04-non-functional-specification.md](docs/04-non-functional-specification.md) |
| **DB（ER 図・テーブルスキーマ・Active Storage）** | [docs/05-data-specification.md](docs/05-data-specification.md) |
| **セキュリティ**（認証・認可・preview_url の iframe 防御） | [docs/06-security-specification.md](docs/06-security-specification.md) |
| **API エンドポイント一覧** | [docs/07-api-specification.md](docs/07-api-specification.md) |
| **起動コマンド・2 構成の差分を読み比べる** | [docs/12-code-reading-guide.md](docs/12-code-reading-guide.md) |
| **進捗・タスク** | [docs/11-tasks.md](docs/11-tasks.md) |
| **画面モック一覧** | `docs/mockups/index.html`（ブラウザで開く） |

### ドキュメント一覧

| # | ファイル | 内容 |
|---|---|---|
| 01 | [business-requirements](docs/01-business-requirements.md) | 要求仕様（背景・目標・スコープ） |
| 02 | [requirements-specification](docs/02-requirements-specification.md) | 要件仕様（機能要件一覧・受け入れ基準・優先度） |
| 03 | [functional-specification](docs/03-functional-specification.md) | 機能仕様（各機能詳細・画面遷移・確認画面・バリデーション） |
| 04 | [non-functional-specification](docs/04-non-functional-specification.md) | 非機能仕様（インフラ構成・ポート） |
| 05 | [data-specification](docs/05-data-specification.md) | データ仕様（ER 図・テーブルスキーマ・Active Storage） |
| 06 | [security-specification](docs/06-security-specification.md) | セキュリティ仕様（認証・認可・iframe 多層防御） |
| 07 | [api-specification](docs/07-api-specification.md) | API 仕様（エンドポイント・リクエスト/レスポンス） |
| 08 | [test-specification](docs/08-test-specification.md) | テスト仕様（戦略・テストケース） |
| 09 | [architecture-specification](docs/09-architecture-specification.md) | アーキテクチャ仕様（システム構成・**Docker/コンテナ構成**・技術スタック） |
| 10 | [miscellaneous-specification](docs/10-miscellaneous-specification.md) | その他（用語集・参考資料） |
| 11 | [tasks](docs/11-tasks.md) | タスク・進捗 |
| 12 | [code-reading-guide](docs/12-code-reading-guide.md) | コードリーディングガイド（起動コマンド・2 構成の差分） |
| — | [design/design-policy](docs/design/design-policy.md) | 開発設計実装方針（ベースライン） |
| — | [test-design/coverage-strengthening-test-design](docs/test-design/coverage-strengthening-test-design.md) | テスト設計（カバレッジ補強） |
