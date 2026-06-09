# API仕様書（API Specification）

※ Project 2（Rails APIモード）で使用。Project 1（フルスタック）完了後に詳細化する。

## 目次

- [エンドポイント一覧](#エンドポイント一覧)
- [リクエスト/レスポンス形式](#リクエストレスポンス形式)
  - [例: タスク作成](#例-タスク作成)
- [認証](#認証)
- [エラーハンドリング](#エラーハンドリング)

## エンドポイント一覧

| メソッド | パス | 説明 |
|----------|------|------|
| POST | /api/v1/users | ユーザー登録 |
| POST | /api/v1/sessions | ログイン |
| DELETE | /api/v1/sessions | ログアウト |
| GET | /api/v1/projects | プロジェクト一覧 |
| POST | /api/v1/projects | プロジェクト作成 |
| GET | /api/v1/projects/:id | プロジェクト詳細 |
| PATCH | /api/v1/projects/:id | プロジェクト更新 |
| DELETE | /api/v1/projects/:id | プロジェクト削除 |
| GET | /api/v1/projects/:project_id/tasks | タスク一覧 |
| POST | /api/v1/projects/:project_id/tasks | タスク作成 |
| GET | /api/v1/projects/:project_id/tasks/:id | タスク詳細 |
| PATCH | /api/v1/projects/:project_id/tasks/:id | タスク更新 |
| DELETE | /api/v1/projects/:project_id/tasks/:id | タスク削除 |

## リクエスト/レスポンス形式

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

- `rails new --api` ではセッション/Cookieミドルウェアがデフォルトで無効
- 認証方式は Project 2 着手時に決定する（候補: セッションミドルウェア追加 or トークン認証）
- 未認証時は `401 Unauthorized` を返す

## エラーハンドリング

```json
{
  "errors": ["Title can't be blank"]
}
```

| ステータスコード | 意味 |
|-----------------|------|
| 200 | 成功 |
| 201 | 作成成功 |
| 204 | 削除成功 |
| 401 | 未認証 |
| 404 | リソースが見つからない |
| 422 | バリデーションエラー |
