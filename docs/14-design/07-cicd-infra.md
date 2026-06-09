# CI/CD・クラウド/ホスティング設計方針

[← 目次に戻る](README.md)

## CI/CD方針

### デプロイ先の選択

プロジェクト要件に応じて、フロントエンド・バックエンドそれぞれのデプロイ先を選択する。

| 対象 | 選択肢 | 採用基準 |
|---|---|---|
| **フロントエンド** | Vercel | Next.jsとの親和性が高い・プレビューデプロイが必要・手軽にMVPを出したい場合 |
| **フロントエンド** | Cloud Run | GCPに統一したい・Vercelの制約（タイムアウト・リージョン等）を超えたい・SSRの細かい制御が必要な場合 |
| **バックエンド** | Cloud Run | コンテナベースでスケーラブルなAPI基盤が必要な場合（デフォルト） |
| **バックエンド** | なし（一体型） | Next.js App Router内で完結する場合（BFFのみ） |

### フロントエンド CI/CD

#### Vercel の場合

- Vercelのデフォルトのビルド・デプロイを利用する。
- CI上で **E2Eテスト** を実行する（Playwright等）。
- プレビューデプロイでPR単位の動作確認を行う。

#### Cloud Run の場合

- GitHub Actions等でCI/CDパイプラインを構築する。
- **CI（Push / PR時）**
  - リント・フォーマットチェック
  - ユニットテスト・E2Eテスト
  - ビルド確認
- **CD（mainマージ時）**
  - コンテナイメージのビルド・プッシュ（Artifact Registry）
  - Cloud Runへの自動デプロイ
- Dockerfileで `next build` → `next start` を実行する構成とする。

### 共通

- ドキュメントのみの変更（`*.md` 等）では**ビルド・デプロイのCI/CDは実行しない**。
  - パスフィルターで除外する。
- ただし、以下の**軽量チェックは実行する**。
  - markdownリント
  - リンク切れチェック
  - 必須ファイル（README.md, CLAUDE.md）の存在検証

### バックエンド CI/CD（Cloud Run）

- GitHub Actions等でCI/CDパイプラインを構築する。
- **CI（Push / PR時）**
  - リント・フォーマットチェック
  - ユニットテスト
  - ビルド確認
- **CD（mainマージ時）**
  - コンテナイメージのビルド・プッシュ（Artifact Registry）
  - Cloud Runへの自動デプロイ

## クラウド・ホスティング設計方針

プロジェクト要件に応じて構成を選択する。

| 構成パターン | フロントエンド | バックエンド | 採用基準 |
|---|---|---|---|
| **Vercel + Cloud Run** | Vercel | Cloud Run（Go等） | フロントの手軽さとバックエンドの柔軟性を両立したい場合 |
| **Vercel一体型** | Vercel | なし（App Router内で完結） | 小規模MVP・バックエンド分離が不要な場合 |
| **GCP統一型** | Cloud Run | Cloud Run | GCPに統一したい・Vercelの制約を超えたい場合 |

### Vercel

- Next.jsのフロントエンドホスティングに使用する。
- Vercel固有の機能（Edge Functions, Image Optimization等）を活用する場合はベンダーロックインに注意する。
  - 移行コストを最小化するため、Vercel固有APIへの依存は最小限にする。

### Cloud Run

- バックエンドのホスティングに使用する。フロントエンドをCloud Runでホストする場合も同様。
- コンテナイメージは Artifact Registry で管理する。

### Artifact Registry

- コンテナイメージは**過去3世代分のみ保持**する。
  - クリーンアップポリシーまたはCI/CDパイプライン内で古いイメージを削除する。
