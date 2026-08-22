# データ仕様書（Data Specification）

## 目次

- [データモデル](#データモデル)
  - [3モデル構成](#3モデル構成)
- [ER図](#er図)
- [データベーススキーマ](#データベーススキーマ)
  - [users テーブル](#users-テーブル)
  - [projects テーブル](#projects-テーブル)
  - [tasks テーブル](#tasks-テーブル)
  - [インデックス](#インデックス)
- [クエリ設計](#クエリ設計)
- [画像添付（Active Storage）](#画像添付active-storage)
- [データフロー](#データフロー)

## データモデル

### 3モデル構成

```text
User
 └── has_many :projects
      └── has_many :tasks

Project
 └── belongs_to :user
 └── has_many :tasks

Task
 └── belongs_to :project
```

## ER図

```text
+------------+       +------------+       +------------+
|   users    |       |  projects  |       |   tasks    |
+------------+       +------------+       +------------+
| id (PK)    |──1:N──| id (PK)    |──1:N──| id (PK)    |
| name       |       | title      |       | title      |
| email      |       | description|       | status     |
| password   |       | user_id(FK)|       | start_date |
|   _digest  |       |            |       | end_date   |
|   _digest  |       | created_at |       | project_id |
| created_at |       | updated_at |       |       (FK) |
| updated_at |       +------------+       | created_at |
+------------+                            | updated_at |
                                          +------------+
```

## データベーススキーマ

### users テーブル

| カラム | 型 | 制約 | 備考 |
|--------|------|------|------|
| id | bigint | PK, NOT NULL | 自動採番 |
| name | string | NOT NULL | ユーザー名 |
| email | string | NOT NULL, UNIQUE | メールアドレス |
| password_digest | string | NOT NULL | bcryptハッシュ |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

### projects テーブル

| カラム | 型 | 制約 | 備考 |
|--------|------|------|------|
| id | bigint | PK, NOT NULL | 自動採番 |
| title | string | NOT NULL | プロジェクト名 |
| description | text | | 説明 |
| user_id | bigint | NOT NULL, FK | users.id |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

### tasks テーブル

| カラム | 型 | 制約 | 備考 |
|--------|------|------|------|
| id | bigint | PK, NOT NULL | 自動採番 |
| title | string | NOT NULL | タスク名 |
| status | integer | NOT NULL, DEFAULT 0 | enum（0: not_started, 1: in_progress, 2: completed）。値の遷移はモデルで制約（`03-functional-specification.md` の「ステータス遷移」） |
| start_date | date | | 開始日（フルスタック版。終了日とともに任意） |
| end_date | date | | 終了日（任意。入力時は終了日 >= 開始日） |
| preview_url | string | | 参考リンク（任意。http/https のみ。確認画面で sandbox iframe プレビュー） |
| project_id | bigint | NOT NULL, FK | projects.id |

> フルスタック版は期間管理（start_date / end_date）を採用する。API版（Project 2）は単一の `due_date`（期日）のままで、両者は意図的に異なる（API仕様は `07-api-specification.md` 参照）。
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

### インデックス

| テーブル | カラム | 種類 |
|----------|--------|------|
| users | email | UNIQUE |
| projects | user_id | INDEX |
| tasks | project_id | INDEX |

> **制約の実態（DB スキーマ vs モデル）**: 上表の「NOT NULL」「DEFAULT」のうち、DB スキーマ（`schema.rb`）で物理的に `null: false` / default を持つのは以下に限られる。それ以外の必須性・初期値は **モデルのバリデーション/コールバックで担保**している（DB レベルでは NULL 許容）。学習用のため意図的にこの差を残している。
>
> - `null: false` を持つカラム: 全テーブルの `created_at` / `updated_at`、`projects.user_id`、`tasks.project_id`、および **フルスタック版のみ** `users.name` / `users.email` / `users.password_digest`。
> - `users.email` の UNIQUE はインデックス制約として両アプリに存在する。
> - `projects.title` / `tasks.title` は DB では NULL 許容で、必須性はモデルの `presence` バリデーションで担保する（両アプリ）。
> - `tasks.status` は DB では `integer`・NULL 許容・**デフォルト無し**で、初期値 `not_started`（0）は **モデルの `after_initialize` コールバック（`set_default_status`）** で設定する（両アプリ）。
> - **API 版** の `users.name` / `users.email` / `users.password_digest` は DB に `null: false` を持たず、必須性はモデルバリデーションのみで担保する。

## クエリ設計

### 一覧のタスク件数（フルスタック版）

プロジェクト一覧はプロジェクトごとにタスク件数を表示する。ビューで `project.tasks.count` を呼ぶと 1 行につき COUNT が 1 本増える（N+1）ため、集計は **モデルのスコープ `Project.with_task_counts`** で SQL 側へ寄せ、一覧取得を 1 クエリに保つ。

| 項目 | 内容 |
|------|------|
| スコープ | `Project.with_task_counts`（`left_joins(:tasks).group(:id).select("projects.*, COUNT(tasks.id) AS tasks_count")`） |
| 呼び出し | `ProjectService.list(user)` が使い、ビューは `project.tasks_count` を表示する |
| 並び順 | 一覧（表示）の責務として `ProjectService.list` 側で `order(:id)`（作成順）を明示する |
| 発行クエリ | プロジェクト件数によらず 1 本（`SELECT ... LEFT OUTER JOIN tasks ... GROUP BY projects.id`） |

- `includes` による事前読み込みでは解消しない（`count` は関連が読み込み済みでも SQL COUNT を発行するため）。
- タスク 0 件のプロジェクトを一覧から落とさないよう、`joins`（INNER JOIN）ではなく `left_joins` を使う。
- `GROUP BY` は行の返却順を保証しないため、並び順を明示しないと表示順が実行計画次第で変わる（集計スコープではなく一覧を組み立てる側で `order` を指定する）。
- 集約済みの Relation を返すため、このスコープに対する `count` は件数ではなく Hash を返す（一覧描画専用であり、件数計測には使わない）。
- counter cache（`projects.tasks_count` カラム）は採用しない。読み取り都合のためにスキーマと書き込み経路・backfill を巻き込まず、変更を読み取り側に閉じるため。
- 回帰は request spec で固定する（プロジェクト件数を増やしても集計クエリが 1 本のままであること。`08-test-specification.md`）。

## 画像添付（Active Storage）

フルスタック版のタスク画像添付は **Active Storage** を使用し、blob 本体は **MinIO（S3 互換）** に保存する。

- Task と画像の関連: `has_many_attached :images`（1タスクに複数枚）
- 管理テーブル（Active Storage 標準）: `active_storage_blobs` / `active_storage_attachments` / `active_storage_variant_records`
- **blob と attachment の id は別物**（別テーブルの主キーで、採番も独立して進む）。`task.images` が列挙するのは `ActiveStorage::Attachment` のため `image.id` は attachment の id であり、画面からの削除指定（`remove_attachment_ids` / `detach_image` の `:attachment_id`）もすべて attachment の id で行う。同じ blob は複数レコードから共有できるため、「どのレコードのどの添付を外すか」は attachment でしか指定できない。
- 添付制約（モデルバリデーション `images_format_and_size` で担保。定数 `Task::IMAGE_CONTENT_TYPES` / `MAX_IMAGE_SIZE`）:
  - 形式: `image/png` / `image/jpeg` / `image/gif` / `image/webp`
  - サイズ: 1枚あたり 5MB 以下
- 確認画面での blob 化 staging・attach・削除 purge は **`TaskImageService`**（`app/services/`）が担い、同じ定数を参照して形式/サイズを事前チェックする（不正混在時は blob を作らずオーファンを防止）。モデルの `images_format_and_size` が最終的な正の検証。
- サムネイル: `variant(resize_to_limit: ...)` を `mini_magick`（ImageMagick）で動的生成し `active_storage_variant_records` にキャッシュ

> API 版（Project 2）は画像添付を持たない（意図的な差分）。

## データフロー

```text
ブラウザ → Controller → Model（ActiveRecord） → PostgreSQL（Docker）
                          ↓
                    バリデーション
                          ↓
                    DB保存/読取
                          ↓
              View（ERB）へデータ渡し
```
