# 正常系テストケース

[← README に戻る](README.md)

| # | テストケース | 入力 | 期待結果 | テスト種別 | 優先度 |
|---|---|---|---|---|---|
| N-1 | プロジェクト一覧に自分のプロジェクトだけ表示 | 自分の project A + 他人の project B、ログイン | body に A.title を含み、B.title を含まない | Request (index 内容) | High |
| N-2 | タスク一覧（プロジェクト詳細）にステータスバッジ表示 | status 違いの task を複数作成、show 表示 | 「未着手」「進行中」「完了」バッジ文言が表示される | Request (show 内容) | High |
| N-3 | 確認画面 E2E: 登録（signup）通し | name/email/password 入力→確認→登録 | 確認画面に入力値表示→「登録する」で User +1・projects へ遷移 | System (rack_test) | High |
| N-4 | 確認画面 E2E: プロジェクト新規作成 通し | title/description 入力→確認→作成 | 確認画面に値表示→「作成する」で Project +1・詳細へ遷移 | System | High |
| N-5 | 確認画面 E2E: タスク編集 通し | 既存 task の title 変更→確認→更新 | 確認画面に新値表示→「更新する」で値が永続化・詳細へ遷移 | System | Medium |
| N-6 | 確認画面 E2E: 「修正する」で入力値が保持される | 入力→確認→「修正する」 | 入力フォームに戻り、入力した値がフォームに残っている | System | **High**（今回追加機能の核心） |

実装ファイル: `spec/requests/projects_spec.rb`（N-1, N-2）/ `spec/system/confirm_flows_spec.rb`（N-3〜N-6）。全ケース ✅ 実装済み。

## 削除確認ダイアログ（turbo_confirm / JS）

> 第2段で追加。第1段では「JS 必須のためスコープ外」としていた削除確認を、selenium ドライバで補強した。

| # | テストケース | 操作 | 期待結果 | 状態 |
|---|---|---|---|---|
| J-1 | キャンセルで残る | `dismiss_confirm { 削除 }` | プロジェクトが削除されない | ✅ |
| J-2 | 承認でタスク削除 | `accept_confirm { 削除 }` | タスクが削除される | ✅ |
| J-3 | 承認でプロジェクト削除 | `accept_confirm { 削除 }` | プロジェクトが削除される | ✅ |

- ファイル: `spec/system/delete_confirmation_spec.rb`（`:js` タグ）
- ドライバ: **selenium / headless Chrome**。`spec/support/capybara.rb` で `:js` のみ selenium、他は rack_test。
- 通常の `rspec` からは除外（`filter_run_excluding js: true`）。実行は `rspec --tag js` または CI。
- **DB 可視性**: Rails 7.1+/rspec-rails 7 の system test はテスト/サーバースレッドで DB コネクションを共有するため、トランザクションフィクスチャ（`use_transactional_fixtures = true`）のまま selenium でもテストデータが見える。
- **安定化**: selenium の連続ログインが sandbox 環境で不安定だったため、(a) `sign_in_as` に遷移完了待ち（`have_current_path`）を追加、(b) `Capybara.default_max_wait_time = 5`、(c) J-1〜J-3 を 1 ログイン・1 example に集約。3 回連続実行でグリーンを確認。
