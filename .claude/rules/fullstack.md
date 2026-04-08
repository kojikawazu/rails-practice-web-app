---
description: Rails フルスタック（MVC + View）設計ルール
globs: "rails-task-fullstack-web-app/app/**,rails-task-fullstack-web-app/config/**"
---

# フルスタックルール（Rails MVC）

## アーキテクチャ

- Rails MVC パターン（Model + View + Controller）
- Controller は薄く保ち、ビジネスロジックは Service オブジェクト（`app/services/`）に集約する。
- Fat Model を避ける。Model はバリデーション・リレーション・スコープに留める。

## ディレクトリ構成

```
app/
├── controllers/
├── models/
├── views/                # ERB / Slim テンプレート
│   └── layouts/
├── services/             # ビジネスロジック
├── helpers/              # ビューヘルパー
├── assets/               # CSS / JS
│   ├── stylesheets/
│   └── javascript/
├── serializers/          # JSON レスポンス用（API エンドポイントがある場合）
└── validators/           # カスタムバリデーター
config/
├── routes.rb
└── database.yml
```

## Controller

- RESTful アクション（`index`, `show`, `new`, `create`, `edit`, `update`, `destroy`）を基本とする。
- `resources` ルーティングを使用する。
- Strong Parameters で入力をホワイトリスト制御する。

## View

- パーシャルで再利用可能な UI 部品を切り出す（`_form.html.erb` 等）。
- ロジックは View に書かない。Helper またはデコレーター（Draper 等）を使用する。

## 例外ハンドリング

- `rescue_from` でグローバル例外ハンドリング。
- フラッシュメッセージでユーザーにフィードバックする。
- センシティブ情報をログに含めない（`config.filter_parameters`）。
