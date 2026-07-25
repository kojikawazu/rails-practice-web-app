# テスト設計: カバレッジ補強（認可・確認画面 E2E・初期表示）

## 目次

- [テストケース（分類別）](#テストケース分類別)
  - [件数サマリ（実装後）](#件数サマリ実装後)
- [対象](#対象)
- [前提・方針（重要）](#前提方針重要)
- [テスト構成](#テスト構成)
  - [Request spec（認可・初期表示）](#request-spec認可初期表示)
  - [System spec（確認画面 E2E / Capybara + rack_test）](#system-spec確認画面-e2e--capybara--rack_test)
  - [ログインヘルパー（system 用）](#ログインヘルパーsystem-用)
- [モック方針](#モック方針)
- [実装メモ](#実装メモ)
- [スコープ外（明示）](#スコープ外明示)

フルスタック版の認可スコープ・確認画面 E2E・初期表示を補強するテスト設計。
テストケースは分類別に分割している（下記リンク）。

## テストケース（分類別）

| 分類 | ファイル | 設計件数 |
|---|---|---|
| 正常系 | [02-normal.md](02-normal.md) | 6（+ 削除確認 JS 3） |
| 準正常系（認可・バリデーション） | [03-semi-normal.md](03-semi-normal.md) | 6（+ 境界値 4） |
| 異常系 | [04-abnormal.md](04-abnormal.md) | 1 |

> リグレッション（バグ修正時のみ）は該当ケースが無いため未作成。

### 件数サマリ（実装後）

- 通常スイート: **81 examples / 0 failures**（rack_test、JS 除外）
- JS スイート: **1 example / 0 failures**（`rspec --tag js`）
- ステータス: ✅ 全ケース実装済み

## 対象

- 対象機能: フルスタック版（`rails-task-fullstack-web-app/`）の以下3点を補強する
  1. **認可スコープ**: 他ユーザーのプロジェクト/タスクへアクセスできないこと
  2. **確認画面の E2E**: 入力 → 確認 → 修正（値保持）→ 確定 のブラウザ操作フロー
  3. **初期表示の内容**: 一覧の絞り込み・タスクのステータスバッジ表示
- 対象ファイル:
  - `app/controllers/projects_controller.rb` / `tasks_controller.rb`（`set_project`/`set_task` のスコープ、`confirm`）
  - `app/views/projects/*`・`tasks/*`・`users/*`（confirm / index / show）
- スタック: Ruby on Rails フルスタック（RSpec request spec + Capybara system spec）

## 前提・方針（重要）

- **Capybara/selenium-webdriver は導入済み**（Gemfile `group :test`、`bundle check` 済み）。追加インストール不要。
- **system spec は `rack_test` ドライバを使用**（実ブラウザ不要）。確認画面フローは全てサーバー往復（ネイティブ HTML フォーム submit + `formaction`）で **JS 非依存**のため、rack_test で完全に駆動できる。高速・安定。
- **JS 必須の挙動（削除の `turbo_confirm` ダイアログ）は第2段で追加**（selenium ドライバの別 spec で担保。[02-normal.md](02-normal.md) 参照）。
- fullstack は `rescue_from ActiveRecord::RecordNotFound` を**持たない**。他ユーザーのリソースは `current_user.projects.find` が `RecordNotFound` を raise する。
- テスト環境は `config.action_dispatch.show_exceptions = :rescuable`（`config/environments/test.rb`）。`RecordNotFound` は Rails の `rescue_responses` で `:not_found` にマップ済みのため、**request spec では実際の 404 レスポンスとして検証できる**（本番挙動と同等）。よって認可検証は `expect(response).to have_http_status(:not_found)` を用いる。

## テスト構成

### Request spec（認可・初期表示）

- 追加先:
  - `spec/requests/projects_spec.rb` … N-1, S-1〜S-3, A-1
  - `spec/requests/tasks_spec.rb` … N-2, S-4〜S-5
- 認可検証の形: `expect { get other_path }.to raise_error(ActiveRecord::RecordNotFound)`
- 初期表示の形: `expect(response.body).to include(...)` / `.not_to include(...)`
- 既存の `log_in` ヘルパー（`post login_path ...`）を再利用。他ユーザーは `create(:user)` / `create(:project, user: other)` で用意。

### System spec（確認画面 E2E / Capybara + rack_test）

- 新規ファイル: `spec/system/confirm_flows_spec.rb`
- サポート設定（新規）: `spec/support/capybara.rb`
  - `RSpec.configure { |c| c.before(:each, type: :system) { driven_by :rack_test } }`
- シナリオ（Capybara DSL）:
  - signup: `visit signup_path` → `fill_in` → `click_button "確認する"` → 確認画面のアサート → `click_button "登録する"` → 遷移・件数
  - 「修正する」: 確認画面で `click_button "修正する"` → フォームに `have_field(..., with: 入力値)` を確認
  - project/task: ログイン用ヘルパー（`sign_in` system 用に画面ログインを行う小ヘルパー）を `spec/support` に用意
- 前提条件: 各シナリオは独立。FactoryBot でユーザー/プロジェクトを用意し、画面操作でログイン。

### ログインヘルパー（system 用）

- system spec は HTTP の `post login_path` ではなく画面操作でログインする必要がある。
- `spec/support/system_login_helper.rb` に `sign_in(user)`（visit login → fill → click）を定義し、`type: :system` で include。

## モック方針

- モック許可: なし（外部 I/O は DB のみ。実 DB（Docker PostgreSQL）を使用）
- モック禁止: モデル・コントローラのロジック、バリデーション、認可スコープ
- system spec も実 DB・実レンダリングで検証（rack_test は実アプリにリクエストを流す）

## 実装メモ

- 認可検証は設計時の「raise」想定から **`have_http_status(:not_found)`（実 404 レスポンス）** に変更（`show_exceptions = :rescuable` のため。前提・方針を参照）。
- サポート: `spec/support/capybara.rb`（rack_test ドライバ）/ `spec/support/system_login_helper.rb`（`sign_in_as`）

## スコープ外（明示）

- API 版（`rails-task-api-web-app/`）は既に認可（他ユーザー→404）テスト済みのため対象外。
- DB接続断・タイムアウト等の真の異常系は、トレーニング用途かつ単一ローカル構成のためスコープ外（`docs/04-non-functional-specification.md` に整合）。
