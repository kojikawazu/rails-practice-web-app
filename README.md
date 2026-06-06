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
├── docker-compose.yml             # PostgreSQL コンテナ定義
├── .env                           # DB接続情報（git管理外）
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

- `docs/mockups/index.html` をブラウザで開くと画面モック一覧を確認できます
