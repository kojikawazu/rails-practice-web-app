# データ仕様書（Data Specification）

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
| password   |       | user_id(FK)|       | due_date   |
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
| due_date | date | | 期日 |
| project_id | bigint | NOT NULL, FK | projects.id |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

### インデックス

| テーブル | カラム | 種類 |
|----------|--------|------|
| users | email | UNIQUE |
| projects | user_id | INDEX |
| tasks | project_id | INDEX |

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
