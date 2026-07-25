---
description: Ruby on Rails コーディング規約 — レイヤ構成・lint・定数配置・レスポンス整形
globs: "**/*.rb"
---

# Ruby on Rails コーディング規約

言語共通の規約は `coding-standards.md`（YARD ドキュメントコメントを含む）に従う。本ファイルは Ruby / Rails 固有の作法を定める。

## 依存・ツール

- Ruby 3.3 系 / Rails 8 系、依存管理は Bundler（`Gemfile` / `Gemfile.lock` をコミット）。
- Linter / Formatter: **RuboCop（`rubocop-rails-omakase`）**。独自オーバーライドは原則入れない（Omakase に従う）。
- セキュリティ: `brakeman` + `bundler-audit` を CI で実行する。
- 静的解析の運用（CI 必須・警告ゼロ・抑制コメントの書き方）は `static-analysis.md` に従う。

## レイヤ構成（薄い Controller + Service）

- **Controller は薄く**保つ。責務はパラメータ受領・Service 呼び出し・描画/レスポンス返却のみ。ビジネスロジック・複雑な分岐を書かない。
- **ビジネスロジックは Service オブジェクト**（`app/services/`）に集約する。副作用・トランザクション・外部ストレージ連携はここに置く。
- **Fat Model を避ける**。Model はバリデーション・リレーション・スコープに留める。
- 認可はアソシエーション経由のスコープで行い（`user.projects.find` 等）、他ユーザーのリソースは **404 で存在秘匿**する。

> 詳細なディレクトリ構成・Controller / View の規約は `fullstack.md`（MVC アプリ）と `api.md`（API モード）が持つ。本ファイルと重複させない。

## レスポンス（AR を直返ししない）

- **ActiveRecord モデル / リレーションをそのまま `render json:` しない**。serializer / PORO / jbuilder テンプレートに変換し、公開してよい属性だけを厳選して返す。
- エラーレスポンスは統一形（`{ error: ... }` / `{ errors: [...] }`）。`rescue_from ActiveRecord::RecordNotFound` → 404。方針は `error-handling.md` に従う。

## 定数の配置

マジックナンバー・マジック文字列を直接書かない。ただし**何でも入る `Constants` モジュールを作らない**（無関係な値の集積になり、全クラスがそこへ依存する）。

| 定数の性質 | 置き場所 |
|---|---|
| 取り得る値が閉じている（区分・ステータス） | **モデルの `enum`**（`enum status: { todo: 0, doing: 1, done: 2 }`。文字列の直書きにしない） |
| 1 クラス内でしか使わない | そのクラスの定数（`private_constant` で非公開にする） |
| 特定の概念に属する制約値 | その概念のモデル・クラス（`Task::MAX_TITLE_LENGTH` 等）に置く |
| 環境ごとに変わる値 | **定数にしない**。環境変数（`.env` / `Rails.application.credentials`）経由で読む |

- 定数名は `UPPER_SNAKE_CASE`。公開定数には**単位とその値である根拠**を YARD コメントで書く。
- **`freeze` する**（`MAX = 50` は不要だが、文字列・配列・ハッシュの定数は必ず `.freeze`。Ruby の定数は再代入警告のみで中身は可変）。
- **バリデーションにも定数を渡す**（`validates :title, length: { maximum: MAX_TITLE_LENGTH }`）。数値を直書きしない。

## 命名

- Rails 標準に従う（Model は PascalCase 単数、テーブルは snake_case 複数、外部キーは `{model}_id`）。詳細は `database.md`。
