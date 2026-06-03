# テスト設計: カバレッジ補強（認可・確認画面 E2E・初期表示）

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
- **JS 必須の挙動（削除の `turbo_confirm` ダイアログ）は本設計のスコープ外**（将来 selenium ドライバの別 spec で担保）。
- fullstack は `rescue_from ActiveRecord::RecordNotFound` を**持たない**。他ユーザーのリソースは `current_user.projects.find` が `RecordNotFound` を raise する。
- テスト環境は `config.action_dispatch.show_exceptions = :rescuable`（`config/environments/test.rb`）。`RecordNotFound` は Rails の `rescue_responses` で `:not_found` にマップ済みのため、**request spec では実際の 404 レスポンスとして検証できる**（本番挙動と同等）。よって認可検証は `expect(response).to have_http_status(:not_found)` を用いる。

## テストケース一覧

### 正常系

| # | テストケース | 入力 | 期待結果 | テスト種別 | 優先度 |
|---|---|---|---|---|---|
| N-1 | プロジェクト一覧に自分のプロジェクトだけ表示 | 自分の project A + 他人の project B、ログイン | body に A.title を含み、B.title を含まない | Request (index 内容) | High |
| N-2 | タスク一覧（プロジェクト詳細）にステータスバッジ表示 | status 違いの task を複数作成、show 表示 | 「未着手」「進行中」「完了」バッジ文言が表示される | Request (show 内容) | High |
| N-3 | 確認画面 E2E: 登録（signup）通し | name/email/password 入力→確認→登録 | 確認画面に入力値表示→「登録する」で User +1・projects へ遷移 | System (rack_test) | High |
| N-4 | 確認画面 E2E: プロジェクト新規作成 通し | title/description 入力→確認→作成 | 確認画面に値表示→「作成する」で Project +1・詳細へ遷移 | System | High |
| N-5 | 確認画面 E2E: タスク編集 通し | 既存 task の title 変更→確認→更新 | 確認画面に新値表示→「更新する」で値が永続化・詳細へ遷移 | System | Medium |
| N-6 | 確認画面 E2E: 「修正する」で入力値が保持される | 入力→確認→「修正する」 | 入力フォームに戻り、入力した値がフォームに残っている | System | **High**（今回追加機能の核心） |

### 準正常系（認可・バリデーション）

| # | テストケース | 入力 | 期待結果 | テスト種別 | 優先度 |
|---|---|---|---|---|---|
| S-1 | 他ユーザーのプロジェクト show | 他人の project に GET | `ActiveRecord::RecordNotFound` を raise（スコープ外） | Request | High |
| S-2 | 他ユーザーのプロジェクト edit/update/destroy | 他人の project に GET edit / PATCH / DELETE | いずれも `RecordNotFound` を raise | Request | High |
| S-3 | 他ユーザーのプロジェクト confirm（member） | 他人の project に POST confirm | `RecordNotFound` を raise | Request | Medium |
| S-4 | 他ユーザーのタスク show/edit/update/destroy | 他人配下の task に各アクセス | `RecordNotFound` を raise | Request | High |
| S-5 | 他ユーザーのプロジェクト配下でタスク作成不可 | 他人の project_id で tasks#new/create | `RecordNotFound` を raise（`set_project` がスコープ外で失敗） | Request | High |
| S-6 | 確認画面 E2E: 不正入力は確認に進まない | title 空で「確認する」 | 確認画面に進まず、入力フォームにエラー表示 | System | Medium |

### 異常系

| # | テストケース | 入力 | 期待結果 | テスト種別 | 優先度 |
|---|---|---|---|---|---|
| A-1 | 存在しない project_id でタスク一覧 | 実在しない id で tasks 系アクセス | `RecordNotFound` を raise（500ではなく想定内の経路） | Request | Low |

> 注: DB接続断・タイムアウト等の真の異常系は、トレーニング用途かつ単一ローカル構成のためスコープ外（`docs/04-non-functional-specification.md` に整合）。

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

## 実装結果

- ステータス: ✅ 全ケース実装済み・**RSpec 74 examples / 0 failures**（既存 55 + 新規 19）
- 認可検証は設計時の「raise」想定から **`have_http_status(:not_found)`（実 404 レスポンス）** に変更（`show_exceptions = :rescuable` のため。前提・方針を参照）。

| 分類 | ケース | 実装ファイル | 状態 |
|---|---|---|---|
| 正常系 | N-1 一覧の絞り込み表示 | `spec/requests/projects_spec.rb` | ✅ |
| 正常系 | N-2 ステータスバッジ表示 | `spec/requests/projects_spec.rb`（projects#show 上） | ✅ |
| 正常系 | N-3 登録 E2E 通し | `spec/system/confirm_flows_spec.rb` | ✅ |
| 正常系 | N-4 プロジェクト作成 E2E | `spec/system/confirm_flows_spec.rb` | ✅ |
| 正常系 | N-5 タスク編集 E2E | `spec/system/confirm_flows_spec.rb` | ✅ |
| 正常系 | N-6 「修正する」で値保持（signup/project） | `spec/system/confirm_flows_spec.rb` | ✅ |
| 準正常系 | S-1〜S-3 他人の project 認可（show/edit/update/destroy/confirm）→404 | `spec/requests/projects_spec.rb` | ✅ |
| 準正常系 | S-4 他人の task 認可（show/edit/update/destroy）→404 | `spec/requests/tasks_spec.rb` | ✅ |
| 準正常系 | S-5 他人の project 配下でタスク作成→404 | `spec/requests/tasks_spec.rb` | ✅ |
| 準正常系 | S-6 確認画面 不正入力は進まない | `spec/system/confirm_flows_spec.rb` | ✅ |
| 異常系 | A-1 存在しない project_id →404 | `spec/requests/tasks_spec.rb` | ✅ |

サポート: `spec/support/capybara.rb`（rack_test ドライバ）/ `spec/support/system_login_helper.rb`（`sign_in_as`）

## スコープ外（明示）

- 削除時の `turbo_confirm`（JS ダイアログ）の挙動 → selenium ドライバが必要。別途。
- API 版（`rails-task-api-web-app/`）は既に認可（他ユーザー→404）テスト済みのため対象外。
- 境界値（タイトルちょうど100/200文字）→ 今回は presence/scope を優先し、必要なら次段で追加。
