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
- 認可スコープ（他ユーザーは 404）は `before_action`（`current_user.projects.find`）に残す。投げられた `RecordNotFound` の応答は `ApplicationController` の `rescue_from` に集約し、HTML はアプリのレイアウトで `errors/not_found` を 404 で描画、JSON は `{ error: "Not found" }` を 404 で返す（静的な `public/404.html` には戻り先がないため。リダイレクトにすると 404 の秘匿が崩れるため 302 にはしない）。
- **確認画面フロー（PRG・session 退避）・`preview_url` 検証は Controller / Model に残す**（HTTP・表示の都合と密結合のため）。タスクの `create`/`update` は画像添付を build と save の間に挟むため、`TaskService` は `build`/`list`/`destroy` のみを担い save は持たない。
- **画像 round-trip の業務ロジック（検証付き blob 化 staging・attach・purge）は `TaskImageService` に集約**する。Controller から Active Storage API 参照（`ActiveStorage::Blob.create_and_upload!` / `images.attach` / `images_attachments...purge`）が消え、Controller は params 抽出と HTTP 判断、`build↔save` 間の `attach` 注入のみを担う。持ち回る `signed_id` の発行（利用者限定・期限付き）と照合（`resolve`）も `TaskImageService` が担い、照合できないときの 422 応答は Controller に残す。
- **定期ジョブ**: 本番は Solid Queue の定期実行（`config/recurring.yml`）で、確認フローを放棄した未添付 blob を `PurgeUnattachedBlobsJob`（`app/jobs/`）が日次で清掃する。development / test は Solid Queue を使わないため定期実行されず、ジョブ単体を job spec で検証する。
- **メール機能は持たない**。Rails が生成する `ApplicationMailer` とメール用レイアウト（`layouts/mailer.*.erb`）は、使われていないため削除した（#152）。`rails g mailer` は `ApplicationMailer` を自動で作り直すが、レイアウトは作り直さないため、メール機能を足すときは `layouts/mailer.html.erb` / `mailer.text.erb` も追加する。

### Project 2: Rails APIモード

```text
APIクライアント → Rails（Router → Controller → Service → Model → JSON） → PostgreSQL（Docker）
```

- MVCのうちViewを省略し、JSONレスポンスを返す
- `rails new --api` で生成
- Controller は薄く保ち、ビジネスロジックは **Service 層（`app/services/`）** に集約する（`AuthService` / `ProjectService` / `TaskService`）。サービスの成否は `ApplicationService::Result` 値オブジェクト（`success`/`data`/`errors`/`status`/`code`）で表し、Controller は `render_result` で JSON に変換する。失敗は HTTP ステータスではなく理由（`code`）で表し、HTTP ステータスとエラーの形への変換は `ErrorSerializer` が担う。
- レスポンスは **Serializer 層（`app/serializers/`、gem を使わない PORO）** で公開属性だけに整形する（`UserSerializer` / `ProjectSerializer` / `TaskSerializer`）。エラーは `ErrorSerializer` が `{ "error": { "code", "message", "details"? } }` の 1 形態に整形し、ルーターの 404 と想定外の 500 は `config.exceptions_app` の `ErrorsController` が同じ形で返す。モデルを直接 `render json:` しない。変換は Controller（HTTP 層）で行い、Service はモデルを返す。
- 他ユーザー/存在しないリソースの 404 は `ApplicationController` の `rescue_from ActiveRecord::RecordNotFound` に一元化する（`e.model` でモデル別メッセージを再現）。
- テストは `spec/lib`（UT）・`spec/services`（UT）・`spec/requests`（IT）・`spec/scenarios`（E2E/シナリオ）で構成（詳細は `08-test-specification.md`）。Service 層・Serializer 層の追加による **gem 変更はなし**。
- **ジョブ・メール機能は持たない**。Rails が生成する `ApplicationJob` / `ApplicationMailer` とメール用レイアウトは、使われていないため削除した（#152）。`rails g job` / `rails g mailer` は基底クラスを自動で作り直す（メール用レイアウトは作り直さない）。

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
| 補助ツール | Node.js（ルートの `package.json`。markdownlint-cli2・remark-validate-links（リンク切れチェック）と CI のパス分類検証のみ。アプリ本体は Node 非依存）、actionlint（Docker イメージ `rhysd/actionlint`。バージョンは `Makefile` の `ACTIONLINT_VERSION`） |

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

# レートリミット（任意。未設定なら括弧内の既定値。docs/06-security-specification.md 参照）
# AUTH_RATE_LIMIT=10            # ログイン・ユーザー登録の上限回数（両アプリ）
# AUTH_RATE_LIMIT_PERIOD=180    # 上記の期間（秒）
# API_RATE_LIMIT=300            # API 全体の上限回数（API 版のみ）
# API_RATE_LIMIT_PERIOD=60      # 上記の期間（秒）
```

※ DB 接続は各アプリの `config/database.yml` が `POSTGRES_*` を `ENV.fetch` で参照して組み立てる（`DATABASE_URL` は使用しない）。MinIO 変数はフルスタック版の Active Storage（S3 互換）で使用する。レートリミットの変数は `config/application.rb` の `config.x.rate_limit` が読む（test 環境は `config/environments/test.rb` で小さい値に上書きする）。

## ディレクトリ構成

```text
rails-task-web-app/
├── AGENTS.md                     # Codex 向けの共通ルール入口
├── CLAUDE.md
├── .claude/rules/                # AI エージェント向け開発ルールの正本
├── README.md
├── Makefile                       # 開発用タスクランナー（docker/setup/test/lint/ci）
├── docker-compose.yml             # PostgreSQL + MinIO コンテナ定義
├── package.json                   # 補助ツール（markdownlint 等）の固定。package-lock.json もコミットする
├── .markdownlint-cli2.jsonc       # markdownlint の対象・除外・ルール設定
├── .remarkrc.mjs                  # リンク切れチェック（remark-validate-links）の設定
├── .remarkignore                  # リンク切れチェックの対象外パス
├── .env                           # DB接続情報・MinIO 認証情報（.gitignore 対象）
├── docs/                          # 仕様書
├── rails-task-fullstack-web-app/  # Project 1: フルスタック
└── rails-task-api-web-app/        # Project 2: APIモード
```

各アプリと `.github/workflows/` には、対象別の追加ルールを参照する `AGENTS.md` を配置する。ルール本文は `.claude/rules/` にのみ置き、`AGENTS.md` は本文を複製しない。

## デプロイ

- 対象外（ローカル開発のみ）
