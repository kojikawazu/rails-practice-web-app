# アーキテクチャ仕様書（Architecture Specification）

## 目次

- [システム構成](#システム構成)
  - [Project 1: フルスタックRails](#project-1-フルスタックrails)
  - [Project 2: Rails APIモード](#project-2-rails-apiモード)
- [技術スタック](#技術スタック)
- [インフラストラクチャ](#インフラストラクチャ)
  - [Docker 構成](#docker-構成)
  - [環境変数（.env）](#環境変数env)
- [ディレクトリ構成](#ディレクトリ構成)
- [デプロイ](#デプロイ)

## システム構成

### Project 1: フルスタックRails

```text
ブラウザ → Rails（Router → Controller → Service → Model → View/ERB） → PostgreSQL（Docker）
```

- MVC アーキテクチャ（Railsデフォルト）
- サーバーサイドレンダリング
- Controller は薄く保ち、CRUD・認証・画像処理のロジックは **Service 層（`app/services/`）** に集約する（`AuthService` / `ProjectService` / `TaskService` / `TaskImageService`）。
- **返り値は Result 値オブジェクトを使わず、レコード / nil を返す**（API 版との意図的な差異）。HTML の Controller は検証失敗時に「`.errors` を持つそのレコード」でフォームを再描画するため、レコードをそのまま返すのが自然。`ApplicationService` 基底クラスも設けない。
- 認可スコープ（他ユーザーは 404）は `before_action`（`current_user.projects.find`）に残す。API 版と異なり `rescue_from` は設けず、Rails 標準の 404 を用いる。
- **確認画面フロー（PRG・session 退避）・`preview_url` 検証は Controller / Model に残す**（HTTP・表示の都合と密結合のため）。タスクの `create`/`update` は画像添付を build と save の間に挟むため、`TaskService` は `build`/`list`/`destroy` のみを担い save は持たない。
- **画像 round-trip の業務ロジック（検証付き blob 化 staging・attach・purge）は `TaskImageService` に集約**する。Controller から Active Storage API 参照（`ActiveStorage::Blob.create_and_upload!` / `images.attach` / `images_attachments...purge`）が消え、Controller は params 抽出と HTTP 判断、`build↔save` 間の `attach` 注入のみを担う。

### Project 2: Rails APIモード

```text
APIクライアント → Rails（Router → Controller → Service → Model → JSON） → PostgreSQL（Docker）
```

- MVCのうちViewを省略し、JSONレスポンスを返す
- `rails new --api` で生成
- Controller は薄く保ち、ビジネスロジックは **Service 層（`app/services/`）** に集約する（`AuthService` / `ProjectService` / `TaskService`）。サービスの成否は `ApplicationService::Result` 値オブジェクト（`success`/`data`/`errors`/`status`）で表し、Controller は `render_result` で JSON に変換する。
- 他ユーザー/存在しないリソースの 404 は `ApplicationController` の `rescue_from ActiveRecord::RecordNotFound` に一元化する（`e.model` でモデル別メッセージを再現）。
- テストは `spec/lib`（UT）・`spec/services`（UT）・`spec/requests`（IT）・`spec/scenarios`（E2E/シナリオ）で構成（詳細は `08-test-specification.md`）。Service 層の追加による **gem 変更はなし**。

## 技術スタック

| カテゴリ | 技術 |
|----------|------|
| 言語 | Ruby |
| フレームワーク | Ruby on Rails |
| データベース | PostgreSQL 16（Docker コンテナ） |
| オブジェクトストレージ | MinIO（S3 互換。フルスタック版の Active Storage バックエンド） |
| コンテナ | Docker / Docker Compose |
| テスト | RSpec, FactoryBot, Shoulda Matchers |
| 認証 | has_secure_password（bcrypt） |
| テンプレート | ERB（Project 1のみ） |

## インフラストラクチャ

- **PostgreSQL**: docker-compose で起動（Rails とは別プロセス）
- **MinIO**: docker-compose で起動（S3 互換オブジェクトストレージ。フルスタック版の Active Storage バックエンド）
- **Rails**: ローカル実行（Docker 外）
- 本番デプロイは対象外

> **アプリ（Rails）はコンテナ化していない**: `docker compose up` で起動するのは PostgreSQL・MinIO などの**ミドルウェアのみ**。Rails 本体はローカル（`rbenv exec rails server`）で実行する（理由は `04-non-functional-specification.md` 参照）。各アプリ直下の `Dockerfile` / `config/deploy.yml` は `rails new` が生成した**本番デプロイ用（Kamal）テンプレートで、本プロジェクトでは未使用**。

### Docker 構成

```text
docker-compose.yml
  ├── db (postgres:16)
  │     ├── Port: 5434:5432
  │     └── Volume: pgdata → /var/lib/postgresql/data
  ├── minio (minio/minio)            # S3 互換ストレージ（フルスタック版の画像保存先）
  │     ├── Port: 9000（S3 API） / 9001（管理コンソール）
  │     └── Volume: miniodata → /data
  └── createbuckets (minio/mc)       # 起動時にバケットを作成する使い捨てコンテナ
```

### 環境変数（.env）

`.env.example` をテンプレートとして用意している（実際の値は `.env` に記載し、`.gitignore` で管理外とする）。

```text
POSTGRES_USER=rails_task
POSTGRES_PASSWORD=<your_password>
POSTGRES_DB=rails_task_development

# MinIO (S3 互換ストレージ / Active Storage バックエンド)
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=<your_minio_password>
AWS_ACCESS_KEY_ID=minioadmin
AWS_SECRET_ACCESS_KEY=<your_minio_password>
S3_BUCKET=rails-task-dev
MINIO_ENDPOINT=http://localhost:9000
```

※ DB 接続は各アプリの `config/database.yml` が `POSTGRES_*` を `ENV.fetch` で参照して組み立てる（`DATABASE_URL` は使用しない）。MinIO 変数はフルスタック版の Active Storage（S3 互換）で使用する。

## ディレクトリ構成

```text
rails-task-web-app/
├── CLAUDE.md
├── README.md
├── Makefile                       # 開発用タスクランナー（docker/setup/test/lint/ci）
├── docker-compose.yml             # PostgreSQL + MinIO コンテナ定義
├── .env                           # DB接続情報・MinIO 認証情報（.gitignore 対象）
├── docs/                          # 仕様書
├── rails-task-fullstack-web-app/  # Project 1: フルスタック
└── rails-task-api-web-app/        # Project 2: APIモード
```

## デプロイ

- 対象外（ローカル開発のみ）
