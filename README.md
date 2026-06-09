# Rails Task Web App

[![CI](https://github.com/kojikawazu/rails-practice-web-app/actions/workflows/ci.yml/badge.svg)](https://github.com/kojikawazu/rails-practice-web-app/actions/workflows/ci.yml)

## Overview

Railsトレーニング用プロジェクト。同じドメイン（タスク管理）で2つの構成を構築し、差分で学ぶ。

| プロジェクト | ディレクトリ | 構成 |
|---|---|---|
| Project 1: フルスタック | `rails-task-fullstack-web-app/` | ERB/View込みのフルスタック |
| Project 2: APIモード | `rails-task-api-web-app/` | JSON APIのみ |

両プロジェクトとも実装・テスト済みで、ローカルで起動できる（[Quick Start](#quick-start) 参照）。

## Features

タスク管理ドメインを題材に、両プロジェクト共通で以下を実装している。

- ユーザー登録・ログイン / ログアウト（フルスタック版 = セッション、APIモード = JWT）
- プロジェクトの CRUD（一覧・詳細・作成・編集・削除）
- タスクの CRUD + ステータス管理（未着手 / 進行中 / 完了）
- 認可スコープ（他ユーザーのリソースへアクセスすると 404）

フルスタック版のみ:

- **確認画面フロー**（入力 → 確認 → 確定。「修正する」で入力値を保持）
- **タスク画像添付**（Active Storage + MinIO）
- プロジェクト / タスクの複製
- 外部 URL プレビューの iframe 多層防御

機能の詳細は [docs/03-functional-specification.md](docs/03-functional-specification.md) を参照。

## Tech Stack

| カテゴリ | 技術 |
|---|---|
| 言語 | Ruby 3.3.11 |
| フレームワーク | Ruby on Rails 8.1.3 |
| データベース | PostgreSQL 16（Docker） |
| 画像ストレージ | Active Storage + MinIO（S3 互換 / Docker） |
| フロント（フルスタック版） | Turbo / Stimulus（Importmap）+ ERB |
| 認証 | セッション（フルスタック版）/ JWT（APIモード） |
| テスト | RSpec, FactoryBot, Shoulda Matchers, Capybara（system spec） |
| CI | GitHub Actions |

## Quick Start

clone 後、以下で両アプリを起動できる（`make` ショートカット利用。全 target は `make help`）。

### 前提条件

- Ruby 3.3.11（rbenv 推奨）/ Bundler
- Docker / Docker Compose
- Git
- ImageMagick または libvips（画像サムネイル生成用）

### 起動手順

```bash
make up                          # PostgreSQL + MinIO 起動（.env 自動生成・MinIO バケット自動作成）

# フルスタック版 → http://localhost:3099
cd rails-task-fullstack-web-app
bundle install
bin/rails db:prepare
bin/rails server -p 3099

# APIモード → http://localhost:3100
cd rails-task-api-web-app
bundle install
bin/rails db:prepare
bin/rails server -p 3100
```

| サービス | URL / ポート |
|---|---|
| フルスタック版 | http://localhost:3099 |
| APIモード | http://localhost:3100 |
| PostgreSQL | 5434 |
| MinIO（API / コンソール） | http://localhost:9000 / http://localhost:9001 |

> **画像ストレージ（MinIO）**: フルスタック版のタスク画像添付は Active Storage + MinIO（S3 互換）を使う。`make up` で MinIO が起動し、`createbuckets` コンテナがバケットを自動作成する。認証情報は `.env`（`MINIO_ROOT_USER` / `AWS_ACCESS_KEY_ID` 等）で管理する。

## Directory Structure

```
rails-practice-web-app/
├── .github/workflows/ci.yml       # GitHub Actions（テスト CI）
├── CLAUDE.md
├── README.md
├── Makefile                       # 開発用タスクランナー（make help で一覧）
├── docker-compose.yml             # PostgreSQL + MinIO コンテナ定義
├── .env                           # DB接続情報・MinIO 認証情報（git管理外）
├── .env.example                   # 環境変数テンプレート
├── docs/                          # 仕様書・設計資料（01〜15 番号付き）
│   ├── 01〜11-*.md                 # 各種仕様書（要求・要件・機能・非機能・データ ほか）
│   ├── 12-code-reading-guide/      # コードリーディングガイド（Step 別）
│   ├── 13-mockups/                 # HTML モック画面
│   ├── 14-design/                  # 開発設計実装方針（トピック別）
│   └── 15-test-design/             # テスト設計（分類別）
├── rails-task-fullstack-web-app/  # Project 1: フルスタック
└── rails-task-api-web-app/        # Project 2: APIモード
```

## Test / CI

GitHub Actions（`.github/workflows/ci.yml`）で、`main` への push と全 PR で**両プロジェクトのテスト**を自動実行する（デプロイは対象外）。

| ジョブ | 内容 |
|---|---|
| `Detect changes` | 差分パスを判定し、コード変更の有無（`code`）を後続ジョブへ渡す軽量ジョブ |
| `Test (matrix)` | 両アプリで Minitest（`bin/rails test`）+ RSpec（`bundle exec rspec`） |
| `System (:js)` | フルスタック版の JS system spec（`rspec --tag js`、headless Chrome） |

ローカル実行（`make` ショートカット推奨。全 target は `make help` で一覧）:

```bash
make up            # PostgreSQL + MinIO 起動（.env 自動生成）
make db-prepare    # テスト用 DB 準備（既定: fullstack。APP= で切替）
make test          # Minitest + RSpec（既定アプリ）
make test-all      # 両アプリでテスト
make test-js       # JS system spec（fullstack のみ、要 Chrome）
make ci            # ローカル CI 一括（rubocop + security + tests）
```

`make` を使わない場合の素のコマンド:

```bash
docker compose up -d                          # PostgreSQL 起動
cd rails-task-fullstack-web-app
bundle exec rails db:test:prepare
bundle exec rspec                             # 通常スイート（JS 除外）
bundle exec rspec --tag js                    # JS system spec（要 Chrome）
```

> ドキュメントのみの変更（`docs/**` / `**.md` / `.claude/**` 等、コード外）では、`Detect changes` が `code=false` と判定し、重い `Test` / `System` ジョブを **`if` 条件でスキップ**する。`paths-ignore` と違いワークフロー自体は起動するため、スキップされたジョブは required check 上で成功扱いとなり、ブランチ保護を有効にしてもマージがブロックされない。

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
| **起動コマンド・2 構成の差分を読み比べる** | [docs/12-code-reading-guide/](docs/12-code-reading-guide/README.md) |
| **進捗・タスク** | [docs/11-tasks.md](docs/11-tasks.md) |
| **画面モック一覧** | `docs/13-mockups/index.html`（ブラウザで開く） |

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
| 12 | [code-reading-guide](docs/12-code-reading-guide/README.md) | コードリーディングガイド（起動コマンド・2 構成の差分） |
| — | [14-design/](docs/14-design/README.md) | 開発設計実装方針（ベースライン・トピック別分割） |
| — | [15-test-design/coverage-strengthening/](docs/15-test-design/coverage-strengthening/README.md) | テスト設計（カバレッジ補強・分類別分割） |
