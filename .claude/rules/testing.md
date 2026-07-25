---
description: テスト方針（テストの書き方・カバレッジ・実行方法）
globs: 
---

# テスト方針

- **テスト必須**: 実装時はテストコードも必ず書く。
- **テストファースト推奨**: 可能な限りテストを先に書いてから実装する。
- **テストは独立**: 各テストは他のテストに依存しない。
- **テストデータ**: FactoryBot でテストデータを管理する。

## テストツール

| テスト種別 | ツール | 対象 |
|-----------|--------|------|
| ユニットテスト / モデルテスト | RSpec + Shoulda Matchers | 両プロジェクト |
| コントローラーテスト | RSpec + request specs | 両プロジェクト |
| E2E テスト | RSpec + Capybara | rails-task-fullstack-web-app のみ（capybara gem 必須） |
| シナリオテスト | RSpec（request spec ベースの業務ジャーニー） | rails-task-api-web-app（`spec/scenarios/`） |

## spec の配置

テスト対象の種別をディレクトリでミラーする。**Minitest（`test/`）は使わない。**

| ディレクトリ | 対象 |
|---|---|
| `spec/models/` | モデル（バリデーション・リレーション・スコープ）。Shoulda Matchers を使う |
| `spec/requests/` | コントローラー / エンドポイント（HTTP ステータス・レスポンス・リダイレクト） |
| `spec/services/` | Service オブジェクト（ビジネスロジック） |
| `spec/system/` | E2E（Capybara + selenium）。fullstack のみ |
| `spec/scenarios/` | 複数機能を横断する業務ジャーニー |
| `spec/factories/` | FactoryBot のファクトリ定義 |
| `spec/support/` | 共通ヘルパー・shared examples・設定 |

- **テストの期待値・ケース内容は共通化しない**（重複してでも読んで分かることを優先する）。セットアップの共通化は `spec/support/` で行う。詳細は `duplication.md`。
- **スキップされたテストを放置しない**（`xit` / `skip`）。詳細は `dead-code.md`。
