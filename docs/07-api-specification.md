# API仕様書（API Specification）

※ Project 2（Rails APIモード / `rails-task-api-web-app`）の実装仕様。認証は **JWT（Bearer トークン）**。

## 目次

- [エンドポイント一覧](#エンドポイント一覧)
- [リクエスト/レスポンス形式](#リクエストレスポンス形式)
  - [例: ログイン（JWT 発行）](#例-ログインjwt-発行)
  - [例: タスク作成](#例-タスク作成)
  - [リソースの公開属性](#リソースの公開属性)
- [認証](#認証)
  - [CORS](#cors)
- [エラーハンドリング](#エラーハンドリング)

## エンドポイント一覧

| メソッド | パス | 説明 | 認証 |
|----------|------|------|------|
| POST | /api/v1/signup | ユーザー登録（成功時に JWT を発行） | 不要 |
| POST | /api/v1/login | ログイン（成功時に JWT を発行） | 不要 |
| GET | /api/v1/projects | プロジェクト一覧 | 必要 |
| POST | /api/v1/projects | プロジェクト作成 | 必要 |
| GET | /api/v1/projects/:id | プロジェクト詳細 | 必要 |
| PATCH/PUT | /api/v1/projects/:id | プロジェクト更新 | 必要 |
| DELETE | /api/v1/projects/:id | プロジェクト削除 | 必要 |
| GET | /api/v1/projects/:project_id/tasks | タスク一覧 | 必要 |
| POST | /api/v1/projects/:project_id/tasks | タスク作成 | 必要 |
| GET | /api/v1/projects/:project_id/tasks/:id | タスク詳細 | 必要 |
| PATCH/PUT | /api/v1/projects/:project_id/tasks/:id | タスク更新 | 必要 |
| DELETE | /api/v1/projects/:project_id/tasks/:id | タスク削除 | 必要 |

> **ログアウトエンドポイントは無い**: JWT はステートレスのため、ログアウトはクライアント側でトークンを破棄して実現する（サーバー側のトークン失効は未実装）。
> プロジェクト/タスクは `resources` ルーティングで生成され、更新は `PATCH` / `PUT` の両方を受け付ける。

## リクエスト/レスポンス形式

### 例: ログイン（JWT 発行）

**Request:**

```json
POST /api/v1/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password"
}
```

**Response (200 OK):**

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": { "id": 1, "name": "山田太郎", "email": "user@example.com" }
}
```

> ユーザー登録（`POST /api/v1/signup`）は `{ "user": { "name", "email", "password", "password_confirmation" } }` を受け取り、成功時に同じ `{ token, user }` 構造を **201 Created** で返す。
> 以降の認証必須エンドポイントは、取得した token を `Authorization: Bearer <token>` ヘッダーで送信する。

### 例: タスク作成

**Request:**

```json
POST /api/v1/projects/1/tasks
Content-Type: application/json

{
  "task": {
    "title": "READMEを書く",
    "status": "not_started",
    "due_date": "2026-04-10"
  }
}
```

**Response (201 Created):**

```json
{
  "id": 1,
  "title": "READMEを書く",
  "status": "not_started",
  "due_date": "2026-04-10",
  "project_id": 1,
  "created_at": "2026-04-07T10:00:00.000Z",
  "updated_at": "2026-04-07T10:00:00.000Z"
}
```

### リソースの公開属性

レスポンスに含める属性は `app/serializers/` の各 Serializer が `ATTRIBUTES` で列挙したものだけ（allowlist）。モデルを直接 `render json:` しないため、**カラムを追加しても API レスポンスには自動で露出しない**。公開する場合は Serializer に属性を追加し、本表と request spec を同時に更新する。

| リソース | Serializer | 公開属性（この順で返す） | 返すエンドポイント |
|---|---|---|---|
| User | `UserSerializer` | `id`, `name`, `email` | signup / login の `user` |
| Project | `ProjectSerializer` | `id`, `title`, `description`, `user_id`, `created_at`, `updated_at` | projects の index（配列）/ show / create / update |
| Task | `TaskSerializer` | `id`, `title`, `status`, `due_date`, `project_id`, `created_at`, `updated_at` | tasks の index（配列）/ show / create / update |

- `status` は enum のキー文字列（`not_started` / `in_progress` / `completed`）、`due_date` は `YYYY-MM-DD`、日時は ISO 8601（UTC・ミリ秒）で返す。
- `password_digest` などの認証情報は返さない。
- 削除（destroy）はボディ無しの `204 No Content`。

## 認証

- 認証方式は **JWT（Bearer トークン）**。`rails new --api` はセッション/Cookie ミドルウェアが無効なため、Cookie に依存しないトークン認証を採用する。
- `signup` / `login` 成功時に JWT を発行する（`JsonWebToken` モジュールで encode/decode）。
- 認証必須エンドポイントは `Authorization: Bearer <token>` ヘッダーを `ApplicationController#authenticate_user!`（`before_action`）で検証する。トークンが無効・ユーザー未存在の場合は `401 Unauthorized`。
- **受理するヘッダーは Bearer スキームのみ**（`Authorization: Bearer <token>`）。スキーム名の大文字小文字は区別しない（RFC 7235: auth-scheme is case-insensitive）が、下記は載っている JWT が有効でも `401` を返す。

  | ヘッダー | 結果 | 理由 |
  |---|---|---|
  | `Bearer <token>` / `bearer <token>` | 200 | 契約どおりの搬送方式 |
  | （ヘッダー無し） | 401 | 資格情報が無い |
  | `<token>`（スキーム無しの生トークン） | 401 | 認証方式が合意されていない |
  | `Basic <token>` | 401 | Bearer 以外のスキーム |
  | `Anything ignored <token>` / `Bearer <token> extra` | 401 | `credentials = auth-scheme 1*SP token68` の形に合わない |
  | `Bearer`（トークン無し） | 401 | 資格情報が空 |

- `AuthController` のみ `skip_before_action :authenticate_user!` で認証を除外する。
- Bearer トークン認証（Cookie 不使用）のため CSRF トークンは不要。

### CORS

`rack-cors`（`config/initializers/cors.rb`）で許可オリジンを明示する。

- 許可オリジン: `http://localhost:3000`（外部フロント想定）/ `http://localhost:3099`（フルスタック版）
- メソッド: `GET / POST / PUT / PATCH / DELETE / OPTIONS / HEAD`
- レスポンスで `Authorization` ヘッダーを expose する（クライアントが発行トークンを読めるように）

## エラーハンドリング

> **実装方針**: Controller はロジックを `app/services/`（`AuthService` / `ProjectService` / `TaskService`）に委譲し、レスポンス整形（`render_result`）に専念する。Service は失敗を HTTP ステータスではなく**理由（`code`）**で返し、`code` から HTTP ステータスとレスポンスの形への変換は `ErrorSerializer` が一元的に担う（#147）。

API が返すエラーは、**すべて次の 1 形態**で返す。

```json
{
  "error": {
    "code": "validation_failed",
    "message": "入力内容に誤りがあります",
    "details": ["Title can't be blank"]
  }
}
```

| キー | 型 | 説明 |
|---|---|---|
| `code` | string | 機械可読な識別子。**クライアントはこれで分岐する**（下表に閉じる） |
| `message` | string | 人に見せる文言。契約ではないため、変更しても互換性を壊さない |
| `details` | string[] | バリデーションの内訳。`validation_failed` のときだけ付き、それ以外では**キーごと無い**（`null` は返さない） |

| `code` | ステータス | `message` | 発生条件 |
|---|---|---|---|
| `bad_request` | 400 | `Bad request` | 必須パラメータの欠落（`params.require`）・壊れた JSON。パーサのメッセージには送られた本文の断片が入るため、message は固定で応答に反射させない |
| `unauthorized` | 401 | `Unauthorized` | トークンが無い・無効・期限切れ、ユーザーが存在しない |
| `invalid_credentials` | 401 | `メールアドレスまたはパスワードが正しくありません。` | ログイン失敗。メール不在とパスワード誤りを区別しない（列挙攻撃対策） |
| `not_found` | 404 | `Project not found` / `Task not found` / `Not found` | リソースが無い（他ユーザーのリソースを含む。存在を秘匿する）・存在しないルート |
| `validation_failed` | 422 | `入力内容に誤りがあります` | バリデーションエラー・ステータス遷移違反。内訳は `details` |
| `rate_limited` | 429 | `Too many requests` | レートリミット超過（login / signup は 180 秒あたり 10 回、API 全体は 60 秒あたり 300 回。同一 IP 単位・環境変数で調整可）。`Retry-After` ヘッダーに再試行までの秒数 |
| `internal_error` | 500 | `Internal server error` | 想定外の例外。例外の内容は応答に含めない |

> **ステータス遷移違反も 422（`validation_failed`）で返す**。`status` は任意の値へ変更できず、`not_started → in_progress → completed` と `completed → in_progress`（差し戻し）のみ許可する。作成時は `not_started` のみ指定できる（省略時の既定値も `not_started`）。違反時のレスポンス例:
>
> ```json
> { "error": { "code": "validation_failed", "message": "入力内容に誤りがあります", "details": ["Status は not_started から completed へは変更できません（許可: in_progress）"] } }
> ```
>
> 規則の詳細は `03-functional-specification.md` の「ステータス遷移」を参照する。

| ステータスコード | 意味 | レスポンス形式 |
|-----------------|------|---------------|
| 200 | 成功 | リソース JSON |
| 201 | 作成成功（signup / create） | リソース JSON |
| 204 | 削除成功（destroy・`head :no_content`） | ボディ無し |
| 400 / 401 / 404 / 422 / 429 / 500 | エラー（上表） | `{ "error": { "code", "message", "details"? } }` |

### エラーの出口

| 出口 | 対象 | 環境 |
|---|---|---|
| `ApplicationController`（`rescue_from` と `render_error`） | コントローラーに届く想定内のエラー（400 / 401 / 404 / 422 / 429） | **全環境で同じ形** |
| `ErrorsController`（`config.exceptions_app`） | コントローラーに届かないルーターの 404、想定外の 500 | 詳細表示がオフ（本番相当）のときだけ。development / test の既定ではデバッグ表示を優先する |

- `rescue_from StandardError` は使わない。想定外の例外を別のエラーに見せかけず、500 として `exceptions_app` へ流す。
- `ParseError`（壊れた JSON）は、パラメータが `params` を最初に読んだ時点で解析される（遅延評価）ため、コントローラーの `rescue_from` で捕捉できる。

### 破壊的変更（#147）

v1 のエラー形式を統一した。外部の利用者がいない学習用 API のため、バージョンを上げずに v1 のまま変更した（利用者がいる API であれば、`/api/v2` の新設か、新旧の形を併記する移行期間が必要になる）。

| ケース | 変更前 | 変更後 |
|---|---|---|
| 422 | `{ "errors": ["..."] }` | `{ "error": { "code": "validation_failed", "message": "...", "details": ["..."] } }` |
| 401 | `{ "error": "Unauthorized" }` / `{ "error": "メールアドレスまたは…" }` | `code`: `unauthorized` / `invalid_credentials` |
| 404 | `{ "error": "Project not found" }` | `code`: `not_found`（message は同じ） |
| 429 | `{ "error": "Too many requests" }` | `code`: `rate_limited` |
| 400 | `{ "status": 400, "error": "Bad Request" }`（必須パラメータの欠落）・空の text/html（壊れた JSON） | `code`: `bad_request` |
| ルートの 404 / 500 | 空の text/html（本番） | `code`: `not_found` / `internal_error` |
