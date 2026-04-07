# タスク（Tasks）

## マイルストーン

| # | マイルストーン | 内容 | 対象 |
|---|---------------|------|------|
| Day 1 | 環境構築 + scaffold一本通す | Rails環境セットアップ、scaffold体験 | Project 1 |
| Day 2 | 手書きCRUD | scaffoldなしで Controller/Model/View を実装 | Project 1 |
| Day 3 | 関連付け | User モデル + 認証（後回し）| Project 1 |
| Day 4 | 仕上げ | RSpec、コード整理、README | Project 1 |
| Day 5+ | APIモード | Project 1 の知識をベースにAPI版を構築 | Project 2 |

## タスク一覧

### Day 1：環境構築 + scaffold一本通す

- [x] Ruby 3.3.11 / Rails 8.1.3 インストール（rbenv）
- [x] docker-compose.yml 作成（PostgreSQL 16、ポート5434）
- [x] `docker compose up -d` で PostgreSQL 起動確認
- [x] .env 作成（DB接続情報）
- [x] `rails new` でフルスタックプロジェクト作成（`-d postgresql`）
- [x] database.yml の設定・接続確認（ENV.fetch で環境変数対応）
- [x] scaffold で Project / Task モデル通す
- [x] `rails db:create` → `rails db:migrate` → ブラウザで動作確認（ポート3099）
- [x] .gitignore に .env / ランタイム成果物 追加
- [x] GitHubリポジトリ作成 → 初回push → PR #1 マージ

### Day 2：手書きCRUD

- [x] Controller / Model / View をカスタマイズ
- [x] ネストルーティング（projects/:id/tasks）の設定
- [x] バリデーションの実装（Project: title必須/100文字、Task: title必須/200文字、status enum）
- [x] フラッシュメッセージの表示（日本語化）
- [x] View をモック画面デザインに寄せてカスタマイズ（サイドバーレイアウト）
- [x] enum validate: true 対応（不正値で500→422）
- [x] JSON エンドポイントのネストルーティング対応
- [x] テスト14件全パス → PR #2 マージ

### Day 3：関連付け

- [ ] User モデル + 認証（has_secure_password）← **後回し**
- [x] has_many / belongs_to の関連付け実装（Project → Task は Day 1-2 で完了）
- [x] ネストしたルーティング（projects/:id/tasks）← Day 2 で完了
- [ ] 3モデル（User / Project / Task）の完成 ← User 待ち

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
| Day 1 | ✅ 完了（PR #1 マージ済み） |
| Day 2 | ✅ 完了（PR #2 マージ済み） |
| Day 3 | 🔶 一部完了（認証は後回し） |
| Day 4 | 未着手 |
| Day 5+ | 未着手 |
