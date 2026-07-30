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

## system spec の学習上重要な境界

Capybara の system spec は、利用者の操作を読みやすく保ちつつ、実ブラウザと Rails の非同期挙動を理解できる形にする。

- `:js` を付ける場合は、Turbo・ブラウザダイアログ・Stimulus など **rack_test では検証できない理由**を spec の先頭または近接するコメントに残す。
- 非同期遷移の完了待機、リトライ、待機時間を設ける場合は、対象となる挙動と防ぐフレークをコメントに残す。
- `fill_in` / `click_button` などの直接操作は、シナリオを読むために許容する。ページオブジェクトを機械的に導入せず、複数 spec で共有する意味のある操作だけを `spec/support/` のヘルパーへ抽出する。
- 直接セレクタ・URL 指定がテスト対象そのもの（表示値、遷移先、フォーム要素）である場合は、抽象化せず spec に残してよい。非自明な場合は、なぜ直接検証するかをコメントに残す。
- system spec は画面操作の検証であり、認可・CSRF・JWT の検証を代替しない。未認証・他ユーザー・不正入力の境界は request spec / scenario spec で検証する。
