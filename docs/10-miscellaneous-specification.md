# その他仕様書（Miscellaneous Specification）

## 目次

- [用語集](#用語集)
  - [Rails 基礎（両プロジェクト共通）](#rails-基礎両プロジェクト共通)
  - [フルスタック版（MVC / Turbo / セッション）](#フルスタック版mvc--turbo--セッション)
  - [API 版（API モード / JWT）](#api-版api-モード--jwt)
  - [テスト](#テスト)
  - [ツール](#ツール)
- [参考資料](#参考資料)
- [付録](#付録)
  - [フルスタック vs APIモード 比較](#フルスタック-vs-apiモード-比較)

## 用語集

このプロジェクトで使う用語を、実装例と結び付けて説明する。用語を見つけたら、まずここで「何か」と「このアプリではどこで使うか」を確認する。

このリポジトリは同じ題材（プロジェクト＋タスク）を **フルスタック版**（`rails-task-fullstack-web-app`）と **API 版**（`rails-task-api-web-app`）の 2 つで実装している。同じ用語でも実装が分かれるものは、両方の実装をリンクして対比できるようにしている。

### Rails 基礎（両プロジェクト共通）

| 用語 | 意味 | このプロジェクトでの例 |
|---|---|---|
| MVC | Model（データ・業務ルール）／View（表示）／Controller（入出力の交通整理）へ責務を分ける Rails の基本構造。API 版には View 層がない。 | [`app/models/`](../rails-task-fullstack-web-app/app/models/)、[`app/views/`](../rails-task-fullstack-web-app/app/views/)、[`app/controllers/`](../rails-task-fullstack-web-app/app/controllers/)。 |
| ActiveRecord | Rails の ORM。DB テーブルを Ruby オブジェクトとして扱い、バリデーション・リレーション・スコープを提供する。 | [`task.rb`](../rails-task-fullstack-web-app/app/models/task.rb)、[`project.rb`](../rails-task-fullstack-web-app/app/models/project.rb)。 |
| Migration | DB スキーマの変更を Ruby コードで管理する仕組み。`rails db:migrate` で適用し、`down` でロールバックできる。 | 各プロジェクトの [`db/migrate/`](../rails-task-fullstack-web-app/db/migrate/)。規約は [`.claude/rules/database.md`](../.claude/rules/database.md)。 |
| Routing | URL と Controller アクションの対応表。`resources` で RESTful な 7 アクションを一括宣言し、`collection` / `member` で追加ルートを足す。 | [`config/routes.rb`（フルスタック）](../rails-task-fullstack-web-app/config/routes.rb)、[`config/routes.rb`（API）](../rails-task-api-web-app/config/routes.rb)。 |
| ネストルーティング | 親子関係を URL に表す書き方（`resources :projects do resources :tasks end` → `/projects/:project_id/tasks/:id`）。親を必ず経由するため、認可スコープの起点にもなる。 | タスクは常にプロジェクト配下（両プロジェクトの `routes.rb`）。 |
| Strong Parameters | マスアサインメント脆弱性を防ぐ仕組み。`params.require(...).permit(...)` で許可カラムだけを抽出する。 | [`users_controller.rb`](../rails-task-fullstack-web-app/app/controllers/users_controller.rb) の `user_params`。 |
| enum | 取り得る値が閉じている区分を、整数カラム + シンボル名で宣言する ActiveRecord の機能。文字列の直書きを避けられる。 | Task の `status`（`not_started` / `in_progress` / `completed`）＝[`task.rb`](../rails-task-fullstack-web-app/app/models/task.rb)。 |
| association scope | `current_user.projects.find(id)` のように、関連経由でレコードを引く書き方。他ユーザーのリソースは自動的に見つからず `RecordNotFound` になるため、**認可と存在秘匿（404）を同時に満たす**。 | [`project_service.rb`（API）](../rails-task-api-web-app/app/services/project_service.rb) の `fetch`、フルスタック版 Controller の `set_project`。 |
| Service オブジェクト | Controller から業務ロジックを切り出す層（`app/services/`）。Controller を薄く保ち、Fat Model も避けるための置き場。 | [`task_service.rb`](../rails-task-fullstack-web-app/app/services/task_service.rb)、[`auth_service.rb`](../rails-task-api-web-app/app/services/auth_service.rb)。 |
| has_secure_password | bcrypt でパスワードをハッシュ化し、`authenticate` を生やす Rails の認証ヘルパー。平文パスワードを DB に持たない。 | [`user.rb`](../rails-task-fullstack-web-app/app/models/user.rb)（両プロジェクト共通）。 |
| `rescue_from` | Controller で発生した例外を種類ごとに一括処理する仕組み。各アクションに `rescue` を散らさず、横断的な失敗（404 等）を 1 箇所に集約する。 | [`application_controller.rb`（API）](../rails-task-api-web-app/app/controllers/application_controller.rb) の `ActiveRecord::RecordNotFound` → 404。 |
| `before_action` | アクションの前に共通処理を差し込むフック。認証チェックやレコード取得の前処理に使う。 | `require_login`（フルスタック）／`authenticate_user!`（API）。 |
| docker-compose | 複数コンテナの定義・起動を管理するツール。このリポジトリでは PostgreSQL 用。 | [`docker-compose.yml`](../docker-compose.yml)。 |
| database.yml / pg gem | 接続設定ファイルと PostgreSQL ドライバ。環境ごとに接続先を分ける。 | 各プロジェクトの `config/database.yml`、`Gemfile` の `pg`。 |

### フルスタック版（MVC / Turbo / セッション）

| 用語 | 意味 | このプロジェクトでの例 |
|---|---|---|
| ERB | Embedded Ruby。HTML に Ruby を埋め込むテンプレートエンジン。 | [`app/views/tasks/`](../rails-task-fullstack-web-app/app/views/tasks/) の `*.html.erb`。 |
| パーシャル | `_form.html.erb` のように `_` 始まりで切り出す再利用可能な View 部品。new / edit で同じフォームを共有する。 | [`tasks/_form.html.erb`](../rails-task-fullstack-web-app/app/views/tasks/_form.html.erb)。 |
| `form_with` | フォームを生成する Rails ヘルパー。モデルの永続化状態（`persisted?`）から POST / PATCH と送信先を自動で決める。 | [`projects/_form.html.erb`](../rails-task-fullstack-web-app/app/views/projects/_form.html.erb)。 |
| Turbo | Hotwire の一部で、フォーム送信・リンク遷移を JavaScript で横取りしてページ全体の再読み込みを避ける仕組み。**確認画面のように 200 で別画面を返す遷移とは相性が悪い**ため、該当箇所は `data: { turbo: false }` で従来のフルページ送信に戻している。 | [`tasks/_form.html.erb`](../rails-task-fullstack-web-app/app/views/tasks/_form.html.erb)、[`projects/confirm.html.erb`](../rails-task-fullstack-web-app/app/views/projects/confirm.html.erb)。 |
| `turbo_confirm` | 削除リンクなどで確認ダイアログを出す Turbo のデータ属性。**ブラウザのダイアログを伴うため rack_test では検証できず、`:js` 付き system spec が必要**になる。 | [`tasks/show.html.erb`](../rails-task-fullstack-web-app/app/views/tasks/show.html.erb) の削除ボタン。 |
| PRG（Post/Redirect/Get） | POST の処理後に画面を直接返さず redirect し、GET で表示させるパターン。リロードによる二重送信を防ぐ。 | ログイン成功時の `redirect_to projects_path`＝[`sessions_controller.rb`](../rails-task-fullstack-web-app/app/controllers/sessions_controller.rb)、プロジェクト新規確認画面のリダイレクト方式＝[`routes.rb`](../rails-task-fullstack-web-app/config/routes.rb)。 |
| session | Cookie を介してリクエストをまたいで値を保持する仕組み。このアプリでは認証状態（`session[:user_id]`）と、確認画面へ持ち回る入力値の退避に使う。 | [`application_controller.rb`](../rails-task-fullstack-web-app/app/controllers/application_controller.rb) の `current_user`、[`sessions_controller.rb`](../rails-task-fullstack-web-app/app/controllers/sessions_controller.rb)。 |
| flash / `flash.now` | 次のリクエストへ渡すメッセージ（`flash`）と、**今回の render だけで表示する**メッセージ（`flash.now`）。redirect には `flash`、`render` には `flash.now` を使う。 | [`sessions_controller.rb`](../rails-task-fullstack-web-app/app/controllers/sessions_controller.rb) の成功／失敗分岐。 |
| 確認画面フロー | 入力 → 確認 → 確定の 3 ステップ。確認ステップでは DB に保存せず `valid?` で検証のみ行う。 | [`users_controller.rb#confirm`](../rails-task-fullstack-web-app/app/controllers/users_controller.rb)、[`tasks_controller.rb#confirm`](../rails-task-fullstack-web-app/app/controllers/tasks_controller.rb)。 |
| jbuilder | JSON レスポンスをテンプレートで組み立てる仕組み。ActiveRecord を直接返さず、公開してよい属性だけを選べる。 | [`tasks/_task.json.jbuilder`](../rails-task-fullstack-web-app/app/views/tasks/_task.json.jbuilder)。 |
| Importmap / Stimulus | ビルドツール無しで JS モジュールを読み込む仕組み（Importmap）と、HTML の data 属性から JS を紐付ける Hotwire のフレームワーク（Stimulus）。 | [`app/javascript/controllers/flatpickr_controller.js`](../rails-task-fullstack-web-app/app/javascript/controllers/flatpickr_controller.js)。 |
| Active Storage | ファイル添付を扱う Rails の標準機能。ファイル実体は `blob`、レコードとの結び付きは `attachment` として別テーブルで管理する。 | Task の `has_many_attached :images`＝[`task.rb`](../rails-task-fullstack-web-app/app/models/task.rb)。 |
| `signed_id` | blob を指す署名付き ID。**推測不能な ID ではなく「その添付を使ってよい」ことを表す capability** として扱う。ファイル input は確認画面の hidden で持ち回れないため、確認ステップで一旦 blob 化し `signed_id` を round-trip させている。 | [`task_image_service.rb`](../rails-task-fullstack-web-app/app/services/task_image_service.rb)、[`tasks/confirm.html.erb`](../rails-task-fullstack-web-app/app/views/tasks/confirm.html.erb)。 |
| staging / attach / purge | 画像処理を 3 段に分ける設計。`stage` は全ファイルの事前検証に通った場合のみ blob を作り（1 つでも不正なら blob を作らず**オーファンを防ぐ**）、`attach` は保存時に結び付け、`purge` は保存成功後に削除する。 | [`task_image_service.rb`](../rails-task-fullstack-web-app/app/services/task_image_service.rb)。 |

### API 版（API モード / JWT）

| 用語 | 意味 | このプロジェクトでの例 |
|---|---|---|
| API モード | `rails new --api` で生成する View 層なしの構成。Cookie・セッション・CSRF 保護など、ブラウザ向けミドルウェアを外して軽量化する。 | [`application_controller.rb`](../rails-task-api-web-app/app/controllers/application_controller.rb) が `ActionController::API` を継承。 |
| API バージョニング | `/api/v1/` のようにバージョンを URL に持たせ、後方互換を壊さず新版を追加できるようにする設計。 | [`routes.rb`](../rails-task-api-web-app/config/routes.rb) の `namespace :api do namespace :v1`。 |
| JWT（JSON Web Token） | ユーザー識別情報を署名付きでクライアントに持たせるトークン。サーバー側にセッションを持たない（ステートレス）ため、API 版の認証方式に採用している。 | [`json_web_token.rb`](../rails-task-api-web-app/app/lib/json_web_token.rb)。 |
| Bearer トークン | `Authorization: Bearer <token>` ヘッダーでトークンを送る方式。Cookie を使わないため **CSRF 対策が不要**になる一方、トークンの保管はクライアント側の責任になる。 | [`application_controller.rb#authenticate_user!`](../rails-task-api-web-app/app/controllers/application_controller.rb)。 |
| `ApplicationService::Result` | Service の実行結果（成否・データ・エラー・HTTP ステータス）を表す値オブジェクト。Controller は例外や真偽値でなく Result を見て render を分岐する。 | [`application_service.rb`](../rails-task-api-web-app/app/services/application_service.rb)、[`tasks_controller.rb`](../rails-task-api-web-app/app/controllers/api/v1/tasks_controller.rb) の `render_result`。 |
| 統一エラーレスポンス | エラー時の JSON 構造を揃える方針。認証失敗・404 は `{ error: ... }`、バリデーション失敗は `{ errors: [...] }`。 | [`application_controller.rb`](../rails-task-api-web-app/app/controllers/application_controller.rb)。 |
| 存在秘匿（404） | 他ユーザーのリソースへアクセスされたとき、403 ではなく 404 を返して**リソースの存在自体を漏らさない**扱い。association scope の `find` が投げる `RecordNotFound` をそのまま 404 に写している。 | [`project_service.rb`](../rails-task-api-web-app/app/services/project_service.rb)、[`authorization_isolation_spec.rb`](../rails-task-api-web-app/spec/scenarios/authorization_isolation_spec.rb)。 |

### テスト

| 用語 | 意味 | このプロジェクトでの例 |
|---|---|---|
| RSpec | このリポジトリで使うテストフレームワーク。**Minitest（`test/`）は使わない。** | 各プロジェクトの [`spec/`](../rails-task-fullstack-web-app/spec/)。 |
| model spec | バリデーション・リレーション・スコープを検証するテスト。 | [`spec/models/task_spec.rb`](../rails-task-fullstack-web-app/spec/models/task_spec.rb)。 |
| request spec | HTTP リクエストを投げ、ステータス・レスポンス・リダイレクトを検証するテスト。**認可・未認証・不正入力の境界はここで検証する**（system spec では代替しない）。 | [`spec/requests/tasks_spec.rb`](../rails-task-fullstack-web-app/spec/requests/tasks_spec.rb)、[`spec/requests/api/v1/tasks_spec.rb`](../rails-task-api-web-app/spec/requests/api/v1/tasks_spec.rb)。 |
| system spec | Capybara でブラウザ操作をシミュレートし、画面の遷移・表示を検証するテスト。フルスタック版のみ。 | [`spec/system/confirm_flows_spec.rb`](../rails-task-fullstack-web-app/spec/system/confirm_flows_spec.rb)。 |
| シナリオテスト | 複数機能を横断する業務ジャーニーを request spec ベースで検証するテスト。API 版の `spec/scenarios/`。 | [`user_task_journey_spec.rb`](../rails-task-api-web-app/spec/scenarios/user_task_journey_spec.rb)。 |
| rack_test / selenium | Capybara のドライバ。`rack_test` はブラウザを起動せず高速だが JS を実行しない。`selenium`（headless Chrome）は実ブラウザを動かす。**既定は rack_test、`:js` タグの spec のみ selenium**。 | [`spec/support/capybara.rb`](../rails-task-fullstack-web-app/spec/support/capybara.rb)。 |
| `:js` タグ | selenium で駆動する spec に付けるタグ。Turbo の確認ダイアログなど **rack_test では検証できない理由**を必ずコメントに残す。通常の `rspec` 実行では除外され、`rspec --tag js` で明示的に実行する。 | [`confirm_flows_js_spec.rb`](../rails-task-fullstack-web-app/spec/system/confirm_flows_js_spec.rb)、[`spec/support/capybara.rb`](../rails-task-fullstack-web-app/spec/support/capybara.rb)。 |
| フレーク（flaky） | 実装を変えていないのに成功・失敗が揺れるテスト。実ブラウザ往復のタイミング差で起きやすく、待機時間の延長やリトライで吸収する。**対象を限定し、本物の失敗を隠さないこと**が条件。 | `Capybara.default_max_wait_time = 10` と、`:js` のみ 3 回リトライする [`spec/support/rspec_retry.rb`](../rails-task-fullstack-web-app/spec/support/rspec_retry.rb)。 |
| FactoryBot | テストデータの生成を定義で管理する gem。各テストが必要な属性だけを上書きして使う。 | [`spec/factories/`](../rails-task-fullstack-web-app/spec/factories/)。 |
| Shoulda Matchers | `validate_presence_of` のようにバリデーション・リレーションを 1 行で検証できる matcher 集。model spec で使う。 | [`spec/support/shoulda_matchers.rb`](../rails-task-fullstack-web-app/spec/support/shoulda_matchers.rb)。 |
| `spec/support/` | 共通ヘルパー・shared examples・設定の置き場。**セットアップは共通化してよいが、テストの期待値・ケース内容は共通化しない**（重複してでも読んで分かることを優先する）。 | [`jwt_helper.rb`](../rails-task-api-web-app/spec/support/jwt_helper.rb)、[`system_login_helper.rb`](../rails-task-fullstack-web-app/spec/support/system_login_helper.rb)。 |

### ツール

| 用語 | 意味 | このプロジェクトでの例 |
|---|---|---|
| RuboCop | Ruby の Linter / Formatter。このリポジトリは `rubocop-rails-omakase` に従い、独自オーバーライドを原則入れない。 | [`.rubocop.yml`（フルスタック）](../rails-task-fullstack-web-app/.rubocop.yml)、[`.rubocop.yml`（API）](../rails-task-api-web-app/.rubocop.yml)。運用は [`static-analysis.md`](../.claude/rules/static-analysis.md)。 |
| Brakeman | Rails 向けの静的セキュリティ解析ツール。SQL インジェクション・XSS 等のパターンを検出する。 | 両プロジェクトの `Gemfile`（development / test グループ）に導入済み。ルール上は CI 必須（[`static-analysis.md`](../.claude/rules/static-analysis.md)）だが、現状 [`ci.yml`](../.github/workflows/ci.yml) のジョブは markdown lint と RSpec のみ。 |
| bundler-audit | `Gemfile.lock` の gem に既知の脆弱性がないか照合するツール。 | Brakeman と同じく `Gemfile` に導入済み・CI ジョブは未追加。 |
| YARD | Ruby のドキュメントコメント形式（`@param` / `@return` / `@raise`）。`app/` 配下のクラス・public メソッドに付与する。 | 規約は [`.claude/rules/coding-standards.md`](../.claude/rules/coding-standards.md)。 |
| scaffold | Model / Controller / View / Migration / Route を一括生成する Rails のコード生成機能。 | 初期実装の出発点として使用（以降は手で調整している）。 |

## 参考資料

- [Ruby on Rails Guides](https://guides.rubyonrails.org/)
- [RSpec公式ドキュメント](https://rspec.info/)
- [PostgreSQL公式ドキュメント](https://www.postgresql.org/docs/)
- [Docker Compose公式ドキュメント](https://docs.docker.com/compose/)

## 付録

### フルスタック vs APIモード 比較

| 観点 | フルスタック | APIモード |
|------|-------------|-----------|
| View | ERBテンプレート | なし（JSON） |
| ミドルウェア | フルセット | API用に軽量化 |
| CSRF保護 | あり（Rails デフォルト） | なし（Bearer トークン認証・Cookie 不使用） |
| セッション | Cookie（`session[:user_id]`） | 使わない（JWT・ステートレス） |
| 認証方式 | has_secure_password + セッション | has_secure_password + JWT（`Authorization: Bearer`） |
| 学習目的 | Railsの規約を体感 | API設計パターンを理解 |
