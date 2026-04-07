# 機能仕様書（Functional Specification）

## 機能詳細

### 認証機能

- `has_secure_password` を使用（Deviseは使わない）
- セッションベースの認証を手書きで実装
- ログイン状態の管理は `session[:user_id]` で行う

### プロジェクト管理

- ログインユーザーに紐づくプロジェクトのみ表示・操作可能
- プロジェクト削除時、紐づくタスクも連動削除（`dependent: :destroy`）

### タスク管理

- プロジェクトに紐づくタスクのCRUD
- ステータス: `not_started`（未着手）/ `in_progress`（進行中）/ `completed`（完了）
- 期日（due_date）の設定が可能

## ユーザーフロー

### 基本フロー

```
ユーザー登録 → ログイン → プロジェクト作成 → タスク追加 → タスク状態更新 → 完了
```

### 画面遷移

```
ログイン画面
  → プロジェクト一覧（トップ）
    → プロジェクト詳細（タスク一覧を含む）
      → タスク作成/編集
    → プロジェクト作成/編集
  → ユーザー登録画面
```

## UI/UX 仕様

- ERBテンプレートによるサーバーサイドレンダリング（Project 1）
- Railsデフォルトのレイアウト構成（`application.html.erb`）
- サイドバー + メインエリアのレイアウト（モック画面参照: `docs/mockups/`）
- フラッシュメッセージで操作結果をフィードバック
- フォームは `form_with` ヘルパーを使用
- 認証系画面（ログイン・登録）は中央寄せの単体レイアウト

## ビジネスロジック

### バリデーション

| モデル | フィールド | ルール |
|--------|-----------|--------|
| User | name | presence, length(max: 50) |
| User | email | presence, uniqueness, format |
| User | password | presence, length(min: 6) |
| Project | title | presence, length(max: 100) |
| Project | user_id | presence |
| Task | title | presence, length(max: 200) |
| Task | status | presence, inclusion(not_started, in_progress, completed) |
| Task | project_id | presence |

### ステータス遷移

```
not_started → in_progress → completed
                ↑                |
                └────────────────┘ (差し戻し可)
```
