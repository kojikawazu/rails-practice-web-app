# Rails Task Web App

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

1. `.env.example` をコピーして `.env` を作成
2. `docker compose up -d` で PostgreSQL を起動
3. `rails new` でプロジェクト作成（`-d postgresql`）
4. `rails db:create && rails db:migrate`
5. `rails server` → `http://localhost:3000` で動作確認

## Directory Structure

```
rails-task-web-app/
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

## Docs

- `docs/mockups/index.html` をブラウザで開くと画面モック一覧を確認できます
