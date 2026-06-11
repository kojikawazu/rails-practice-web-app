# CI/CD・ローカルインフラ方針

> 本プロジェクトは**ローカル開発のみ**で本番デプロイは対象外。クラウドへの自動デプロイ（CD）は存在しない。

## 目次

- [CI 方針（GitHub Actions）](#ci-方針github-actions)
  - [ジョブ構成](#ジョブ構成)
  - [パスフィルターで docs-only をスキップ](#パスフィルターで-docs-only-をスキップ)
  - [テストマトリクスと :js ジョブ](#テストマトリクスと-js-ジョブ)
- [ローカルインフラ（docker-compose）](#ローカルインフラdocker-compose)
- [Makefile（タスクランナー）](#makefileタスクランナー)
- [デプロイについて](#デプロイについて)

[← 目次に戻る](README.md)

## CI 方針（GitHub Actions）

CI は `.github/workflows/ci.yml` の単一ワークフロー。`push`（main）と `pull_request` で起動し、`concurrency` で同一 ref の古い実行をキャンセルする。

### ジョブ構成

3 ジョブで構成する。

| ジョブ | 役割 |
|--------|------|
| **Detect changes** | パスフィルターでコード変更の有無（`code` 出力）を 1 か所で判定する |
| **Test (${{ matrix.app }})** | 両アプリで Minitest + RSpec を実行（`code == 'true'` のときのみ） |
| **System (:js, headless Chrome)** | フルスタック版の `:js` System spec を実行（`code == 'true'` のときのみ） |

### パスフィルターで docs-only をスキップ

- `Detect changes` は `dorny/paths-filter` で「コードとは何か」を**positive パターンで列挙**する（取りこぼさない安全側）。

```yaml
filters: |
  code:
    - 'rails-task-fullstack-web-app/**'
    - 'rails-task-api-web-app/**'
    - '.github/workflows/**'
```

- 上記に該当しない変更（`docs/**` / `**.md` / `README` / `.claude/**` 等）は **`code=false`** となり、下流の重いジョブ（Test / System）が `if` 条件でスキップされる。
- **スキップされたジョブは required check 上では成功扱い**になるため、ブランチ保護を有効にしても docs-only PR のマージはブロックされない。ドキュメント変更を軽量に保つための設計。

### テストマトリクスと :js ジョブ

- **Test ジョブ**は `matrix.app = [fullstack, api]` で 2 アプリを並列実行（`fail-fast: false`）。各ジョブで `postgres:16` サービスを起動し、`bin/rails db:test:prepare` → `bin/rails test`（Minitest）→ `bundle exec rspec`（RSpec）の順に走らせる。
  - Rails 標準の Minitest と RSpec が**併存**しており、CI は両方を実行する。
- **System (:js) ジョブ**はフルスタック版のみ（`working-directory` 固定）。headless Chrome で `bundle exec rspec --tag js` を実行し、Turbo 退行の回帰ガードとする（Selenium が不要な API 版には無い）。
- Ruby バージョンは各アプリの `.ruby-version`、依存は `bundler-cache: true` でキャッシュする。

## ローカルインフラ（docker-compose）

ルートの `docker-compose.yml` で**ミドルウェアのみ**を起動する（Rails 本体はローカル実行・コンテナ化しない）。

| サービス | イメージ | 役割 |
|----------|----------|------|
| `db` | `postgres:16` | DB（ポート `5434:5432`、`pgdata` ボリューム） |
| `minio` | `minio/minio` | S3 互換ストレージ（`9000` API / `9001` コンソール）。フルスタック版 Active Storage のバックエンド |
| `createbuckets` | `minio/mc` | 起動時にバケットを作成する使い捨てコンテナ（`minio` の healthy 待ち） |

- 認証情報・接続情報は `.env`（`.env.example` をテンプレートに生成）から読み込み、ハードコードしない。

## Makefile（タスクランナー）

ルートの `Makefile` が開発用タスクをまとめる。`APP` 変数でアプリを切り替える（既定 `fullstack`、`make test APP=$(API)` 等）。

| 分類 | 主なターゲット |
|------|----------------|
| Docker | `up` / `down` / `restart` / `ps` / `logs` / `clean` / `env` |
| セットアップ | `setup` / `setup-all`（`bin/setup --skip-server`） |
| DB | `db-setup` / `migrate` / `db-prepare` / `db-reset` / `seed` |
| 実行 | `server` / `console` |
| テスト | `test`（Minitest + RSpec） / `test-js`（`:js`、fullstack のみ） / `test-all`（両アプリ） |
| 品質 | `lint` / `lint-fix`（RuboCop） / `security`（bundler-audit + Brakeman） / `ci` / `ci-all` |

> ローカル CI（`make ci`）と GitHub Actions の Test ジョブは同等のチェックを意図する。push 前にローカルで揃えられる。

## デプロイについて

- **本番デプロイは行わない。CD パイプラインは存在しない。**
- 各アプリ直下の `Dockerfile` / `config/deploy.yml`（Kamal）は `rails new` が生成した**本番デプロイ用テンプレートで、本プロジェクトでは未使用**。Vercel / Cloud Run / Artifact Registry 等の外部ホスティングは使わない。
