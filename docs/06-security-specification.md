# セキュリティ仕様書（Security Specification）

## 目次

- [認証](#認証)
- [認可](#認可)
- [暗号化](#暗号化)
- [脆弱性対策](#脆弱性対策)
  - [Content Security Policy（フルスタック版）](#content-security-policyフルスタック版)
- [外部 URL のプレビュー（iframe 埋め込み）](#外部-url-のプレビューiframe-埋め込み)
  - [想定リスクと対策](#想定リスクと対策)
  - [iframe 設定](#iframe-設定)
- [シークレット管理](#シークレット管理)
  - [Rails credentials と master.key](#rails-credentials-と-masterkey)
  - [secret_key_base の影響範囲](#secret_key_base-の影響範囲)
  - [鍵のローテーション](#鍵のローテーション)

## 認証

- `has_secure_password`（bcrypt）によるパスワードハッシュ化
- セッションベース認証（`session[:user_id]`）— フルスタック版（Project 1）
- ログイン/ログアウト機能
- **API 版（Project 2）は JWT**（`Authorization: Bearer <token>`）。Cookie を持たないための選択で、資格情報の搬送方式も契約どおりに限定する:
  - **Bearer スキームの資格情報だけを受理**する（scheme の大文字小文字は区別しない。RFC 7235: auth-scheme is case-insensitive）。
  - スキーム無しの生トークン・別スキーム（`Basic <token>` 等）・要素が多いヘッダーは、載っている JWT が有効でも **401** にする。認証境界を文書化した契約より広げると、プロキシ・クライアント・監査ログの前提が崩れるため。
  - 契約とレスポンス形式の詳細は `07-api-specification.md` を参照する。

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
- **Content Security Policy（CSP）** をフルスタック版で **enforce モード**で有効化（下記）

### Content Security Policy（フルスタック版）

XSS 対策は「入力検証 + 出力エスケープ + CSP」の多層防御とし、CSP は**ブラウザ側の最終防御**を担う。設定は `config/initializers/content_security_policy.rb`。

| ディレクティブ | 値 | 理由 |
|---|---|---|
| `default-src` | `'self'` | 既定は自オリジンのみ |
| `script-src` | `'self'` + リクエストごとの `nonce` | **インライン JS を許可しない**。importmap / Turbo のインライン script には `importmap-rails` が nonce を自動付与する |
| `style-src` | `'self'` | `<style>` ブロックの注入を禁止する |
| `style-src-attr` | `'unsafe-inline'`（**暫定**） | View に残るインライン `style` 属性のための段階導入。移行は [#101](https://github.com/kojikawazu/rails-practice-web-app/issues/101) で追跡し、完了時にこの行を削除する |
| `img-src` | `'self' data:` + （development のみ）MinIO の配信元 | development の Active Storage は MinIO へリダイレクトするため。production は Disk（同一オリジン）で不要 |
| `frame-src` | `http: https:` | タスクの `preview_url` プレビュー用。`javascript:` / `data:` の frame は拒否する。埋め込みの封じ込めは iframe の `sandbox` とモデルの URL 検証が担う |
| `frame-ancestors` | `'none'` | 自アプリを他サイトに埋め込ませない（クリックジャッキング対策） |
| `object-src` | `'none'` | プラグイン埋め込みを禁止 |
| `base-uri` / `form-action` | `'self'` | `<base>` 書き換えと外部への form 送信を禁止 |

- **nonce はレスポンスごとに使い捨てる**（`SecureRandom.base64(16)`）。推測できる値にすると `script-src` の制限を回避されるため。
- インライン `onclick` は Stimulus（`row_link_controller.js`）へ移行済み。CSP を有効にしたブラウザではインラインハンドラは実行されない。
- `:js` の system spec は headless Chrome で実際に CSP が適用されるため、**CSP 違反はテストの失敗として検出できる**（`08-test-specification.md`）。

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

### Rails credentials と master.key

Rails のシークレットは `config/credentials.yml.enc`（暗号化済み・**コミット対象**）と、その復号鍵である `config/master.key`（**コミット禁止**）の 2 つで構成される。両者が揃って初めて復号できるため、鍵をリポジトリに含めないことが暗号化の前提そのものになる。

- `.gitignore` では `/config/*.key` で除外する。`master.key` 単体指定ではなく glob にするのは、環境別鍵（`production.key` 等）を将来追加したときに除外漏れを起こさないため。
- `master.key` は各開発者がローカルで保持し、Git 以外の経路で受け渡す。CI・デプロイでは環境変数 `RAILS_MASTER_KEY` として渡す。
- CI の `Secret scan` ジョブ（`.github/workflows/ci.yml`）で、`*.key` / `*.pem` が追跡対象に入っていないことを変更種別によらず常時検証する。`.gitignore` は未追跡ファイルにしか効かないため、誤って追跡された時点で落とす検出側を併せて持つ。

### secret_key_base の影響範囲

本リポジトリの `credentials.yml.enc` が保持するのは `secret_key_base` のみだが、これはアプリの「信頼の根」であり、漏洩時の影響は広範囲に及ぶ。

| 用途 | 漏洩時の影響 |
|---|---|
| JWT の署名鍵（API 版） | 任意ユーザーになりすました token を偽造できる（`app/lib/json_web_token.rb` が `Rails.application.secret_key_base` を流用しているため） |
| 署名付き / 暗号化 Cookie | セッションの偽造・改ざん |
| Active Storage の `signed_id` | 添付を許す capability の偽造 |
| `MessageVerifier` 全般 | 署名検証の全面的な破綻 |

### 鍵のローテーション

`master.key` が Git 履歴へ混入した場合、`.gitignore` への追加や `git rm --cached` による追跡除外は対処にならない。**`.gitignore` は未追跡ファイルにしか効かず、Git の履歴は追記型であるため、過去のブロブは clone した全員の手元に残り続ける**ためである。

したがって本質的な対処は **鍵の無効化（ローテーション）** とする。

```bash
cd <app>
mv config/master.key config/credentials.yml.enc <backup-dir>/   # 復旧用に退避
EDITOR=true bin/rails credentials:edit                          # 新しい鍵と credentials を再生成
```

- `EDITOR=true` は「何もせず終了ステータス 0 を返す」ため、エディタを開かずテンプレートのまま再暗号化できる。`EDITOR=cat` は復号された平文を標準出力に出してしまうため使わない。
- ローテーション後は、旧鍵で署名された JWT・Cookie・`signed_id` がすべて検証に失敗する（＝漏洩した鍵が無効化される）。稼働中のサービスでは全ユーザーの再ログインが発生する点に注意する。
- Git 履歴の書き換え（`git filter-repo` / BFG + force-push）は本質的な対処ではないため実施しない。GitHub は force-push 後も dangling commit を一定期間参照可能で完全消去は保証されず、ローテーション済みであれば履歴に残る鍵は復号能力を持たない無効な文字列にすぎない。

※ トレーニング目的のため、最低限のRailsデフォルトセキュリティを活用する方針
