# タスク（Tasks）

## マイルストーン

| # | マイルストーン | 内容 | 対象 |
|---|---------------|------|------|
| Day 1 | 環境構築 + scaffold一本通す | Rails環境セットアップ、scaffold体験 | Project 1 |
| Day 2 | 手書きCRUD | scaffoldなしで Controller/Model/View を実装 | Project 1 |
| Day 3 | 関連付け | User モデル + 認証（has_secure_password）| Project 1 |
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

### Day 3：User認証

- [x] User モデル + has_secure_password（bcrypt）
- [x] SessionsController（login/logout）
- [x] UsersController（signup）
- [x] ApplicationController に認証ヘルパー（current_user, require_login）
- [x] Projects/Tasks を current_user にスコープ
- [x] ログイン・登録 View + レイアウト更新
- [x] テスト28件全パス → PR #3 マージ

### Day 4：RSpec

- [x] RSpec セットアップ（rspec-rails, factory_bot_rails, faker, shoulda-matchers）
- [x] User/Project/Task モデルスペック
- [x] Sessions/Projects/Tasks リクエストスペック
- [x] config/ci.rb に RSpec ステップ追加
- [x] Task デフォルトステータス実装 → PR #4 マージ

### Day 5：APIモード（Project 2）

- [x] `rails new --api` でAPIプロジェクト作成
- [x] User/Project/Task モデル実装（フルスタック版と同一バリデーション）
- [x] JWT認証（JsonWebToken モジュール）
- [x] Api::V1::AuthController（signup/login）
- [x] Api::V1::ProjectsController（CRUD）
- [x] Api::V1::TasksController（CRUD）
- [x] rack-cors 設定
- [x] RSpec リクエストスペック18件

### 追加対応（機能・テスト・CI）

- [x] 確認画面（入力→確認→確定）をフルスタック版に追加（PR #8）
- [x] テスト補強：認可(404)・確認画面E2E・初期表示・境界値・turbo_confirm(JS)（PR #9）
- [x] CI（GitHub Actions, テストのみ）導入：両アプリの Minitest + RSpec、JS system spec を別ジョブで自動実行（PR #10）
- [x] プロジェクト/タスクの複製機能を追加（既存の確認→作成フローへ合流・本体のみ複製）（PR #11）
- [x] 確認画面フローを Turbo Drive 下で動作させる修正＋`:js` system spec で回帰ガード（PR #12）
- [x] 複製・Turbo 対応を各ドキュメント/モックへ同期（PR #13）
- [x] `:js` system spec のフレーク対策（アサーション堅牢化＋`rspec-retry`）（PR #14）
- [x] タスクに開始日・終了日を追加し flatpickr で選択（due_date 廃止）（PR #15）
- [x] タスクに画像添付機能を追加（Active Storage + MinIO・複数枚＋サムネ）。アップロードは新規/編集フォームから行い、確認画面フローに合流（file input は確認ステップで blob 化し `signed_id` を round-trip）。詳細画面はサムネ表示＋個別削除、編集フォームは既存画像の削除予約に対応（PR #16）

## 進捗

| マイルストーン | ステータス |
|---------------|-----------|
| Day 1 | ✅ 完了（PR #1 マージ済み） |
| Day 2 | ✅ 完了（PR #2 マージ済み） |
| Day 3 | ✅ 完了（PR #3 マージ済み） |
| Day 4 | ✅ 完了（PR #4 マージ済み） |
| Day 5 | ✅ 完了（PR #5 マージ待ち） |
