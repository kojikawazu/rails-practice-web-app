# セキュリティ仕様書（Security Specification）

## 目次

- [認証](#認証)
- [認可](#認可)
- [暗号化](#暗号化)
- [脆弱性対策](#脆弱性対策)
- [外部 URL のプレビュー（iframe 埋め込み）](#外部-url-のプレビューiframe-埋め込み)
  - [想定リスクと対策](#想定リスクと対策)
  - [iframe 設定](#iframe-設定)
- [シークレット管理](#シークレット管理)

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

## 外部 URL のプレビュー（iframe 埋め込み）

タスクの `preview_url` を確認画面で iframe プレビューする機能のセキュリティ方針。任意のユーザー入力 URL を iframe に埋め込むのは高リスクのため、**多層防御**で担保する。

### 想定リスクと対策

| リスク | 対策 |
|--------|------|
| スキームインジェクション（`javascript:` / `data:` による XSS） | **モデル層で http/https のみ許可**（`URI::HTTP` 判定）。危険スキームは保存・確認画面到達前に弾く |
| トップナビゲーション乗っ取り（`top.location` フィッシング誘導） | iframe sandbox に `allow-top-navigation` を**付与しない** |
| ポップアップ・フォーム送信・モーダル悪用 | sandbox に `allow-popups` / `allow-forms` / `allow-modals` を付与しない |
| sandbox 脱獄（`allow-same-origin` ＋ `allow-scripts` の併用） | 表示互換性のため `allow-same-origin` は付与するが、**自ホスト・内部/ループバック/プライベート IP の URL をモデル層で拒否**し、脱獄が成立する「自オリジン埋め込み」を不可能にする |
| Referer 経由の情報漏洩 | `referrerpolicy="no-referrer"` |
| カメラ/マイク/位置情報の悪用 | Permissions Policy `allow=""` で無効化 |
| SSRF | サーバー側で URL を fetch しない（iframe はクライアント側取得のみ）。将来サーバー側取得（OGP/スクショ等）を足す場合は内部 IP・メタデータ遮断を別途必須とする |

### iframe 設定

```text
sandbox="allow-scripts allow-same-origin"  referrerpolicy="no-referrer"  allow=""
```

- `allow-same-origin` は **外部（クロスオリジン）サイトを正常表示するため**に付与する。クロスオリジンのため同一オリジンポリシーにより当アプリの DOM/Cookie には触れられない。
- 脱獄が成立するのは「枠内 URL が**当アプリと同一オリジン**」の場合のみ。これを **モデルバリデーション**（`localhost` / `0.0.0.0` / `app_host` 一致 / ループバック・プライベート・リンクローカル IP の拒否）で塞ぐ。`app_host` はコントローラーが `request.host` を渡す。
- ホスト判定は **正規化してから**行う（IPv6 リテラルの角括弧 `[::1]` を除去、FQDN 末尾ドット `localhost.` を除去）。表記揺れによる allowlist/denylist バイパスを防ぐ。
- 詳細画面では iframe を出さず、`rel="noopener noreferrer"` の安全リンクのみ表示する。
- **CSP は本プロジェクトでは未導入**（既存 ERB のインラインスタイルを多用しており `style-src` 違反で回帰するため）。スキーム検証＋ホスト制限＋sandbox の多層で担保し、CSP `frame-src` 導入は将来課題とする。
- 多くのサイトは `X-Frame-Options` / `frame-ancestors` で埋め込みを拒否するため、プレビューは**ベストエフォート**（表示されない場合は安全リンクから開く）。

## シークレット管理

- DB接続情報は `.env` で管理（`.gitignore` 対象）
- `POSTGRES_PASSWORD` 等をコードにハードコードしない
- `docker-compose.yml` は `.env` から環境変数を読み込む

※ トレーニング目的のため、最低限のRailsデフォルトセキュリティを活用する方針
