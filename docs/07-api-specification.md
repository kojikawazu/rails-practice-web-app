# API仕様書（API Specification）

※ Project 2（Rails APIモード / `rails-task-api-web-app`）の実装仕様。認証は **JWT（Bearer トークン）**。

## 目次

- [エンドポイント一覧](#エンドポイント一覧)
- [リクエスト/レスポンス形式](#リクエストレスポンス形式)
  - [例: ログイン（JWT 発行）](#例-ログインjwt-発行)
  - [例: タスク作成](#例-タスク作成)
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

> **実装方針**: Controller はロジックを `app/services/`（`AuthService` / `ProjectService` / `TaskService`）に委譲し、レスポンス整形（`render_result`）に専念する。リソース未存在（404）は `ApplicationController` の `rescue_from ActiveRecord::RecordNotFound` で一元処理し、`e.model` から `{ error: "Project not found" }` / `{ error: "Task not found" }` を返す。エラー JSON の形（`errors` 複数形 vs `error` 単数形）は現行契約を維持しており、完全な統一は将来課題とする。

エラーレスポンスは内容に応じて 2 形態を使い分ける。

**バリデーションエラー（422）** — 複数メッセージを配列で返す（`errors`・複数形）:

```json
{
  "errors": ["Title can't be blank"]
}
```

> **ステータス遷移違反も 422 で返す**。`status` は任意の値へ変更できず、`not_started → in_progress → completed` と `completed → in_progress`（差し戻し）のみ許可する。作成時は `not_started` のみ指定できる（省略時の既定値も `not_started`）。違反時のレスポンス例:
>
> ```json
> { "errors": ["Status は not_started から completed へは変更できません（許可: in_progress）"] }
> ```
>
> 規則の詳細は `03-functional-specification.md` の「ステータス遷移」を参照する。

**認証エラー（401）・リソース未存在（404）** — 単一メッセージを返す（`error`・単数形）:

```json
{ "error": "Unauthorized" }
{ "error": "Project not found" }
{ "error": "メールアドレスまたはパスワードが正しくありません。" }
```

| ステータスコード | 意味 | レスポンス形式 |
|-----------------|------|---------------|
| 200 | 成功 | リソース JSON |
| 201 | 作成成功（signup / create） | リソース JSON |
| 204 | 削除成功（destroy・`head :no_content`） | ボディ無し |
| 401 | 未認証（トークン無効 / ログイン失敗） | `{ "error": "..." }` |
| 404 | リソースが見つからない（他ユーザーのリソース含む） | `{ "error": "..." }` |
| 422 | バリデーションエラー | `{ "errors": [...] }` |
