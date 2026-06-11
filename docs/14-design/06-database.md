# DB（ActiveRecord）設計方針

> 命名規約の正本は `.claude/rules/database.md`、スキーマの実態は `docs/05-data-specification.md`。本書は**設計判断と本プロジェクト固有の方針**を補足する。

## 目次

- [命名規約](#命名規約)
- [マイグレーション](#マイグレーション)
- [共通カラムとスキーマ制約](#共通カラムとスキーマ制約)
  - [DB 制約 vs モデルバリデーション](#db-制約-vs-モデルバリデーション)
  - [enum](#enum)
- [関連と削除](#関連と削除)
- [クエリと N+1](#クエリと-n1)

[← 目次に戻る](README.md)

## 命名規約

Rails の規約に従う（自動変換に乗る）。

- モデル名: **PascalCase・単数形**（例: `User`, `Project`, `Task`）。
- テーブル名: **snake_case・複数形**（例: `users`, `projects`, `tasks`）。
- カラム名: **snake_case**（例: `user_id`, `created_at`）。
- 外部キー: `{モデル名単数}_id`（例: `user_id`, `project_id`）。

## マイグレーション

- スキーマ変更は `rails generate migration` で生成し、`rails db:migrate` で適用する。
- 共通の作成/更新日時は `t.timestamps`（`created_at` / `updated_at`）で付与する。
- 外部キーは `t.references ...` でインデックス + FK を張る（例: `tasks.project_id`）。
- **ロールバック（`down`）も書く**。非自明な変更（カラム入れ替え等）は `change` ではなく `up` / `down` を明示する。
  - 実例: フルスタック版の `due_date` → `start_date` / `end_date` 入れ替えは `up` / `down` を明示してロールバック安全にしている。

> **2 アプリのスキーマ差分は意図的**: フルスタック版のみ `start_date` / `end_date` と `preview_url`、Active Storage テーブルを持つ。API 版は単一 `due_date` のまま。差分は学習目的で残している（`docs/05` / `docs/07`）。

## 共通カラムとスキーマ制約

### DB 制約 vs モデルバリデーション

本プロジェクトは**学習目的で「DB 制約」と「モデルバリデーション」の差を意図的に残している**。設計判断として以下を方針とする。

- DB スキーマ（`schema.rb`）で物理的に `null: false` を持つのは、外部キー（`projects.user_id` / `tasks.project_id`）・`created_at` / `updated_at`・`users.email`（UNIQUE）など限定的。
- それ以外の必須性・初期値は**モデル層で担保**する。
  - `projects.title` / `tasks.title` の必須性は `presence` バリデーション。
  - `tasks.status` の初期値 `not_started`（0）は `after_initialize` コールバック（`set_default_status`）で設定（DB デフォルト無し）。
- 実プロダクトでは「必須・一意・FK は DB 制約でも二重に守る」のが堅牢だが、本リポジトリは ActiveRecord のバリデーション/コールバックの学習を優先してこの差を残す（`docs/05` の制約実態の表を参照）。

### enum

- `Task.status` は `enum` で `{ not_started: 0, in_progress: 1, completed: 2 }` を定義する。
- **`validate: true`** を付け、enum 定義外の値を inclusion バリデーションで弾く（不正値を 422 にする）。

## 関連と削除

- 親削除に連動する子は `dependent: :destroy` を付ける（`User has_many :projects` / `Project has_many :tasks`）。物理削除を採用し、論理削除（`paranoia` / `discard`）は本プロジェクトでは導入しない。
- 関連は Model に定義し、取得は関連経由でスコープする（認可と一体化。`04-api-backend.md` 参照）。

## クエリと N+1

- 必ず ActiveRecord のクエリインターフェースを使う。`find_by_sql` での文字列結合は禁止（プレースホルダ `?` または Hash 条件）。
- 一覧表示で関連を辿る場合は **N+1 に注意**し、`includes` / `preload` / `eager_load` で事前読み込みする。
