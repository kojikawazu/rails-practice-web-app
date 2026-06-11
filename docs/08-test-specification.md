# テスト仕様書（Test Specification）

## 目次

- [テスト戦略](#テスト戦略)
- [テスト環境](#テスト環境)
- [テストケース](#テストケース)
- [カバレッジ目標](#カバレッジ目標)
- [テストツール](#テストツール)

## テスト戦略

学習目的のため、以下の3レベルで構成する:

| レベル | 目的 | 対象 |
|--------|------|------|
| Model spec | バリデーション・関連付けの検証 | User, Project, Task（**フルスタック版のみ**。`spec/models/`） |
| Request spec | エンドポイントの動作検証 | 各CRUDアクション・複製・認可（両アプリ） |
| System spec | 画面操作フローの検証（確認画面・削除確認・複製） | フルスタック版のみ |

> **2 アプリのテスト構成差分**: フルスタック版は Model spec（`spec/models/`）+ Request spec（`spec/requests/`）+ System spec（`spec/system/`）を持つ。API 版は Model spec を持たず、**Request spec（`spec/requests/api/v1/`）のみ**で検証する（auth / projects / tasks）。
> System spec のうち Turbo 必須の挙動（確認画面遷移・`turbo_confirm` ダイアログ）は `:js` タグを付け、headless Chrome（selenium）で実行する（`rspec --tag js`）。それ以外は `rack_test` で駆動する。

## テスト環境

- テスト用DB: PostgreSQL（`rails_task_test` データベース）
- Docker の PostgreSQL コンテナを開発用・テスト用で共有する
- `database.yml` の test 環境で別データベース名を指定
- テスト実行前に `rails db:test:prepare` でスキーマ同期

## テストケース

| テスト種別 | 対象 | テスト内容 |
|-----------|------|-----------|
| Model spec | User | 有効なデータで作成できる / name必須 / email必須・一意・形式 / password最小文字数 |
| Model spec | Project | 有効なデータで作成できる / title必須 / user関連付け / 削除時にtasksも削除 |
| Model spec | Task | 有効なデータで作成できる / title必須 / status必須・値の制限 / project関連付け |
| Request spec（fullstack） | Projects | index/show/create/update/destroy の正常系 / 複製(duplicate)の正常系・create フロー合流 / 他ユーザーリソースの404 / 未ログイン時のリダイレクト |
| Request spec（fullstack） | Tasks | index/show/create/update/destroy の正常系 / 複製(duplicate)の正常系・create フロー合流 / 他ユーザーリソースの404 / 存在しないprojectでの404 |
| Request spec（fullstack） | Sessions | ログイン成功/失敗 / ログアウト（セッション） |
| Request spec（API） | Auth | signup / login の成功・失敗（JWT 発行）|
| Request spec（API） | Projects / Tasks | CRUD 正常系 / 他ユーザーリソースの404 / **未認証時は 401**（リダイレクトではない）/ `Authorization: Bearer` 検証 |
| System spec | 確認画面フロー（rack_test） | 登録・プロジェクト/タスク作成の 入力→確認→確定 / 「修正する」で入力値保持 / 不正入力でフォーム留まり |
| System spec | 確認画面フロー（`:js` / Turbo 有効） | 実ブラウザで 登録・作成・複製 の 入力→確認画面表示→確定 が完了すること（Turbo Drive 退行の回帰ガード） |
| System spec | 削除確認（`:js`） | `turbo_confirm` ダイアログの承認/キャンセル挙動 |

## カバレッジ目標

- トレーニング目的のため、厳密なカバレッジ目標は設けない
- 主要なバリデーションと正常系CRUDを網羅することを目標とする

## テストツール

| ツール | 用途 |
|--------|------|
| RSpec | テストフレームワーク |
| FactoryBot | テストデータ生成 |
| Faker | ダミーデータ生成 |
| Shoulda Matchers | バリデーション・関連付けのマッチャー |
| Capybara + Selenium | System spec（`:js` は headless Chrome、フルスタック版のみ） |
| rspec-retry | `:js` System spec のフレーク対策（リトライ） |

> テスト間の DB クリーンアップは RSpec の `use_transactional_fixtures`（トランザクションロールバック）を使用する（`database_cleaner` gem は導入していない）。
