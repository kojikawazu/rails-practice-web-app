# タスク（Tasks）

## 目次

- [マイルストーン](#マイルストーン)
- [タスク一覧](#タスク一覧)
  - [Day 1：環境構築 + scaffold一本通す](#day-1環境構築--scaffold一本通す)
  - [Day 2：手書きCRUD](#day-2手書きcrud)
  - [Day 3：User認証](#day-3user認証)
  - [Day 4：RSpec](#day-4rspec)
  - [Day 5：APIモード（Project 2）](#day-5apiモードproject-2)
  - [追加対応（機能・テスト・CI）](#追加対応機能テストci)
  - [設計・品質の強化（PR #18〜）](#設計品質の強化pr-18)
- [進捗](#進捗)

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
- [x] タスクにプレビュー URL（`preview_url`）を追加。確認画面で sandbox iframe プレビュー。http/https のみ許可（スキーム検証＋sandbox の多層防御で XSS/トップナビ乗っ取りを抑止）（PR #17）

### 設計・品質の強化（PR #18〜）

PR #18 以降は、作業単位を GitHub issue で管理している（`.claude/rules/github-issue.md`）。ここにはテーマごとの到達点だけを記録し、個々の作業の進捗は issue / PR を参照する。PR を足すたびにこの一覧を更新する必要はない。

#### 機能・設計

- [x] プロジェクト新規作成の確認画面を PRG リダイレクト方式に変更し、タスク確認画面で新規添付画像をサムネイル表示（PR #19, #20）
- [x] Service 層を新設し、Controller を薄く保つ（API: PR #27、フルスタック: PR #28, #30）
- [x] API のレスポンスを Serializer 層で整形し、ActiveRecord を直接返さない（PR #126）
- [x] API のエラーレスポンスを `{ error: { code, message, details } }` に統一（PR #148）
- [x] 不具合修正: プロジェクト一覧の N+1、ステータス遷移の仕様との不一致、confirm ルートの HEAD、画像削除の識別子、404 画面（PR #94, #96, #99, #100, #124）
- [x] 本番で `app/lib` が eager load されていなかった問題を修正（PR #156）
- [x] 非推奨 API の置き換えと、使われていない Rails のスタブの削除（PR #140, #154）

#### セキュリティ

- [x] Authorization ヘッダーを Bearer スキームとして厳密に検証（PR #97）
- [x] CSP を enforce モードで有効化し、インライン JS を Stimulus へ、インライン style を CSS クラスへ移行（PR #102, #130, #139）
- [x] master.key / secret_key_base のローテーションと、鍵の再混入を防ぐガード（PR #105）
- [x] 画像の staging 用 signed_id を利用者限定・期限付きで発行し照合（PR #120）
- [x] 認証系エンドポイントと API 全体にレートリミットを導入（PR #125）
- [x] JWT の署名鍵を定数から外し、呼び出しごとに参照（PR #134）
- [x] Dependabot アラートの脆弱な gem をパッチ版へ更新（PR #113）

#### テスト

- [x] テストピラミッド（UT / IT / E2E・シナリオ）を構築（PR #27, #28）
- [x] request spec の describe / it を日本語の仕様文にする（PR #86）
- [x] Minitest を廃止し RSpec に一本化（PR #123）
- [x] RSpec 実行中の警告・非推奨警告でスイートを失敗させる（PR #143）
- [x] SimpleCov で行・分岐カバレッジを可視化し、見つかった未検証の分岐にテストを追加（PR #150, #153）

#### CI・静的解析

- [x] 開発用タスクランナー（Makefile）を追加（PR #22）
- [x] 変更内容に関係のあるジョブだけを動かす（必須チェック対応の条件実行・除外リスト方式のパスフィルタ）（PR #21, #64, #98）
- [x] Lint & Security ジョブ（RuboCop / bundler-audit / Brakeman）を追加し、Zeitwerk の検査も警告ごと実行（PR #115, #156）
- [x] markdownlint の版固定、リンク切れチェック、actionlint を追加（PR #127, #136, #138）
- [x] Dependabot で GitHub Actions とルートの npm 補助ツールの更新 PR を作る（PR #128）
- [x] ランナーの Ubuntu 26 移行を事前に検証し、`ubuntu-latest` に追従する方針を明記（PR #161）

#### ドキュメント・ルール

- [x] ドキュメント体系の整理と README の改善（PR #18, #23, #24）
- [x] 両アプリの `app/` に YARD ドキュメントコメントを付与し、規約化（PR #25, #26）
- [x] `.claude/rules/` の拡充と、Codex 向けの `AGENTS.md` の追加（PR #31, #78, #82）
- [x] 学習用語集を追加（PR #84）
- [x] issue 運用（重複確認・優先度ラベル）をルール化（PR #122）
- [x] 教訓ログ（`docs/lessons-learned.md`）と記録ルールを導入し、繰り返す教訓をルールへ昇格（PR #117, #146, #158）

## 進捗

| マイルストーン | ステータス |
|---------------|-----------|
| Day 1 | ✅ 完了（PR #1 マージ済み） |
| Day 2 | ✅ 完了（PR #2 マージ済み） |
| Day 3 | ✅ 完了（PR #3 マージ済み） |
| Day 4 | ✅ 完了（PR #4 マージ済み） |
| Day 5 | ✅ 完了（PR #5 マージ済み） |
| 追加対応（機能・テスト・CI） | ✅ 完了（PR #8〜#17 マージ済み） |
| 設計・品質の強化 | 継続中（PR #163 まで反映。以降の進捗は GitHub issue で管理） |
