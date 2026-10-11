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
| `JsonWebToken`（API・`spec/lib/`） | **モック無し（純粋）**。DB非依存のため実物の JWT ライブラリで round-trip / 有効期限 / 改ざん / 不正入力を検証。鍵ローテーションの検証のみ `Rails.application.secret_key_base` を差し替える（環境依存値の入口であり、JWT ライブラリはモックしない） |
| `AuthService.login`（両アプリ・`spec/services/`） | **DB 境界をモック**。`User.find_by` **だけ**を `allow` でスタブ（verified `instance_double`）。呼び出し順を assert する `expect(...).to receive` は使わない。API 版は Result（token 検証）、フルスタック版は `User`/nil を返す点のみ異なる |
| `TaskImageService`（fullstack・`spec/services/`） | **モック無し（実 substrate）**。test 環境の Active Storage は Disk（`tmp/storage`）で実物が安く動くため、実 blob / attachment で stage のオーファン防止・signed_id の照合（用途・利用者・期限・添付済み）・attach・purge を検証。`create_and_upload!`/`attach`/`purge` をモックすると委譲の実装追認になる |
| `AuthService.signup` | UT を書かない（分岐が save 成否のみ＝モデル検証の二重化になる）。IT + シナリオ/System で担保 |
| `ProjectService` / `TaskService` の CRUD | **モック UT を書かない**（意図的・両アプリ）。build/save/update/destroy の委譲はモックすると 100% 実装追認。実価値（スコープ→404・検証→422）は IT + シナリオ/System で担保 |

> フルスタック版の Model spec 46 件は実 DB のモデル単体テスト（build+valid?）で、**モック化しない**（モデル自身の検証をモックすると無意味になるため）。UT のモック対象はサービス層に限る。

## テスト環境

- テスト用DB: PostgreSQL（`rails_task_test` データベース）
- Docker の PostgreSQL コンテナを開発用・テスト用で共有する
- `database.yml` の test 環境で別データベース名を指定
- テスト実行前に `rails db:test:prepare` でスキーマ同期

### 警告ゼロの維持

RSpec の実行中に警告・非推奨警告が出たら、テストが全件成功していても**スイートを失敗させる**（両アプリ共通）。警告は出力に流れるだけで CI が green のまま見逃されるため（#135 の Rack 非推奨警告。`.claude/rules/static-analysis.md`「警告ゼロを維持する」）。警告の出口は 2 系統あり、それぞれ別の仕組みで検出する。

| 出元 | 出し方 | 検出 |
|---|---|---|
| Ruby / gem（Rack・rspec-rails 等） | `Kernel#warn` → `Warning.warn` | `spec/support/warning_collector.rb` が記録し、`after(:suite)` で 1 件以上あれば失敗させる。警告の場では例外にしない（Capybara のサーバースレッド内で発生すると、原因の分かりにくい別の失敗に化けるため） |
| Rails（`ActiveSupport::Deprecation`） | `$stderr` へ直接出力（`Warning.warn` を通らない） | `config/environments/test.rb` の `config.active_support.deprecation = :raise` で、発生した example を失敗させる |

## テストケース

