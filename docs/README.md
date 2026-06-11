# ドキュメント索引

Rails Task Web App の仕様・設計ドキュメント一覧。プロジェクト概要・起動手順はリポジトリ直下の [`../README.md`](../README.md) を参照。

ドキュメントは 3 層で構成している。

- **標準仕様書（`01`〜`11`）** — 仕様の正準。番号順に読むと全体像をつかめる。
- **ガイド・設計資料（[`12-code-reading-guide/`](./12-code-reading-guide/) / [`14-design/`](./14-design/)）** — コードリーディングの手引きと開発設計実装方針。
- **モック・テスト設計（[`13-mockups/`](./13-mockups/) / [`15-test-design/`](./15-test-design/)）** — 画面モック（HTML）とテスト設計の詳細ケース表。

## 目次

- [読み進め順（おすすめ）](#読み進め順おすすめ)
- [標準仕様書](#標準仕様書)
- [12-code-reading-guide/ — コードリーディングガイド](#12-code-reading-guide--コードリーディングガイド)
- [14-design/ — 開発設計実装方針](#14-design--開発設計実装方針)
- [13-mockups/ — 画面モック](#13-mockups--画面モック)
- [15-test-design/ — テスト設計](#15-test-design--テスト設計)
- [関連](#関連)

## 読み進め順（おすすめ）

`01 要求 → 02 要件 → 03 機能 → 05 データ → 06 セキュリティ → 07 API → 08 テスト → 09 アーキテクチャ`。
04・10・11 は随時参照。初めて環境構築する場合は [ルート README の Quick Start](../README.md#quick-start) から。2 構成（フルスタック / API）を読み比べる場合は [`12-code-reading-guide/`](./12-code-reading-guide/README.md) が入口。

## 標準仕様書

| # | ドキュメント | 概要 |
|---|---|---|
| 01 | [要求仕様書](./01-business-requirements.md) | 背景・目標・スコープ・ステークホルダー・制約 |
| 02 | [要件仕様書](./02-requirements-specification.md) | 機能要件一覧・受け入れ基準・優先度 |
| 03 | [機能仕様書](./03-functional-specification.md) | 各機能詳細・画面遷移・確認画面・バリデーション |
| 04 | [非機能仕様書](./04-non-functional-specification.md) | インフラ構成・ポート番号 |
| 05 | [データ仕様書](./05-data-specification.md) | ER 図・テーブルスキーマ・Active Storage |
| 06 | [セキュリティ仕様書](./06-security-specification.md) | 認証・認可・preview_url の iframe 多層防御 |
| 07 | [API 仕様書](./07-api-specification.md) | エンドポイント・JWT 認証・リクエスト/レスポンス・ステータスコード |
| 08 | [テスト仕様書](./08-test-specification.md) | テスト戦略・テストケース・2 アプリのテスト構成差分 |
| 09 | [アーキテクチャ仕様書](./09-architecture-specification.md) | システム構成・Docker/コンテナ構成・技術スタック・環境変数 |
| 10 | [その他仕様書](./10-miscellaneous-specification.md) | 用語集・参考資料 |
| 11 | [タスク](./11-tasks.md) | マイルストーン・完了済み実績・進捗 |

## 12-code-reading-guide/ — コードリーディングガイド

起動コマンドと 2 構成（フルスタック / API）の差分を Step 別に読み比べる。

| # | ドキュメント | 対象 |
|---|---|---|
| — | [README（目次）](./12-code-reading-guide/README.md) | ガイド全体の入口 |
| 01 | [routing](./12-code-reading-guide/01-routing.md) | ルーティングの差分 |
| 02 | [auth](./12-code-reading-guide/02-auth.md) | 認証（セッション / JWT）の差分 |
| 03 | [models](./12-code-reading-guide/03-models.md) | モデル・バリデーションの差分 |
| 04 | [controllers](./12-code-reading-guide/04-controllers.md) | コントローラーの差分 |
| 05 | [tests](./12-code-reading-guide/05-tests.md) | テスト構成の差分 |

## 14-design/ — 開発設計実装方針

| # | ドキュメント | 対象 |
|---|---|---|
| — | [README（目次）](./14-design/README.md) | 方針全体の入口 |
| 01 | [development-flow](./14-design/01-development-flow.md) | 開発フロー |
| 02 | [documentation](./14-design/02-documentation.md) | ドキュメント運用 |
| 03 | [frontend](./14-design/03-frontend.md) | フロント設計 |
| 04 | [api-backend](./14-design/04-api-backend.md) | API / バックエンド設計 |
| 05 | [testing](./14-design/05-testing.md) | テスト方針 |
| 06 | [database](./14-design/06-database.md) | DB 方針 |
| 07 | [cicd-infra](./14-design/07-cicd-infra.md) | CI/CD・インフラ |
| 08 | [security](./14-design/08-security.md) | セキュリティ方針 |

## 13-mockups/ — 画面モック

HTML の静的モック画面。ブラウザで [index.html](./13-mockups/index.html) を開くと一覧から各画面・シーケンス図を確認できる。

## 15-test-design/ — テスト設計

| ドキュメント | 対象 |
|---|---|
| [coverage-strengthening/README](./15-test-design/coverage-strengthening/README.md) | カバレッジ補強（分類別の入口） |
| [02-normal](./15-test-design/coverage-strengthening/02-normal.md) | 正常系 |
| [03-semi-normal](./15-test-design/coverage-strengthening/03-semi-normal.md) | 準正常系 |
| [04-abnormal](./15-test-design/coverage-strengthening/04-abnormal.md) | 異常系 |

## 関連

- **このページが docs/ の索引（正本）です**。プロジェクト概要・起動手順は [ルート README](../README.md) を参照（ルート README は要点のクイックリンクのみ）。
- 開発ルール: [`../CLAUDE.md`](../CLAUDE.md) と [`../.claude/rules/`](../.claude/rules/)
- ドキュメント更新の影響マップ: [`../.claude/rules/documentation.md`](../.claude/rules/documentation.md)
