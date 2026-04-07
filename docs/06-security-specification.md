# セキュリティ仕様書（Security Specification）

## 認証

- `has_secure_password`（bcrypt）によるパスワードハッシュ化
- セッションベース認証（`session[:user_id]`）
- ログイン/ログアウト機能

## 認可

- ログインユーザーは自分のプロジェクト・タスクのみ操作可能
- 未ログイン時はログイン画面へリダイレクト（`before_action`）
- 他ユーザーのリソースへのアクセスは Controller 層で制御（`current_user.projects.find(params[:id])`）

## 暗号化

- パスワードは `bcrypt` でハッシュ化して保存（平文保存しない）
- ローカル開発のため通信暗号化（HTTPS）は対象外

## 脆弱性対策

- Railsデフォルトの CSRF トークン保護を利用
- Strong Parameters による Mass Assignment 防止
- ERBテンプレートの自動エスケープによる XSS 防止
- SQLインジェクションは ActiveRecord のパラメータバインディングで防止

## シークレット管理

- DB接続情報は `.env` で管理（`.gitignore` 対象）
- `POSTGRES_PASSWORD` 等をコードにハードコードしない
- `docker-compose.yml` は `.env` から環境変数を読み込む

※ トレーニング目的のため、最低限のRailsデフォルトセキュリティを活用する方針