| テスト種別 | 対象 | テスト内容 |
|-----------|------|-----------|
| Unit spec（API） | JsonWebToken | encode/decode の round-trip / 既定 exp ≒24h / 明示 exp 尊重 / 期限切れ・改ざん・不正入力で nil（例外を投げない）/ 署名鍵を呼び出しごとに参照（`secret_key_base` のローテーション後は旧トークンが nil・新トークンは検証成功） |
| Unit spec（API） | AuthService.login | 正資格情報で成功・token に user_id / 誤パスワードで `invalid_credentials`・token なし / メール不在も `invalid_credentials`（誤り時と同一の失敗理由＝列挙攻撃対策） |
| Unit spec（API） | ErrorSerializer | 一覧に無い code は例外にする（仕様外の code を返さない） |
| Unit spec（fullstack） | AuthService.login | 正資格情報で該当ユーザーを返す / 誤パスワードで nil / メール不在も nil（誤り時と同一結果＝列挙攻撃対策）。`User.find_by` のみモック |
| Unit spec（fullstack） | TaskImageService | stage: 全有効→blob 返す + blob 生成 / 不正混在→nil・blob 未生成（オーファン防止）/ 空→[] ・ signed_id_for/resolve: 発行した利用者なら blob を返す / 他ユーザー向け・既定用途（画像 URL）・改ざん・期限切れ（`travel_to`）・添付済み・不正混在→nil ・ attach→images 増 ・ purge→attachment 削除。実 test-disk・モック無し |
| Job spec（fullstack） | PurgeUnattachedBlobsJob | 保持期間を過ぎた未添付 blob だけを削除（添付済み・保持期間内は残す。`perform_enqueued_jobs` で PurgeJob まで実行）/ 保持期間 > staging の有効期限 |
| Model spec | User | 有効なデータで作成できる / name必須 / email必須・一意・形式 / password最小文字数 |
| Model spec | Project | 有効なデータで作成できる / title必須 / user関連付け / 削除時にtasksも削除 / `.with_task_counts` が件数を tasks_count として載せる（タスク0件のプロジェクトも落とさない） |
| Model spec | Task | 有効なデータで作成できる / title必須 / status必須・値の制限 / project関連付け / ステータス遷移の許可・禁止（作成時は not_started のみ、飛ばし・逆行の拒否、変更なしの更新は許可）/ 添付画像の形式と上限サイズ（上限ちょうどは有効、1 バイト超過で無効） |
| Request spec（fullstack） | Projects | index/show/create/update/destroy の正常系 / 更新の検証失敗は edit を 422 で再描画し値を変えない / 複製(duplicate)の正常系・create フロー合流 / 他ユーザーリソースの404 / 未ログイン時のリダイレクト / 確認画面の HEAD が GET と同じ結果になる / 一覧のタスク件数表示（0件・複数件・プロジェクト0件）/ 件数集計がプロジェクト件数に比例しない（N+1 回帰ガード） |
| Request spec（fullstack） | Not Found | 存在しないプロジェクト・タスクは 404 でレイアウト内にメッセージと一覧への戻り先を表示 / 他ユーザーのプロジェクトは存在しない場合と同じ本文の 404（秘匿）/ JSON は `{ "error": "Not found" }` の 404 / 未ログインは require_login が先にログイン画面へ誘導 |
| Request spec（fullstack） | Tasks | index/show/create/update/destroy の正常系 / 複製(duplicate)の正常系・create フロー合流・ステータスを引き継がないこと / 他ユーザーリソースの404 / 存在しないprojectでの404 / 確認画面の GET・HEAD がフォームへリダイレクト / 画像削除（blob と attachment の id をずらした状態で、選んだ 1 枚だけが外れる・他タスクの添付は外せない）/ ステータス遷移（許可は更新、禁止は 422 で値も変えない）/ フォームの選択肢が現在状態に応じて絞られること / 画像 signed_id の検証（他ユーザー向け・他ユーザーの画像 URL・改ざん・二重送信で create / update / confirm が 422、添付されない） |
| Request spec（fullstack） | Sessions | ログイン成功/失敗 / ログアウト（セッション） |
| Request spec（fullstack） | 認証系のレートリミット | 上限内は通常応答 / 超過で 429・フォーム再描画・メッセージ・`Retry-After` / 上限到達後は正しい認証情報でもログイン・登録させない / 登録の確認と確定はカウンタ共有・ログインとは別カウンタ |
| Request spec（fullstack） | セキュリティヘッダー | CSP を enforce で返す / script-src に unsafe-inline・unsafe-eval が無い / object-src・base-uri・frame-ancestors の禁止設定 / CSP のどこにも unsafe-inline が無い（style-src-attr も無い）/ importmap の nonce 付与 / style-src に nonce があり `csp-nonce` の meta を出す（Turbo の `<style>` を許可）/ `app/views` に style 属性・`style:` オプションが無い（CSP で黙って無視されるための静的検査） |
| Request spec（API） | Auth | signup / login の成功・失敗（JWT 発行）/ `user` の公開属性がキー集合の完全一致で `id` `name` `email` のみ（`password_digest` を返さない） |
| Request spec（API） | レートリミット | login / signup の超過で 429・`code: rate_limited`・`Retry-After` / 上限到達後はトークンを発行しない / login と signup は別カウンタ / API 全体の超過で 429・カウンタはコントローラーをまたいで共有 |
| Request spec（API） | 認証境界（Authorization ヘッダーの契約） | Bearer は 200（scheme は大小無視）/ ヘッダー無し・生トークン・別スキーム・要素過多・空トークン・改ざんは 401 / 401 の統一形式（`code: unauthorized`） |
| Request spec（API） | エラーレスポンスの契約 | 400（必須パラメータの欠落・壊れた JSON。送られた本文を反射しない）/ 401（`unauthorized`・`invalid_credentials`。メール不在とパスワード誤りで同一）/ 404（モデル名入り message）/ 422（`details` に内訳）を、キー集合まで完全一致で固定。詳細表示オフ（本番相当）でルートの 404・想定外の 500（例外の内容を出さない）も JSON で返す |
| Request spec（API） | Projects / Tasks | CRUD 正常系 / 他ユーザーリソースの404 / **未認証時は 401**（リダイレクトではない）/ `Authorization: Bearer` 検証 / ステータス遷移違反は 422 + `details`（作成時の completed 指定を含む）/ index・show・create・update のレスポンスが公開属性のキー集合と完全一致（カラム追加時の意図しない露出を検出） |
| Scenario spec（API） | ユーザージャーニー | signup→project 作成→task 作成→一覧→status 更新（not_started→in_progress→completed と遷移規則どおりに進む）→詳細反映（signup の token だけで全書き込みが認可される） |
| Scenario spec（API） | 認可分離 | 他ユーザーの project/task は 404 / project 一覧は自分のものだけ（実DBでスコープ保証を固定） |
| Scenario spec（API） | 認証ライフサイクル | signup token が保護EPで即利用可 / login 成功・誤パスワード 401 / 期限切れ・改ざんトークンは保護EPで 401 |
| System spec | 確認画面フロー（rack_test） | 登録・プロジェクト/タスク作成の 入力→確認→確定 / 「修正する」で入力値保持 / 不正入力でフォーム留まり |
| System spec | 確認画面フロー（`:js` / Turbo 有効） | 実ブラウザで 登録・作成・複製 の 入力→確認画面表示→確定 が完了すること（Turbo Drive 退行の回帰ガード） |
| System spec | 削除確認（`:js`） | `turbo_confirm` ダイアログの承認/キャンセル挙動 |
| System spec | 一覧の行クリック（`:js`） | 行クリックで詳細へ遷移 / 行内リンクは本来の遷移先へ。CSP を enforce したブラウザで Stimulus 移行が効いていることの回帰ガード |
| System spec | CSP 違反（`:js`） | ログイン〜Turbo 遷移でブラウザログに CSP 違反が出ない（Turbo のプログレスバー `<style>` が nonce で許可されることの回帰ガード）。ログ取得の設定外れで素通りしないよう、既知のメッセージが取得できることも同時に確認する |

