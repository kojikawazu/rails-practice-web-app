# コードリーディングガイド

このドキュメントは、2つのプロジェクト（フルスタック版 / APIモード）を比較しながらコードを読む際のナビゲーションガイドです。

---

## プロジェクト構成の対比

| 項目 | フルスタック版 | APIモード |
|---|---|---|
| ディレクトリ | `rails-task-fullstack-web-app/` | `rails-task-api-web-app/` |
| レスポンス | HTML（ERBテンプレート） | JSON |
| 認証方式 | セッション（`session[:user_id]`） | JWT（`Authorization: Bearer`） |
| 基底コントローラー | `ActionController::Base` | `ActionController::API` |
| APIバージョニング | なし | `/api/v1/` 名前空間 |

---

## 読む順番（推奨）

### Step 1: ルーティングから全体像を把握する

まずどのURLがどのコントローラーに繋がっているかを確認する。

**フルスタック版**
```
rails-task-fullstack-web-app/config/routes.rb
```
```ruby
resources :projects do
  resources :tasks      # ネスト: /projects/:project_id/tasks
end
get "login"  → SessionsController#new
post "login" → SessionsController#create
```

**APIモード**
```
rails-task-api-web-app/config/routes.rb
```
```ruby
namespace :api do
  namespace :v1 do
    post "login"  → Api::V1::AuthController#login
    resources :projects do
      resources :tasks
    end
  end
end
```

> **差分ポイント**: APIモードは `namespace :api do namespace :v1` で全エンドポイントをバージョン管理している。

---

### Step 2: 認証の仕組みを読む

認証はアプリ全体の根幹。ここを押さえると他のコードが読みやすくなる。

**フルスタック版（セッション認証）**

| ファイル | 役割 |
|---|---|
| `app/controllers/application_controller.rb` | `current_user`・`require_login` ヘルパー定義 |
| `app/controllers/sessions_controller.rb` | ログイン・ログアウト処理 |
| `app/controllers/users_controller.rb` | サインアップ処理 |

読むポイント:
- `session[:user_id]` にユーザーIDを保存してログイン状態を維持
- `before_action :require_login` で未ログイン時にリダイレクト

**APIモード（JWT認証）**

| ファイル | 役割 |
|---|---|
| `app/lib/json_web_token.rb` | JWTのエンコード・デコード |
| `app/controllers/application_controller.rb` | `authenticate_user!`（Bearerトークン検証） |
| `app/controllers/api/v1/auth_controller.rb` | signup/login → トークン発行 |

読むポイント:
- `JsonWebToken.encode(user_id: user.id)` でトークン生成
- `request.headers["Authorization"]` からトークンを取り出して検証
- `skip_before_action :authenticate_user!` で認証不要なエンドポイントを除外

---

### Step 3: モデルを読む（共通）

両プロジェクトのモデルはほぼ同一。一方を読めばもう一方も分かる。

```
app/models/user.rb      # has_secure_password、バリデーション
app/models/project.rb   # belongs_to :user、has_many :tasks
app/models/task.rb      # belongs_to :project、enum :status
```

**モデルの関連図**

```
User
 └── has_many :projects (dependent: :destroy)
       └── has_many :tasks (dependent: :destroy)
```

読むポイント:
- `has_secure_password` → bcrypt で password_digest を自動管理
- `enum :status, { not_started: 0, in_progress: 1, completed: 2 }, validate: true`
  → `task.not_started?` / `task.in_progress?` のような便利メソッドが自動生成される
- `after_initialize :set_default_status` → 新規レコードのデフォルト値設定パターン

---

### Step 4: コントローラーを読む

**フルスタック版**
```
app/controllers/projects_controller.rb
app/controllers/tasks_controller.rb
```

読むポイント:
- `before_action :require_login` — 認証ガード
- `current_user.projects.find(params[:id])` — スコープ付き検索（他ユーザーのデータにアクセスできない）
- `respond_to do |format|` — HTML/JSON の両レスポンス対応

**APIモード**
```
app/controllers/api/v1/projects_controller.rb
app/controllers/api/v1/tasks_controller.rb
```

読むポイント:
- `render json: @project` — シンプルなJSON返却
- `head :no_content` — DELETE時に204を返す（ボディなし）
- `rescue ActiveRecord::RecordNotFound` → 404 JSON を返す

> **差分ポイント**: フルスタック版は `redirect_to` でページ遷移するが、APIモードは `render json:` のみ。エラーも `render json: { error: "..." }, status: :not_found` で返す。

---

### Step 5: テストを読む

テストはコードの「仕様書」として読める。実装を読む前にテストを読むと意図が分かりやすい。

**フルスタック版（Minitest + RSpec 併用）**

| ファイル | 内容 |
|---|---|
| `test/controllers/projects_controller_test.rb` | Miniteストでのコントローラーテスト |
| `spec/models/user_spec.rb` | shoulda-matchers でバリデーション検証 |
| `spec/requests/projects_spec.rb` | RSpec リクエストスペック |

**APIモード（RSpec のみ）**

| ファイル | 内容 |
|---|---|
| `spec/requests/api/v1/auth_spec.rb` | signup/login のトークン返却確認 |
| `spec/requests/api/v1/projects_spec.rb` | JWT付きリクエストのCRUD確認 |
| `spec/support/jwt_helper.rb` | `auth_headers(user)` ヘルパー（テスト用トークン生成） |

読むポイント:
- `auth_headers(user)` の実装を見ると JWT の使い方が分かる
- `as: :json` — リクエストボディを JSON として送信
- `JSON.parse(response.body)` — レスポンスの JSON を検証

---

## 重要な差分まとめ

| 観点 | フルスタック版 | APIモード |
|---|---|---|
| **認証の維持** | `session[:user_id]`（Cookie） | JWT トークン（Authorizationヘッダー） |
| **未認証時の挙動** | `redirect_to login_path` | `render json: { error: "Unauthorized" }, status: 401` |
| **削除後の挙動** | `redirect_to projects_url` | `head :no_content`（204） |
| **バリデーションエラー** | `render :new, status: :unprocessable_entity` | `render json: { errors: [...] }, status: 422` |
| **ルーティング** | `/projects` | `/api/v1/projects` |
| **テストでのログイン** | `post login_url, params: { email:, password: }` | `auth_headers(user)` でトークンをヘッダーに付与 |

---

## 動作確認コマンド

### フルスタック版
```bash
cd rails-task-fullstack-web-app
docker compose up -d          # PostgreSQL 起動
rbenv exec bundle exec rails db:migrate
rbenv exec bundle exec rails server -p 3099
# ブラウザで http://localhost:3099 を開く
```

### APIモード
```bash
cd rails-task-api-web-app
rbenv exec bundle exec rails db:migrate
rbenv exec bundle exec rails server -p 3100

# アカウント作成
curl -X POST http://localhost:3100/api/v1/signup \
  -H "Content-Type: application/json" \
  -d '{"user":{"name":"テスト","email":"test@example.com","password":"password123","password_confirmation":"password123"}}'

# ログイン → token を取得
curl -X POST http://localhost:3100/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# プロジェクト一覧（token を置き換える）
curl http://localhost:3100/api/v1/projects \
  -H "Authorization: Bearer <token>"
```

### テスト実行
```bash
# フルスタック版
cd rails-task-fullstack-web-app
rbenv exec bundle exec rails test   # Minitest 28件
rbenv exec bundle exec rspec        # RSpec 39件

# APIモード
cd rails-task-api-web-app
rbenv exec bundle exec rspec        # RSpec 18件
```
