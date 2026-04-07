# タスク（Tasks）

## マイルストーン

| # | マイルストーン | 内容 | 対象 |
|---|---------------|------|------|
| Day 1 | 環境構築 + scaffold一本通す | Rails環境セットアップ、scaffold体験 | Project 1 |
| Day 2 | 手書きCRUD | scaffoldなしで Controller/Model/View を実装 | Project 1 |
| Day 3 | 関連付け | 3モデル（User/Project/Task）の関連付きCRUD | Project 1 |
| Day 4 | 仕上げ | RSpec、コード整理、README | Project 1 |
| Day 5+ | APIモード | Project 1 の知識をベースにAPI版を構築 | Project 2 |

## タスク一覧

### Day 1：環境構築 + scaffold一本通す

- [ ] Ruby / Rails バージョン確認・インストール
- [ ] docker-compose.yml 作成（PostgreSQL）
- [ ] `docker compose up -d` で PostgreSQL 起動確認
- [ ] .env 作成（DB接続情報）
- [ ] `rails new` でフルスタックプロジェクト作成（`-d postgresql`）
- [ ] database.yml の設定・接続確認
- [ ] scaffold で一モデル通す（Task等）
- [ ] `rails db:create` → `rails db:migrate` → ブラウザで動作確認
- [ ] .gitignore に .env 追加
- [ ] GitHubリポジトリ作成 → 初回push

### Day 2：手書きCRUD

- [ ] scaffoldなしで Controller / Model / View を自分で書く
- [ ] ルーティング（routes.rb）の設定
- [ ] バリデーションの実装
- [ ] フラッシュメッセージの表示

### Day 3：関連付け

- [ ] User モデル + 認証（has_secure_password）
- [ ] has_many / belongs_to の関連付け実装
- [ ] ネストしたルーティング（projects/:id/tasks）
- [ ] 3モデル（User / Project / Task）の完成

### Day 4：仕上げ

- [ ] RSpec セットアップ
- [ ] Model spec の作成
- [ ] Request spec の作成
- [ ] コード整理・README更新
- [ ] GitHub最終push

### Day 5+：APIモード（Project 2）

- [ ] `rails new --api` でAPIプロジェクト作成
- [ ] 同じ3モデルをAPI版で実装
- [ ] JSONレスポンスの設計・実装
- [ ] RSpec（Request spec中心）
- [ ] フルスタック版との差分を整理

## 進捗

| マイルストーン | ステータス |
|---------------|-----------|
| Day 1 | 未着手 |
| Day 2 | 未着手 |
| Day 3 | 未着手 |
| Day 4 | 未着手 |
| Day 5+ | 未着手 |
