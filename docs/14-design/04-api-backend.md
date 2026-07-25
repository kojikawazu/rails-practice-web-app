# Controller / Model / Service 設計方針

> 本方針は両アプリ共通の Rails サーバーサイド設計（`.claude/rules/fullstack.md` / `.claude/rules/api.md` と整合）。
> 「何を返すか」の具体仕様は `docs/07-api-specification.md`、データ構造は `docs/05-data-specification.md` を参照（本書は重複させない）。

## 目次

- [レイヤーの責務](#レイヤーの責務)
  - [Thin Controller](#thin-controller)
  - [Service オブジェクト（意図する方向）](#service-オブジェクト意図する方向)
  - [Fat Model を避ける](#fat-model-を避ける)
- [ルーティング](#ルーティング)
- [Strong Parameters](#strong-parameters)
- [API モード固有の方針](#api-モード固有の方針)
  - [バージョニングと名前空間](#バージョニングと名前空間)
  - [JWT 認証](#jwt-認証)
  - [JSON シリアライズ](#json-シリアライズ)
  - [統一エラーハンドリング](#統一エラーハンドリング)
- [ディレクトリ構成](#ディレクトリ構成)

[← 目次に戻る](README.md)

## レイヤーの責務

### Thin Controller

- Controller は薄く保つ。RESTful アクション（`index` / `show` / `new` / `create` / `edit` / `update` / `destroy`）を基本とする。
- ユーザーデータへのアクセスは**スコープ経由**で取得し、認可と取得を一体化する。
  - 例: `current_user.projects.find(params[:id])` / `@project.tasks.find(...)`。他ユーザーのリソースは `RecordNotFound`（=404）で自然に弾かれる。
- 複製（`duplicate`）・確認（`confirm`）など RESTful 外のアクションも、ルーティングで明示して Controller に置く。

### Service オブジェクト（意図する方向）

- ビジネスロジックは Service オブジェクト（`app/services/`）へ集約する方針とする（`.claude/rules/fullstack.md` / `api.md`）。
- **現状、両アプリとも `app/services/` は未作成**で、ロジックは Controller / Model に収まる規模に留まっている。
  - 確認画面の round-trip（画像 blob 化・session 退避）やプレビュー URL 検証など、ロジックが Controller に厚くなってきた箇所が将来の切り出し候補。
- ロジックが Controller に滲み出し始めたら Service に切り出す、を判断基準とする（先回りで空クラスは作らない）。

### Fat Model を避ける

- Model はバリデーション・関連（association）・スコープ・enum に留める。
- 横断的な処理や複数モデルにまたがる操作を Model に詰め込まない（→ Service の方向）。

## ルーティング

- `resources` による RESTful ルーティングを使用する。
- ネストは 1 段まで（`projects` → `tasks`）。
- RESTful 外は `collection` / `member` で明示する。
  - 例（フルスタック）: 確認画面 `match :confirm, via: %i[get post]`、複製 `get :duplicate`、画像個別削除 `delete "images/:image_id"`。

## Strong Parameters

- 入力は **Strong Parameters でホワイトリスト制御**する（Mass Assignment 防止）。
  - 例: `params.require(:project).permit(:title, :description)` / `params.require(:task).permit(:title, :status, ...)`。
- 確認画面で session に退避する値も、permit 済みのキー（`title` / `description` 等）のみとする。

## API モード固有の方針

`rails-task-api-web-app` は `ActionController::API` を継承し（View / Cookie ミドルウェア無効）、JSON のみを返す。

### バージョニングと名前空間

- すべてのエンドポイントを `/api/v1/` 配下に置く（`namespace :api { namespace :v1 { ... } }`）。
- コントローラーは `app/controllers/api/v1/` に配置する（`Api::V1::ProjectsController` 等）。

### JWT 認証

- 認証は **JWT（Bearer トークン）**。`rails new --api` はセッション/Cookie を持たないため、Cookie 非依存のトークン認証を採る。
- トークンの encode / decode は `app/lib/json_web_token.rb`（`JsonWebToken` モジュール）に集約する。
  - 署名鍵は `Rails.application.secret_key_base`、`exp` は既定 24 時間。decode は `JWT::DecodeError` を捕捉して `nil` を返す。
- `ApplicationController#authenticate_user!`（`before_action`）が `Authorization: Bearer <token>` を検証し、`current_user` を確立する。無効・未存在なら **401**。
- `AuthController` のみ `skip_before_action :authenticate_user!` で signup / login を公開する。
- ステートレスのため**ログアウト API は持たない**（クライアントがトークンを破棄）。

### JSON シリアライズ

- レスポンスは `render json:` で返す。
- **現状はモデルを直接シリアライズ**している（`render json: @project`）。
- レスポンス整形の規約は Serializer 層（`app/serializers/`、ActiveModel Serializers / Blueprinter 等）に寄せる方向だが、**未導入**。表現の出し分けが必要になった時点で導入する。

### 統一エラーハンドリング

- エラー JSON は用途で 2 形態を使い分ける（詳細は `docs/07`）。
  - バリデーションエラー（**422**）: `{ "errors": ["..."] }`（複数形・配列）。
  - 認証エラー（**401**）/ リソース未存在（**404**）: `{ "error": "..." }`（単数形）。
- 他ユーザーのリソースは `set_*` の `rescue ActiveRecord::RecordNotFound` で **404** に正規化する（存在を秘匿）。
- グローバルな例外整形は `rescue_from` に寄せる方向。センシティブ情報はレスポンス・ログに含めない（`config.filter_parameters`）。

## ディレクトリ構成

```text
# フルスタック版
app/
├── controllers/        # ProjectsController / TasksController / Sessions / Users
├── models/             # User / Project / Task
├── views/              # ERB（03-frontend.md）
├── helpers/
└── javascript/
# （services/ serializers/ validators/ は規約上の置き場。現状未作成）

# API 版
app/
├── controllers/
│   ├── application_controller.rb   # ActionController::API + authenticate_user!
│   └── api/v1/                      # Auth / Projects / Tasks
├── lib/json_web_token.rb           # JWT encode/decode
└── models/                          # User / Project / Task
# （services/ serializers/ は規約上の置き場。現状未作成）
```
