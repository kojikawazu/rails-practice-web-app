# Rails Task Web App

## Instruction Shortcuts

以下の短い指示は、対応するフルアクションとして解釈・実行してください。

| 指示 | アクション |
|------|-----------|
| PR承認しました | main ブランチを pull → マージ済みブランチを削除 → main に切り替え |
| PR出して | 変更をコミット → push → PR 作成 |
| Copilotにレビュー依頼出して | PR のコメントで `@copilot` メンション付きでレビュー依頼を投稿 |
| Copilotからレビュー来ました | PR のレビューコメントを取得・内容を確認・必要な対応を実施 |
| 〇〇を参考にしてください | 参考先は **read-only**（参考先のファイルやリポジトリを変更しない） |

## Rules

明示的な指示がなくても、以下のルールを常に守ってください。

### 開発フロー

- **ブランチ運用**: 開発を開始する際は、必ず作業ブランチを切ってから着手する。main ブランチで直接作業しない。
- **テスト必須**: 実装時はテストコードも必ず書く。

### 品質ゲート

- **セルフレビュー必須**: 要求仕様の作成・ドキュメント生成・設計・実装が完了したら、次のフェーズに進む前にセルフレビューを実施する。
- **セルフレビュー後の修正**: セルフレビューで指摘を検出したら、修正まで実施する。
- **設計完了時**: 要求仕様との齟齬がないか確認し、ユーザーにレビューしてもらう。レビュー完了まで実装に進まない。
- **実装完了時**: 設計仕様との齟齬がないか確認し、ユーザーにレビューしてもらう。

### ドキュメント

- **ドキュメント更新**: 作業が完了したら、ルートドキュメント（CLAUDE.md / README.md / docs/）の更新が必要かどうか確認し、必要であれば更新する。

## Rule Files

詳細ルールは `.claude/rules/` に分割管理しています。

Codex 向けの入口はリポジトリ階層の `AGENTS.md` です。ルール本文は `.claude/rules/` にのみ置き、変更対象に最も近い `AGENTS.md` が指定する追加ルールも適用します。

| ファイル | スコープ | 内容 |
|---------|---------|------|
| `.claude/rules/coding-standards.md` | 全体 | Ruby / Bundler / RuboCop コーディング規約・YARD ドキュメントコメント |
| `.claude/rules/ruby.md` | `**/*.rb` | Ruby / Rails 固有の作法（薄い Controller + Service・定数の配置・レスポンス整形） |
| `.claude/rules/duplication.md` | 全体 | 重複と共通化の判断基準（3 回目で共通化・偶然の一致は残す） |
| `.claude/rules/dead-code.md` | 全体 | デッドコード禁止（コメントアウト・未使用コード・スキップ放置テストを残さない） |
| `.claude/rules/static-analysis.md` | 全体 | 静的解析の運用（Formatter と Linter の役割分担・CI 必須・抑制コメント） |
| `.claude/rules/github-issue.md` | 全体 | GitHub issue 運用（ブランチと対で起票し open/close で進捗管理） |
| `.claude/rules/github-actions.md` | `.github/workflows/**` | GitHub Actions の発火ルール（関係あるジョブだけ動かす・パスフィルタの落とし穴） |
| `.claude/rules/error-handling.md` | 全体 | バリデーション・例外処理・HTTP ステータスコード方針 |
| `.claude/rules/security.md` | 全体 | 認証・CORS・インジェクション対策・シークレット管理 |
| `.claude/rules/testing.md` | 全体 | RSpec / FactoryBot / Shoulda Matchers テスト方針 |
| `.claude/rules/fullstack.md` | `rails-task-fullstack-web-app/app/**` | Rails MVC フルスタック設計ルール |
| `.claude/rules/api.md` | `rails-task-api-web-app/app/**` | Rails API モード設計ルール |
| `.claude/rules/database.md` | 両プロジェクトの `app/models/`, `db/` | ActiveRecord 命名規約・監査列の自動設定・マイグレーション・クエリ規約 |
| `.claude/rules/documentation.md` | 全体 | ドキュメント更新・設計書管理（影響マップ + opt-out 完了条件） |
