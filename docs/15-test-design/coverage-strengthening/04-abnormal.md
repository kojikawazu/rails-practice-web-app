# 異常系テストケース

[← README に戻る](README.md)

| # | テストケース | 入力 | 期待結果 | テスト種別 | 優先度 |
|---|---|---|---|---|---|
| A-1 | 存在しない project_id でタスク一覧 | 実在しない id で tasks 系アクセス | `RecordNotFound` を raise（500ではなく想定内の経路） | Request | Low |

実装ファイル: `spec/requests/tasks_spec.rb`。✅ 実装済み。

> 注: DB接続断・タイムアウト等の真の異常系は、トレーニング用途かつ単一ローカル構成のためスコープ外（`docs/04-non-functional-specification.md` に整合）。
