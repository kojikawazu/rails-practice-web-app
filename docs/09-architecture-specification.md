# アーキテクチャ仕様書（Architecture Specification）

## システム構成

### Project 1: フルスタックRails

```
ブラウザ → Rails（Router → Controller → Model → View/ERB） → PostgreSQL（Docker）
```

- MVC アーキテクチャ（Railsデフォルト）
- サーバーサイドレンダリング

### Project 2: Rails APIモード

```
APIクライアント → Rails（Router → Controller → Model → JSON） → PostgreSQL（Docker）
```

- MVCのうちViewを省略し、JSONレスポンスを返す
- `rails new --api` で生成

## 技術スタック

| カテゴリ | 技術 |
|----------|------|
| 言語 | Ruby |
| フレームワーク | Ruby on Rails |
| データベース | PostgreSQL 16（Docker コンテナ） |
| コンテナ | Docker / Docker Compose |
| テスト | RSpec, FactoryBot, Shoulda Matchers |
| 認証 | has_secure_password（bcrypt） |
| テンプレート | ERB（Project 1のみ） |

## インフラストラクチャ

- **PostgreSQL**: docker-compose で起動（Rails とは別プロセス）
- **Rails**: ローカル実行（Docker 外）
- 本番デプロイは対象外

### Docker 構成

```
docker-compose.yml
  └── db (postgres:16)
        ├── Port: 5434:5432
        └── Volume: pgdata → /var/lib/postgresql/data
```

### 環境変数（.env）

```
POSTGRES_USER=rails_task
POSTGRES_PASSWORD=<任意のパスワード>
POSTGRES_DB=rails_task_development
DATABASE_URL=postgresql://rails_task:<パスワード>@localhost:5432/rails_task_development
```

※ 実際の値は `.env` に記載し、`.gitignore` で管理外とする。`.env.example` をテンプレートとして用意する。

## ディレクトリ構成

```
rails-task-web-app/
├── CLAUDE.md
├── README.md
├── docker-compose.yml             # PostgreSQL コンテナ定義
├── .env                           # DB接続情報（.gitignore 対象）
├── docs/                          # 仕様書
├── rails-task-fullstack-web-app/  # Project 1: フルスタック
└── rails-task-api-web-app/        # Project 2: APIモード
```

## デプロイ

- 対象外（ローカル開発のみ）
