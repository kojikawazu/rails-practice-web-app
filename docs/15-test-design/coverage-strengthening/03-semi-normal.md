# 準正常系テストケース（認可・バリデーション）

[← README に戻る](README.md)

| # | テストケース | 入力 | 期待結果 | テスト種別 | 優先度 |
|---|---|---|---|---|---|
| S-1 | 他ユーザーのプロジェクト show | 他人の project に GET | `ActiveRecord::RecordNotFound` を raise（スコープ外） | Request | High |
| S-2 | 他ユーザーのプロジェクト edit/update/destroy | 他人の project に GET edit / PATCH / DELETE | いずれも `RecordNotFound` を raise | Request | High |
| S-3 | 他ユーザーのプロジェクト confirm（member） | 他人の project に POST confirm | `RecordNotFound` を raise | Request | Medium |
| S-4 | 他ユーザーのタスク show/edit/update/destroy | 他人配下の task に各アクセス | `RecordNotFound` を raise | Request | High |
| S-5 | 他ユーザーのプロジェクト配下でタスク作成不可 | 他人の project_id で tasks#new/create | `RecordNotFound` を raise（`set_project` がスコープ外で失敗） | Request | High |
| S-6 | 確認画面 E2E: 不正入力は確認に進まない | title 空で「確認する」 | 確認画面に進まず、入力フォームにエラー表示 | System | Medium |

実装ファイル: `spec/requests/projects_spec.rb`（S-1〜S-3）/ `spec/requests/tasks_spec.rb`（S-4〜S-5）/ `spec/system/confirm_flows_spec.rb`（S-6）。全ケース ✅ 実装済み（認可検証は実 404 レスポンスで検証）。

## 境界値テスト（model spec）

> 第2段で追加。バリデーション上限・下限の境界を model spec で担保した。

| # | テストケース | 入力 | 期待結果 | ファイル | 状態 |
|---|---|---|---|---|---|
| B-1 | プロジェクト title 上限 | 100文字 / 101文字 | valid / invalid | `spec/models/project_spec.rb` | ✅ |
| B-2 | タスク title 上限 | 200文字 / 201文字 | valid / invalid | `spec/models/task_spec.rb` | ✅ |
| B-3 | ユーザー name 上限 | 50文字 / 51文字 | valid / invalid | `spec/models/user_spec.rb` | ✅ |
| B-4 | パスワード下限 | 6文字 | valid（最小境界） | `spec/models/user_spec.rb` | ✅ |