## spec の文言（`describe` / `it`）の書き方

学習用リポジトリのため、**`rspec --format documentation` の出力がそのまま仕様書として読める**ことを目標にする。

- **`it` は日本語の仕様文にする**。「何が起きるか」に加え、**非自明なら「なぜそうするか」まで書く**（例: `"他ユーザーのタスク詳細は、403 ではなく 404 を返して存在自体を秘匿する"`）。
- **`"returns http success"` のような実装なぞりを書かない**。`have_http_status(:success)` を読めば分かることを繰り返さない。
- **`describe` は HTTP メソッドとパスを残し、日本語の括弧書きを添える**（例: `"POST /projects/:project_id/tasks/confirm（新規の確認画面）"`）。パスはルーティングとの対応を追う手がかりになるため消さない。
- **意図の説明に `#` コメントを使わない。** 意図は `it` の文言で表現する。`#` コメントを使うのは、**テストの意図ではなくテスト機構の都合**を書くときに限る（`:js` を付けた理由、リトライの根拠、`fixture_file_upload` の前提など）。詳細は `.claude/rules/testing.md` の「system spec の学習上重要な境界」。

> この方針は request spec / scenario spec / system spec に適用する。model spec は Shoulda Matchers の 1 行 matcher（`it { is_expected.to validate_presence_of(:title) }`）が自己説明的なため、無理に文章化しない。

