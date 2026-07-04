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
| Unit spec（UT） | 純粋ロジック・サービスの単体検証（モックあり・DB非依存） | AuthService.login（**両アプリ**。`spec/services/`）・JsonWebToken（**API 版のみ**。`spec/lib/`） |
| Model spec | バリデーション・関連付けの検証 | User, Project, Task（**フルスタック版のみ**。`spec/models/`） |
| Request spec（IT） | エンドポイントの動作検証（実DB） | 各CRUDアクション・複製・認可（両アプリ） |
| Scenario spec（E2E） | 複数エンドポイント縦断の検証（実DB） | signup→CRUD ジャーニー・認可分離・JWT ライフサイクル（**API 版のみ**。`spec/scenarios/`） |
| System spec（E2E） | 画面操作フローの検証（確認画面・削除確認・複製） | フルスタック版のみ（`spec/system/`） |

> **2 アプリのテスト構成差分**: フルスタック版は **Unit spec（`spec/services/`・AuthService.login + TaskImageService）+ Model spec（`spec/models/`）+ Request spec（`spec/requests/`）+ System spec（`spec/system/`）** を持つ。API 版は Model spec を持たない代わりに、**Unit spec（`spec/lib/` `spec/services/`）+ Request spec（`spec/requests/api/v1/`）+ Scenario spec（`spec/scenarios/`）** でテストピラミッドを構成する。API は UI が無いため **E2E == シナリオ == マルチエンドポイントの request spec**（Capybara はフルスタック版専用）。両アプリとも Controller のロジックは `app/services/` に集約する（フルスタック版は HTML 再描画のため Result 値オブジェクトを使わずレコード/ nil を返す。API 版は JSON のため Result を使う）。
> System spec のうち Turbo 必須の挙動（確認画面遷移・`turbo_confirm` ダイアログ）は `:js` タグを付け、headless Chrome（selenium）で実行する（`rspec --tag js`）。それ以外は `rack_test` で駆動する。

### モック方針

「**モック = UT / 実DB = IT・E2E・シナリオ**」を原則とし、モックは**実ロジックのある所だけ**に限定する（薄い CRUD 委譲をモックすると ActiveRecord のスタブ＝実装追認になるため）。UT は substrate の性質で 3 通りに分かれる（純粋＝モック無し／DB 境界＝モック／実 substrate が安価＝モック無し）。

| 対象 | 方針 |
|------|------|
| `JsonWebToken`（API・`spec/lib/`） | **モック無し（純粋）**。DB非依存のため実物の JWT ライブラリで round-trip / 有効期限 / 改ざん / 不正入力を検証 |
| `AuthService.login`（両アプリ・`spec/services/`） | **DB 境界をモック**。`User.find_by` **だけ**を `allow` でスタブ（verified `instance_double`）。呼び出し順を assert する `expect(...).to receive` は使わない。API 版は Result（token 検証）、フルスタック版は `User`/nil を返す点のみ異なる |
| `TaskImageService`（fullstack・`spec/services/`） | **モック無し（実 substrate）**。test 環境の Active Storage は Disk（`tmp/storage`）で実物が安く動くため、実 blob / attachment で stage のオーファン防止・attach・purge を検証。`create_and_upload!`/`attach`/`purge` をモックすると委譲の実装追認になる |
| `AuthService.signup` | UT を書かない（分岐が save 成否のみ＝モデル検証の二重化になる）。IT + シナリオ/System で担保 |
| `ProjectService` / `TaskService` の CRUD | **モック UT を書かない**（意図的・両アプリ）。build/save/update/destroy の委譲はモックすると 100% 実装追認。実価値（スコープ→404・検証→422）は IT + シナリオ/System で担保 |

> フルスタック版の Model spec 46 件は実 DB のモデル単体テスト（build+valid?）で、**モック化しない**（モデル自身の検証をモックすると無意味になるため）。UT のモック対象はサービス層に限る。

## テスト環境

- テスト用DB: PostgreSQL（`rails_task_test` データベース）
- Docker の PostgreSQL コンテナを開発用・テスト用で共有する
- `database.yml` の test 環境で別データベース名を指定
- テスト実行前に `rails db:test:prepare` でスキーマ同期

## テストケース

| テスト種別 | 対象 | テスト内容 |
|-----------|------|-----------|
| Unit spec（API） | JsonWebToken | encode/decode の round-trip / 既定 exp ≒24h / 明示 exp 尊重 / 期限切れ・改ざん・不正入力で nil（例外を投げない） |
| Unit spec（API） | AuthService.login | 正資格情報で成功・token に user_id / 誤パスワードで 401・token なし / メール不在も 401（誤り時と同一メッセージ＝列挙攻撃対策） |
| Unit spec（fullstack） | AuthService.login | 正資格情報で該当ユーザーを返す / 誤パスワードで nil / メール不在も nil（誤り時と同一結果＝列挙攻撃対策）。`User.find_by` のみモック |
| Unit spec（fullstack） | TaskImageService | stage: 全有効→signed_id 返す + blob 生成 / 不正混在→nil・blob 未生成（オーファン防止）/ 空→[] ・ attach→images 増 ・ purge→attachment 削除。実 test-disk・モック無し |
| Model spec | User | 有効なデータで作成できる / name必須 / email必須・一意・形式 / password最小文字数 |
| Model spec | Project | 有効なデータで作成できる / title必須 / user関連付け / 削除時にtasksも削除 |
| Model spec | Task | 有効なデータで作成できる / title必須 / status必須・値の制限 / project関連付け |
| Request spec（fullstack） | Projects | index/show/create/update/destroy の正常系 / 複製(duplicate)の正常系・create フロー合流 / 他ユーザーリソースの404 / 未ログイン時のリダイレクト |
| Request spec（fullstack） | Tasks | index/show/create/update/destroy の正常系 / 複製(duplicate)の正常系・create フロー合流 / 他ユーザーリソースの404 / 存在しないprojectでの404 |
| Request spec（fullstack） | Sessions | ログイン成功/失敗 / ログアウト（セッション） |
| Request spec（API） | Auth | signup / login の成功・失敗（JWT 発行）|
| Request spec（API） | Projects / Tasks | CRUD 正常系 / 他ユーザーリソースの404 / **未認証時は 401**（リダイレクトではない）/ `Authorization: Bearer` 検証 |
| Scenario spec（API） | ユーザージャーニー | signup→project 作成→task 作成→一覧→status 更新→詳細反映（signup の token だけで全書き込みが認可される） |
| Scenario spec（API） | 認可分離 | 他ユーザーの project/task は 404 / project 一覧は自分のものだけ（実DBでスコープ保証を固定） |
| Scenario spec（API） | 認証ライフサイクル | signup token が保護EPで即利用可 / login 成功・誤パスワード 401 / 期限切れ・改ざんトークンは保護EPで 401 |
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
