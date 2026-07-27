---
description: ActiveRecord 命名規約・監査列の自動設定・マイグレーション・クエリ規約
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
| created_by | STRING NULL | 作成者（操作ユーザー。監査要件がある場合） |
| updated_by | STRING NULL | 更新者（操作ユーザー。監査要件がある場合） |

## 監査列

監査列（`created_at` / `updated_at` / `created_by` / `updated_by` / `deleted_at`）は **Rails の機構で自動設定する**。アプリケーションコードで値を組み立てない。

- **手動代入を禁止**する。`record.update(updated_at: Time.current)` のようにモデル・サービス層で監査列へ値を書かない。更新時刻だけ進めたい場合は `touch` を使う。
- 日時カラムはマイグレーションで **`t.timestamps`** により定義する（`created_at` / `updated_at` の名前を変えない。Rails の自動タイムスタンプが効かなくなる）。
- `updated_at` の自動更新を止める `record.save(touch: false)` は、明確な理由がある場合に限る。
- 操作ユーザー（`created_by` / `updated_by`）を持つ場合は、**`ActiveSupport::CurrentAttributes`（例: `Current.user`）＋ concern の `before_save` コールバックで自動注入**する。各コントローラ・サービスで個別に詰めない。
- 監査列の付与ロジックは **concern（例: `Auditable`）に集約**し、`include` して使う。モデルごとにコールバックを書き写さない。
- 論理削除は `discard` / `paranoia` gem の API（`discard` / `destroy`）を使い、`deleted_at` へ手で日時を代入しない。
- **例外**: シードデータ・テストで日時を固定したい場合のみ明示指定を許容する（`travel_to` の利用を推奨）。本番コードパスに持ち込まない。

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
