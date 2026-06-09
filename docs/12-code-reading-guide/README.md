# コードリーディングガイド

このドキュメントは、2つのプロジェクト（フルスタック版 / APIモード）を比較しながらコードを読む際のナビゲーションガイドです。

## プロジェクト構成の対比

| 項目 | フルスタック版 | APIモード |
|---|---|---|
| ディレクトリ | `rails-task-fullstack-web-app/` | `rails-task-api-web-app/` |
| レスポンス | HTML（ERBテンプレート） | JSON |
| 認証方式 | セッション（`session[:user_id]`） | JWT（`Authorization: Bearer`） |
| 基底コントローラー | `ActionController::Base` | `ActionController::API` |
| APIバージョニング | なし | `/api/v1/` 名前空間 |

## 読む順番（推奨）

上から順に読むことを推奨します。各ステップは独立したファイルに分割しています。

| Step | 内容 | ファイル |
|---|---|---|
| 1 | ルーティングから全体像を把握する | [01-routing.md](01-routing.md) |
| 2 | 認証の仕組みを読む | [02-auth.md](02-auth.md) |
| 3 | モデルを読む（共通） | [03-models.md](03-models.md) |
| 4 | コントローラーを読む | [04-controllers.md](04-controllers.md) |
| 5 | テストを読む | [05-tests.md](05-tests.md) |

## 重要な差分まとめ

| 観点 | フルスタック版 | APIモード |
|---|---|---|
| **認証の維持** | `session[:user_id]`（Cookie） | JWT トークン（Authorizationヘッダー） |
| **未認証時の挙動** | `redirect_to login_path` | `render json: { error: "Unauthorized" }, status: 401` |
| **削除後の挙動** | `redirect_to projects_url` | `head :no_content`（204） |
| **バリデーションエラー** | `render :new, status: :unprocessable_entity` | `render json: { errors: [...] }, status: 422` |
| **ルーティング** | `/projects` | `/api/v1/projects` |
| **テストでのログイン** | `post login_url, params: { email:, password: }` | `auth_headers(user)` でトークンをヘッダーに付与 |

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
