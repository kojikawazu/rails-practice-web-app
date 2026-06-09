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
- [画像添付（Active Storage）](#画像添付active-storage)
- [データフロー](#データフロー)

## データモデル

### 3モデル構成

```
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

```
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
| status | integer | NOT NULL, DEFAULT 0 | enum（0: not_started, 1: in_progress, 2: completed） |
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

## 画像添付（Active Storage）

フルスタック版のタスク画像添付は **Active Storage** を使用し、blob 本体は **MinIO（S3 互換）** に保存する。

- Task と画像の関連: `has_many_attached :images`（1タスクに複数枚）
- 管理テーブル（Active Storage 標準）: `active_storage_blobs` / `active_storage_attachments` / `active_storage_variant_records`
- 添付制約（モデルバリデーション `images_format_and_size` で担保）:
  - 形式: `image/png` / `image/jpeg` / `image/gif` / `image/webp`
  - サイズ: 1枚あたり 5MB 以下
- サムネイル: `variant(resize_to_limit: ...)` を `mini_magick`（ImageMagick）で動的生成し `active_storage_variant_records` にキャッシュ

> API 版（Project 2）は画像添付を持たない（意図的な差分）。

## データフロー

```
ブラウザ → Controller → Model（ActiveRecord） → PostgreSQL（Docker）
                          ↓
                    バリデーション
                          ↓
                    DB保存/読取
                          ↓
              View（ERB）へデータ渡し
```
