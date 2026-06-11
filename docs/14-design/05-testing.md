# テスト・エラーハンドリング方針

> ツール・対象の一覧は `docs/08-test-specification.md` が正本。本書は**なぜその構成か**を補足する。

## 目次

- [テスト方針](#テスト方針)
  - [テスト分類（RSpec）](#テスト分類rspec)
  - [2 アプリの構成差](#2-アプリの構成差)
  - [:js System spec とフレーク対策](#js-system-spec-とフレーク対策)
  - [テストデータと DB クリーンアップ](#テストデータと-db-クリーンアップ)
  - [テストの原則](#テストの原則)
- [エラーハンドリング方針](#エラーハンドリング方針)

[← 目次に戻る](README.md)

## テスト方針

実装時はテストコードも必ず書く（テストファースト推奨）。テストは独立させ、他テストに依存させない（`.claude/rules/testing.md`）。

### テスト分類（RSpec）

| レベル | ツール | 検証対象 |
|--------|--------|----------|
| **Model spec** | RSpec + Shoulda Matchers | バリデーション・関連付け・enum（`spec/models/`） |
| **Request spec** | RSpec（request specs） | 各 CRUD アクション・複製・認可・エラー応答（`spec/requests/`） |
| **System spec** | RSpec + Capybara | 確認画面・削除確認・複製の画面操作フロー（`spec/system/`） |

- バリデーション・関連付けの単純な検証は **Shoulda Matchers** で簡潔に書く（`validate_presence_of` 等）。
- 認可（他ユーザーリソースの 404、未ログイン時の挙動）は **Request spec** で検証する。フルスタックはリダイレクト、API は **401** と挙動が異なる点を区別する。

### 2 アプリの構成差

- **フルスタック版**: Model spec + Request spec + System spec の 3 層。
- **API 版**: Model spec を持たず、**Request spec（`spec/requests/api/v1/`）のみ**。画面が無いため System spec / Capybara / Selenium は不要（Gemfile にも含めない）。

### :js System spec とフレーク対策

- System spec のうち **Turbo 必須の挙動**（確認画面遷移・`turbo_confirm` ダイアログ）は `:js` タグを付け、**Capybara + Selenium（headless Chrome）**で駆動する（`rspec --tag js`）。
  - これらは「Turbo Drive 退行（確認画面に遷移できなくなる）」の**回帰ガード**が目的。
- それ以外の System spec は高速な `rack_test` で駆動する。
- 実ブラウザ駆動はフレークしやすいため、`:js` には **rspec-retry**（リトライ）を適用する。

### テストデータと DB クリーンアップ

- テストデータは **FactoryBot**（+ Faker）で生成する。
- テスト間の DB クリーンアップは RSpec の **`use_transactional_fixtures`**（トランザクションロールバック）を使用する。`database_cleaner` gem は導入していない。
- テスト用 DB は実行前に `rails db:test:prepare` でスキーマ同期する（CI でも同様）。

### テストの原則

- テストを通すためにテストケースやアサーションを捻じ曲げない。
  - テストが失敗したら、**実装側を修正する**のが正しい対応。期待値を実装の出力に合わせて書き換えるのは禁止。
- テストは仕様の証明であり、実装の後追いではない。
- トレーニング目的のため厳密なカバレッジ目標は設けず、**主要バリデーション + 正常系 CRUD + 認可**の網羅を目標とする。

## エラーハンドリング方針

- ユーザー入力・外部入力は必ずバリデーションする（`.claude/rules/error-handling.md`）。
- **ドメイン層で防げる不正値はモデルで弾く**（presence / format / 値域 / 独自バリデーション。例: タスクのプレビュー URL 検証、画像形式・サイズ）。
- ドメイン層で防げないリクエスト形式・型チェックは Controller 層で検証する。
- HTTP ステータスは適切に返す（フルスタックは確認画面エラーで **422** 再表示、API は 401/404/422 を使い分け）。
- エラー時はスタックトレースを含むログを出力するが、**センシティブ情報はログに含めない**（`config.filter_parameters`）。