## カバレッジ目標

- トレーニング目的のため、厳密なカバレッジ目標は設けない
- 主要なバリデーションと正常系CRUDを網羅することを目標とする

### カバレッジの計測（SimpleCov）

両アプリで SimpleCov（`rails` プロファイル）により、**行カバレッジと分岐カバレッジ**を計測する（#149）。**最低ラインは設けず、可視化だけに使う**。数値を上げるためのテストは書かず、0% の行や通らない分岐は**デッドコードの候補**として扱う（`.claude/rules/dead-code.md`）。

- **計測の開始位置**: `spec/spec_helper.rb` の先頭で `SimpleCov.start` を呼ぶ。Ruby の `Coverage` は計測開始より後に読み込まれたファイルだけを数えるため、Rails・アプリのコードより先に開始しないと、そのファイルは計測対象から黙って外れる。
- **対象**: `app/**/*.rb`。一度も読み込まれなかったファイルも 0% として計上される（使われていないクラスを見つけられる）。
- **見方**: ローカルでは `bundle exec rspec` 後に `coverage/index.html`（`bundle exec simplecov open` で開ける）。CI では `Test (matrix)` ジョブのサマリーに行・分岐の % が表示され、HTML レポートは artifact（`coverage-<アプリ名>`、保持 7 日）に残る。
- **`:js` system spec は含まない**: fullstack の CI では `:js` を別ジョブ（`System (:js)`）で実行するため、ジョブサマリーの値は通常の実行だけの値になる（結果のマージはしない）。

導入時（2026-10-11）の値:

| アプリ | 行 | 分岐 |
|---|---|---|
| API | 98.13%（210 / 214） | 91.66%（44 / 48） |
| fullstack（`:js` を除く） | 98.47%（322 / 327） | 95.74%（90 / 94） |

## テストツール

| ツール | 用途 |
|--------|------|
| RSpec | テストフレームワーク |
| FactoryBot | テストデータ生成 |
| Faker | ダミーデータ生成 |
| Shoulda Matchers | バリデーション・関連付けのマッチャー |
| Capybara + Selenium | System spec（`:js` は headless Chrome、フルスタック版のみ） |
| rspec-retry | `:js` System spec のフレーク対策（リトライ） |
| SimpleCov | 行・分岐カバレッジの計測（可視化のみ。上記「カバレッジの計測」） |

> N+1 の回帰ガードは gem ではなく `spec/support/query_counter.rb`（`ActiveSupport::Notifications` の `sql.active_record` を購読して SQL 本数を数えるヘルパー）で行う。クエリキャッシュにヒットした SQL も数に含め、キャッシュ任せで N+1 を見逃さないようにする。
>
> ステータス遷移を業務制約にしたため、`create(:task, status: :completed)` は作成時の検証で弾かれる。途中状態のタスクは FactoryBot の trait（`create(:task, :in_progress)` / `create(:task, :completed)`）で作り、trait 側が許可された遷移を実際に踏む（両アプリ）。
>
> テスト間の DB クリーンアップは RSpec の `use_transactional_fixtures`（トランザクションロールバック）を使用する（`database_cleaner` gem は導入していない）。
