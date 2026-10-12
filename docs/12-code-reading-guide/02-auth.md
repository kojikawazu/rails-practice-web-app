# Step 2: 認証の仕組みを読む

[← README](README.md)

認証はアプリ全体の根幹。ここを押さえると他のコードが読みやすくなる。

## フルスタック版（セッション認証）

| ファイル | 役割 |
|---|---|
| `app/controllers/application_controller.rb` | `current_user`・`require_login` ヘルパー定義 |
| `app/controllers/sessions_controller.rb` | ログイン・ログアウト処理 |
| `app/controllers/users_controller.rb` | サインアップ処理 |

読むポイント:

- `session[:user_id]` にユーザーIDを保存してログイン状態を維持
- `before_action :require_login` で未ログイン時にリダイレクト

## APIモード（JWT認証）

| ファイル | 役割 |
|---|---|
| `app/lib/json_web_token.rb` | JWTのエンコード・デコード |
| `app/controllers/application_controller.rb` | `authenticate_user!`（Bearer トークンを取り出し、検証を AuthService に任せる） |
| `app/services/auth_service.rb` | signup / login（トークン発行）・authenticate（検証と失効の照合）・logout（失効） |
| `app/models/revoked_token.rb` | ログアウトで失効させたトークンの記録（denylist） |
| `app/controllers/api/v1/auth_controller.rb` | signup / login → トークン発行、logout → トークン失効 |

読むポイント:

- `JsonWebToken.encode(user_id: user.id)` でトークン生成
- `request.headers["Authorization"]` からトークンを取り出して検証
- `skip_before_action :authenticate_user!, only: %i[signup login]` で認証不要なエンドポイントだけを除外（logout は失効させるトークンで認証する）
- `AuthService.authenticate` が `jti` を `RevokedToken` と照合する。JWT 自体はステートレスだが、ログアウトを実現するためにここでサーバー側の状態を引いている

---

前へ: [Step 1: ルーティングから全体像を把握する](01-routing.md) ｜ 次へ: [Step 3: モデルを読む（共通）](03-models.md)
