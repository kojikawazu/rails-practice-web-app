---
description: ActiveRecord 命名規約・マイグレーション・クエリ規約
globs: "rails-task-fullstack-web-app/app/models/**,rails-task-fullstack-web-app/db/**,rails-task-api-web-app/app/models/**,rails-task-api-web-app/db/**"
---

---
description: ActiveRecord 命名規約・マイグレーション・クエリ規約
globs: "rails-task-fullstack-web-app/app/models/**,rails-task-fullstack-web-app/db/**,rails-task-api-web-app/app/models/**,rails-task-api-web-app/db/**"
---

# データベースルール（ActiveRecord）

## 命名規約

- モデル名: PascalCase・単数形（例: `User`, `TaskComment`）— Rails の規約に従う
- テーブル名: snake_case・複数形（例: `users`, `task_comments`）— Rails が自動変換
- カラム名: snake_case（例: `user_id`, `created_at`）
- 外部キー: `{モデル名単数}_id`（例: `user_id`, `task_id`）

## 共通カラム

すべてのテーブルに以下のカラムを含める:

| カラム | 型 | 説明 |
|--------|------|------|
| id | UUID or BIGINT | 主キー（Rails デフォルトは BIGINT の自動採番） |
| created_at | TIMESTAMP | 作成日時（`t.timestamps` で自動追加） |
| updated_at | TIMESTAMP | 更新日時（`t.timestamps` で自動追加） |
| deleted_at | TIMESTAMP NULL | 論理削除日時（要件に応じて。`paranoia` gem 等） |

## 論理削除

- `paranoia` gem または `discard` gem を使用する。
- `default_scope` での一括適用は避ける（明示的にスコープを適用する）。

## マイグレーション

- `rails generate migration` でマイグレーションを生成する。
- `rails db:migrate` で適用する。
- マイグレーションは冪等に書く。ロールバック（`down`）も定義する。

## クエリ

- ActiveRecord のクエリインターフェースを使用する。`find_by_sql` での文字列結合は禁止（プレースホルダ `?` または Hash 条件を使用）。
- N+1 問題に注意: `includes` / `preload` / `eager_load` で関連データを事前読み込みする。
