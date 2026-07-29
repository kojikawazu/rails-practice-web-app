# CI/CD・ローカルインフラ方針

> 本プロジェクトは**ローカル開発のみ**で本番デプロイは対象外。クラウドへの自動デプロイ（CD）は存在しない。

## 目次

- [CI 方針（GitHub Actions）](#ci-方針github-actions)
  - [ジョブ構成](#ジョブ構成)
  - [パスフィルターで発火条件を分ける](#パスフィルターで発火条件を分ける)
  - [Markdown lint](#markdown-lint)
  - [テストマトリクスと :js ジョブ](#テストマトリクスと-js-ジョブ)
- [ローカルインフラ（docker-compose）](#ローカルインフラdocker-compose)
- [Makefile（タスクランナー）](#makefileタスクランナー)
- [デプロイについて](#デプロイについて)

[← 目次に戻る](README.md)

## CI 方針（GitHub Actions）

CI は `.github/workflows/ci.yml` の単一ワークフロー。`push`（main）と `pull_request` で起動し、`concurrency` で同一 ref の古い実行をキャンセルする。

### ジョブ構成

4 ジョブで構成する。

| ジョブ | 役割 |
|--------|------|
| **Detect changes** | パスフィルターで変更範囲（`code` / `docs` 出力）を 1 か所で判定する |
| **Markdown lint** | リポジトリ全体の markdown を lint（`docs == 'true'` のときのみ） |
| **Test (${{ matrix.app }})** | 両アプリで Minitest + RSpec を実行（`code == 'true'` のときのみ） |
| **System (:js, headless Chrome)** | フルスタック版の `:js` System spec を実行（`code == 'true'` のときのみ） |

### パスフィルターで発火条件を分ける

変更内容に関係のあるジョブだけを動かす（`.claude/rules/github-actions.md`）。`Detect changes` は `dorny/paths-filter` で 2 つの出力を返す。

```yaml
filters: |
  code:
    - 'rails-task-fullstack-web-app/**'
    - '!rails-task-fullstack-web-app/**/AGENTS.md'
    - 'rails-task-api-web-app/**'
    - '!rails-task-api-web-app/**/AGENTS.md'
    - '.github/workflows/**'
    - '!.github/workflows/**/AGENTS.md'
  docs:
    - '**/*.md'
    - '.markdownlint-cli2.jsonc'
    - '.github/workflows/**'
```

| 変更内容 | 実行されるジョブ |
|---|---|
| アプリコード | Test / System（+ アプリ配下の `*.md` を含むなら Markdown lint） |
| `docs/**` / `README.md` / `CLAUDE.md` / `.claude/**` / `AGENTS.md` | Markdown lint のみ |
| `.github/workflows/**` | 全ジョブ（ワークフロー自身の検証のため両方に含める） |

- `code` は「コードとは何か」を**positive パターンで列挙**する（取りこぼさない安全側）。
- アプリ・workflow 配下の `AGENTS.md` はルール文書であるため、`code` から明示的に除外する。
- **ドキュメント変更でも「何も動かさない」にはしない**。markdown lint は軽量なため常に実行し、doc-only の変更でも壊れた markdown を検出できる状態を保つ。
- 下流ジョブはワークフローレベルの `paths` ではなく **ジョブレベルの `if` でスキップ**する。**スキップされたジョブは required check 上では成功扱い**になるため、ブランチ保護を有効にしても PR が `pending` のままマージ不能になることがない。

### Markdown lint

- ツールは **markdownlint-cli2**（`npx --yes markdownlint-cli2 "**/*.md"`）。設定はリポジトリルートの `.markdownlint-cli2.jsonc` に置き、**CI とローカル（`make lint-md`）で同一設定**を使う。
- 見た目のみの規則（`MD013` 行長 / `MD060` 表のパイプ位置 / `MD033` インライン HTML）は無効化している。markdown formatter を導入していないため、Linter で見た目を見ない方針（`.claude/rules/static-analysis.md`）。
- 対象は 49 ファイル・**違反ゼロ**が基準。自動修正は `make lint-md-fix`。

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
| 品質 | `lint` / `lint-fix`（RuboCop） / `lint-md` / `lint-md-fix`（markdownlint） / `security`（bundler-audit + Brakeman） / `ci` / `ci-all` |

> ローカル CI（`make ci`）と GitHub Actions の Test ジョブは同等のチェックを意図する。push 前にローカルで揃えられる。

## デプロイについて

- **本番デプロイは行わない。CD パイプラインは存在しない。**
- 各アプリ直下の `Dockerfile` / `config/deploy.yml`（Kamal）は `rails new` が生成した**本番デプロイ用テンプレートで、本プロジェクトでは未使用**。Vercel / Cloud Run / Artifact Registry 等の外部ホスティングは使わない。
