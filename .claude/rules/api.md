---
description: Rails API モード設計・コントローラー構成
globs: "rails-task-api-web-app/app/controllers/**,rails-task-api-web-app/app/models/**,rails-task-api-web-app/app/services/**"
---

---
description: Rails API モード設計・コントローラー構成
globs: "rails-task-api-web-app/app/**,rails-task-api-web-app/config/**"
---

# API ルール（Rails API モード）

## アーキテクチャ

- Rails API モード（`rails new --api`）を使用。View 層なし。
- Controller は薄く保ち、ビジネスロジックは Service オブジェクト（`app/services/`）に集約する。
- Fat Model を避ける。Model はバリデーション・リレーション・スコープに留める。

## ディレクトリ構成

```
app/
├── controllers/
│   ├── application_controller.rb
│   └── api/
│       └── v1/           # バージョニング
├── models/
├── services/             # ビジネスロジック
├── serializers/          # レスポンス整形（ActiveModel Serializers / Blueprinter 等）
└── validators/           # カスタムバリデーター
config/
├── routes.rb
└── database.yml
```

## 共通方針

- RESTful 設計（`resources` ルーティング）
- レスポンス形式: JSON（`render json:`）
- API バージョニング: `/api/v1/` プレフィックス
- 例外: `rescue_from` でグローバル例外ハンドリング。統一 JSON エラーレスポンス。
- Strong Parameters で入力をホワイトリスト制御する。
- センシティブ情報をログに含めない（`config.filter_parameters`）
