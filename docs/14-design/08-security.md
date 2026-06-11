# セキュリティ設計方針

> 実装仕様の正本は `docs/06-security-specification.md`、ルールは `.claude/rules/security.md`。本書は**2 アプリの方式差と設計判断**を補足する。
> トレーニング目的のため、Rails デフォルトのセキュリティ機構を活用し、MVP 段階で過剰にならない範囲で対策する。

## 目次

- [認証（2 方式）](#認証2-方式)
- [認可（スコープによる 404）](#認可スコープによる-404)
- [脆弱性対策](#脆弱性対策)
  - [CSRF（方式で要否が分かれる）](#csrf方式で要否が分かれる)
  - [XSS / SQL インジェクション / Mass Assignment](#xss--sql-インジェクション--mass-assignment)
- [外部 URL プレビューの多層防御](#外部-url-プレビューの多層防御)
- [通信・CORS](#通信cors)
- [シークレット管理](#シークレット管理)

[← 目次に戻る](README.md)

## 認証（2 方式）

2 アプリで認証方式が異なる。アプリ特性に合わせた設計判断。

| アプリ | 方式 | 保存先 |
|--------|------|--------|
| フルスタック版 | `has_secure_password`（bcrypt）+ **セッション認証** | `session[:user_id]`（Cookie） |
| API 版 | `has_secure_password`（bcrypt）+ **JWT（Bearer トークン）** | クライアント保持（Cookie 不使用） |

- パスワードは両アプリとも **bcrypt** でハッシュ化（`password_digest`）。平文保存しない。
- API 版が JWT なのは、`rails new --api` がセッション/Cookie ミドルウェアを持たないため。トークン検証は `JsonWebToken` + `authenticate_user!`（`before_action`）に集約する（`04-api-backend.md`）。

## 認可（スコープによる 404）

- ログインユーザーは**自分のプロジェクト・タスクのみ**操作可能。
- 認可は専用の Policy 層ではなく**関連スコープで実装**する。`current_user.projects.find(...)` で取得すると、他ユーザーのリソースは `RecordNotFound` となり、存在を秘匿したまま **404** で弾ける。
- 未認証時の挙動は方式差がある: フルスタックは `before_action` でログイン画面へリダイレクト、API は **401 Unauthorized** を返す。

## 脆弱性対策

### CSRF（方式で要否が分かれる）

- **フルスタック版（セッション/Cookie）**: Rails デフォルトの CSRF トークン保護を**無効化しない**。`form_with` がトークンを自動付与する。
- **API 版（Bearer トークン）**: Cookie にトークンを置かないため CSRF 対策は不要（`ActionController::API` で CSRF 保護も無い）。トークンを Cookie 保存する設計に変える場合は CSRF 対策を再導入する。

### XSS / SQL インジェクション / Mass Assignment

- **XSS**: ERB の自動エスケープを基本とする。`raw` / `html_safe` の濫用を避ける。
- **SQL インジェクション**: ActiveRecord のパラメータバインディングを必須とする（生 SQL の文字列結合は禁止）。
- **Mass Assignment**: Strong Parameters でホワイトリスト制御する。

> CSP は本プロジェクトでは未導入（既存 ERB のインラインスタイル多用で `style-src` 違反が回帰するため）。スキーム検証 + ホスト制限 + sandbox の多層で担保し、CSP 導入は将来課題（`docs/06`）。

## 外部 URL プレビューの多層防御

タスクの `preview_url` を確認画面で **iframe プレビュー**する機能（フルスタック版のみ）は高リスクのため、**多層防御**で守る。設計の要点は以下（リスク対応表の正本は `docs/06`）。

1. **スキーム検証（モデル層）**: `URI::HTTP` 判定で **http / https のみ許可**。`javascript:` / `data:` 等の危険スキームを保存・確認画面到達前に弾く。
2. **自オリジン埋め込みの遮断（モデル層）**: `localhost` / `0.0.0.0` / `app_host`（コントローラーが `request.host` を渡す）一致、およびループバック・プライベート・リンクローカル IP（`IPAddr` で判定）を拒否。`allow-same-origin` + `allow-scripts` による sandbox 脱獄が成立する「自オリジン埋め込み」を不可能にする。ホストは正規化してから判定する（IPv6 角括弧・FQDN 末尾ドット除去でバイパス防止）。
3. **iframe sandbox（View 層）**: `sandbox="allow-scripts allow-same-origin"`・`referrerpolicy="no-referrer"`・`allow=""`。`allow-top-navigation` / `allow-popups` / `allow-forms` / `allow-modals` は付与しない。
4. **詳細画面では iframe を出さない**: `rel="noopener noreferrer"` の安全リンクのみ表示する。
5. **SSRF 非該当**: サーバー側で URL を fetch しない（取得はクライアントの iframe のみ）。将来サーバー側取得を足す場合は内部 IP・メタデータ遮断を別途必須とする。

## 通信・CORS

- ローカル開発のため **HTTPS は対象外**（本番化する場合は HTTPS 必須）。
- API 版は `rack-cors`（`config/initializers/cors.rb`）で**許可オリジンを明示**する（`http://localhost:3000` / `http://localhost:3099`）。`*` は使わない。`Authorization` ヘッダーを expose し、クライアントが発行トークンを読めるようにする。

## シークレット管理

- DB 接続情報・MinIO 認証情報・`master.key` 等は **`.env` / Rails credentials** で管理し、コードにハードコードしない。
- `.env` は `.gitignore` 対象。`docker-compose.yml` は `.env` から環境変数を読み込む。
- 本番化する場合は Secret Manager 等のマネージドサービスを使用する（本プロジェクトは対象外）。
