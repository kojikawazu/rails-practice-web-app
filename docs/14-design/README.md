# 開発設計実装方針（MVP開発レベル）

> 本文書群はMVP開発における**厳格な標準（ベースライン）**である。
> メインスタックは Next.js + Go + GCP を想定するが、言語・クラウドが変わる場合はベンダー固有部分を適宜読み替えること。

本方針は読みやすさのためトピック別に分割している。全体像はこの目次から辿ること。

## 目次

| ファイル | 内容 |
|---|---|
| [01-development-flow.md](01-development-flow.md) | 開発フロー方針・Git運用方針 |
| [02-documentation.md](02-documentation.md) | ドキュメント方針 |
| [03-frontend.md](03-frontend.md) | フロントエンド設計方針 |
| [04-api-backend.md](04-api-backend.md) | API設計・BFF・バックエンド設計方針 |
| [05-testing.md](05-testing.md) | テスト方針・エラーハンドリング方針 |
| [06-database.md](06-database.md) | DB設計方針 |
| [07-cicd-infra.md](07-cicd-infra.md) | CI/CD方針・クラウド/ホスティング設計方針 |
| [08-security.md](08-security.md) | セキュリティ設計方針 |

## 全体

- それぞれの言語仕様のコーディング規約に準ずる。
- リンター・フォーマッターを導入し、コード品質を自動で担保する。
- 環境変数で環境差分を管理する（.env）。
