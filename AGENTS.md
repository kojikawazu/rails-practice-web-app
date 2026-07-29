# Codex instructions

このリポジトリでは `.claude/rules/` が開発ルールの唯一の正本です。作業を始める前に、`CLAUDE.md` と変更対象に応じた以下のルールを読み、守ってください。ルール本文をこのファイルへ複製しないでください。

## 常に適用するルール

- `.claude/rules/coding-standards.md`
- `.claude/rules/duplication.md`
- `.claude/rules/dead-code.md`
- `.claude/rules/static-analysis.md`
- `.claude/rules/error-handling.md`
- `.claude/rules/security.md`
- `.claude/rules/testing.md`
- `.claude/rules/documentation.md`
- `.claude/rules/github-issue.md`

Ruby ファイルを変更する場合は、さらに `.claude/rules/ruby.md` を読みます。

## パス別ルール

より深いディレクトリの `AGENTS.md` がある場合は、ここに加えてその指示も適用します。

- `rails-task-fullstack-web-app/**`: `rails-task-fullstack-web-app/AGENTS.md`
- `rails-task-api-web-app/**`: `rails-task-api-web-app/AGENTS.md`
- `.github/workflows/**`: `.github/workflows/AGENTS.md`

## ルール構成を変更するとき

`.claude/rules/` の本文が唯一の正本です。ルールファイルの追加・削除・改名・適用範囲変更時は、同一変更で `CLAUDE.md`、該当する `AGENTS.md`、README の「AI エージェント向けルール」表を同期してください。ルール本文だけの変更では、これらの入口ファイルを更新する必要はありません。

## ショートカットの扱い

`CLAUDE.md` の Instruction Shortcuts の意図は守ります。ただし Claude 固有の機能名は、利用可能な Codex の機能・指示に読み替えます。Codex は PR の承認・マージを実行しません。
