# 教訓ログ

誤り・失敗・ハマりから得た教訓を蓄積する。記録の運用ルール（記録トリガー・フォーマット・ルールへの昇格基準）は [`../.claude/rules/lessons-learned.md`](../.claude/rules/lessons-learned.md) を参照。

新しいエントリはこの見出しの直下に追記する（新しいものが上）。

<!-- 記入例（実際のエントリを追記する際は、この例より下に残さず先頭へ追加する）

## YYYY-MM-DD 何が起きたかが一読で分かる一文

### 概要

何が起きて何が問題だったかを 1〜3 行で。ここだけ読んで内容が掴める粒度にする。

### 詳細

- 何が起きたか: 事象・影響範囲（対象データ・ユーザー・期間）
- なぜ起きたか（根本原因）: どのコード・設定・判断が原因か
- 教訓 / 次からどうする: 次に同じ状況でとるべき具体的な行動
- 関連: 関連するルールファイル・PR・issue・コミットへの参照

-->

## 2026-10-11 CSP 違反は :js system spec を落とさず、Turbo のプログレスバーがブロックされ続けていた

### 概要

`docs/06-security-specification.md` に「`:js` の system spec は CSP 違反をテストの失敗として検出できる」と書いていたが、誤りだった。Turbo のプログレスバー用 `<style>` が CSP の `style-src` でブロックされ、遷移のたびにコンソールへ違反が出ていたのに、`:js` spec はすべて green のままだった。

### 詳細

- 何が起きたか: フルスタック版で Turbo が挿入するプログレスバーの `<style>` が CSP でブロックされ、遅い遷移で進捗が見えない状態になっていた。CSP を enforce にした時点（#101 / PR #130 より前）から存在し、PR #130 の移行前後比較でブラウザのコンソールを見て初めて気づいた（#132）。セキュリティ上の後退ではなく、ブロックされる側の不具合。
- なぜ起きたか（根本原因）: CSP 違反は、ブラウザがその資源を黙って無効にし、コンソールにメッセージを出すだけで、ページ操作は成功する。インライン `onclick` のように**ブロックで操作そのものが壊れる**場合は、遷移しないことで spec が落ちる。一方、`<style>` のように**見た目だけが変わる**場合は spec が落ちない。前者の経験から「CSP 違反は spec で検出できる」と一般化して書き、違反を意図的に起こして赤になるかを確かめていなかった。違反の原因は、`content_security_policy_nonce_directives` が `script-src` だけで、Turbo が `<style>` に付けた nonce を `style-src` で照合できなかったこと。
- 教訓 / 次からどうする:
  - CSP 違反を spec で検出したいときは、ブラウザログを取得して違反メッセージの有無を検査する（selenium の `logging_prefs = { browser: "ALL" }` と `page.driver.browser.logs.get(:browser)`）。ログ取得の設定外れで素通りしないよう、既知のメッセージ（`console.error` のプローブ）が取得できることも同じ spec で確認する。
  - 「〇〇はテストで検出できる」とドキュメントに書く前に、〇〇を意図的に起こして、テストが実際に赤になることを確かめる。確かめていない検出能力を書かない。
- 関連: #132 / PR #139（`style-src` に nonce を追加し、`spec/system/csp_violations_js_spec.rb` を追加）、#101 / PR #130、`.claude/rules/testing.md`（「検出の確かめ方」としてルール化。#145）。「エラーにならず黙って効かない」という点で、下の 2026-10-08 のエントリ（`form_with` の `style:`）と同じ型の見逃し

## 2026-10-08 form_with に渡した style: が黙って捨てられ、フォームの幅指定が一度も効いていなかった

### 概要

フルスタック版のプロジェクト / タスクのフォームに `form_with(..., class: "card", style: "max-width:600px;")` と書いていたが、`style:` は HTML に出力されず、フォームは全幅で表示され続けていた。エラーも警告も出ないため、書かれた当初からコードレビューでも気づかれず、#101 で移行前後のスクリーンショットをピクセル比較して初めて判明した。

### 詳細

- 何が起きたか: `app/views/projects/_form.html.erb` と `app/views/tasks/_form.html.erb` の `max-width:600px` が適用されず、新規作成・編集フォーム（5 画面）のカードが全幅になっていた。確認画面・詳細画面のカードは 600px のため、フォームから確認画面へ進むとカードの幅が変わっていた。機能・データへの影響はない。
- なぜ起きたか（根本原因）: `form_with` が直下のキーワード引数から HTML 属性として拾うのは `id` / `class` / `multipart` / `method` / `data` / `authenticity_token` だけで（`ActionView::Helpers::FormHelper#html_options_for_form_with` の `options.slice(...)`）、それ以外の属性は `html: { ... }` で渡さないと捨てられる。`link_to` や `image_tag` は任意の属性をそのまま出力するため、同じ感覚で `style:` を直下に書いてしまい、捨てられたことにも気づけなかった。
- 教訓 / 次からどうする:
  - `form_with` に `id` / `class` / `data` 以外の HTML 属性を付けるときは `html: { ... }` で渡す。付けた属性は、ブラウザの DOM か request spec のレスポンス HTML で、実際に出力されていることを確かめる。
  - 「見た目を変えない」前提のリファクタ（CSS 移行・レイアウト整理）は、前後のスクリーンショットをピクセル単位で比較し（ImageMagick の `compare -metric AE`）、差分が出た画面は原因を説明できるまで調べる。差分ゼロを確認できない変更を「見た目は同じ」と報告しない。
- 関連: #101 / PR #130（インライン style の CSS 移行で判明し、`card-narrow` で 600px に揃えた）、#131、`.claude/rules/testing.md`（「検出の確かめ方」としてルール化。#145）

## 2026-10-07 既存 issue を検索せずに起票し、2 か月放置されていた同じ issue と重複した

### 概要

CI に RuboCop / brakeman / bundler-audit を追加する作業で #114 を起票したが、同じ内容の #65 が 2026-07-25 から open のまま存在していた。#65 は親 issue #74 で「最優先」とされていたにもかかわらず着手されていなかった。

### 詳細

- 何が起きたか: #114 を起票して #115 で対応した後、open issue を一覧して #65 との重複に気づいた。同時に、github-actions 用の dependabot.yml も #108 として起票済みだった。同日のエントリ「CI 必須の静的解析・脆弱性検査が CI に無く Dependabot アラートが 74 件溜まった」の教訓「issue を立てて追跡する」は、実際には issue が存在していたため不正確であり、本エントリで訂正する。
- なぜ起きたか（根本原因）: 起票の前に既存 issue を検索する手順がなく、ルール（`.claude/rules/github-issue.md`）も「ブランチと対で起票する」ことだけを定めている。また、乖離調査（#74）で優先度を付けて起票しても、それを次の作業の選択に使う手順がなく、優先度の高い issue が手つかずのまま残った。
- 教訓 / 次からどうする: 起票の前に `gh issue list --state open --search "<キーワード>"` で重複を確認し、該当があればその issue を使う。作業を選ぶときは、まず open の親 issue（例: #74）の優先順を確認する。「未実装」の状態を防ぐのは起票ではなく、起票した issue を消化することである。
- 関連: #65、#74、#108、#114、#115、`.claude/rules/github-issue.md`、本日付エントリ「CI 必須の静的解析・脆弱性検査が CI に無く Dependabot アラートが 74 件溜まった」

## 2026-10-07 dependabot.yml が無いから修正 PR が来ないと誤診した

### 概要

Dependabot アラートが溜まった原因を「`.github/dependabot.yml` が無く修正 PR が作られないため」と説明し、その対策を提案した。実際には security update PR は作られており、放置されていただけだった。

### 詳細

- 何が起きたか: アラート解消後の再発防止として `dependabot.yml` の追加を提案し、着手直前の調査で Dependabot の PR（#109〜#111）が既に存在していたことが判明した。提案の前提が誤っており、対策もずれていた（PR が来ないことではなく、来た PR に気づけないことが問題）。
- なぜ起きたか（根本原因）: 設定ファイルの有無だけから挙動を推測し、実際の成果物（Dependabot が作った PR）を確認しないまま原因を断定した。security updates はリポジトリ設定で有効化でき、`dependabot.yml` は version updates 用であるため、ファイルが無くても PR は作られる。
- 教訓 / 次からどうする: 「〇〇が動いていない」と判断する前に、その仕組みの出力を直接確認する。Dependabot なら `gh pr list --author app/dependabot --state all` と `gh api repos/{owner}/{repo}/automated-security-fixes` を見てから原因を述べる。
- 関連: #112、#113、#115

## 2026-10-07 範囲指定なしの bundle update で puma と json がメジャーアップした

### 概要

脆弱な gem の更新に `bundle update --conservative <gems>` を使ったところ、修正に不要なメジャーアップ（puma 7→8、json 2→3）と、それに引きずられた rubocop の更新が入った。

### 詳細

- 何が起きたか: Dependabot アラート解消のための lockfile 更新で、修正版がパッチ版で出ているにもかかわらず最新メジャーまで上がった。コミット前の差分確認で気づき、やり直した。
- なぜ起きたか（根本原因）: `--conservative` は「指定した gem の依存を不必要に動かさない」指定であり、指定した gem 自体の上げ幅は制限しない。Gemfile の制約が `puma ">= 5.0"` のように緩い gem は、`--patch` などの上げ幅指定がなければ最新メジャーまで上がる。
- 教訓 / 次からどうする: 脆弱性対応の gem 更新は `bundle update --patch --conservative <gems>` を基本にし、修正版が新しいマイナーにしかない gem だけ `--minor` で個別に上げる。更新後は `git diff -U0 Gemfile.lock` でバージョンの変化を一覧し、メジャーアップが混ざっていないか確認してからテストする。
- 関連: #113

## 2026-10-07 CI 必須の静的解析・脆弱性検査が CI に無く Dependabot アラートが 74 件溜まった

### 概要

ルール上は CI 必須の RuboCop / brakeman / bundler-audit が CI ジョブとして存在せず、Dependabot の修正 PR も見落とされたため、critical 2 件を含むアラートが 74 件溜まった。

### 詳細

- 何が起きたか: 両アプリの `Gemfile.lock` に activestorage（critical）・puma・nokogiri・net-imap などの既知の脆弱性が残り続けた。Dependabot の security update PR は作られていたが、マージされないまま放置された。
- なぜ起きたか（根本原因）: `.claude/rules/ruby.md` と `static-analysis.md` は「brakeman + bundler-audit を CI で実行」「Linter は CI 必須」と定めていたが、`ci.yml` には markdown lint とテストしかなかった。ルールを置いただけで実行の仕組みが無く、`docs/10-miscellaneous-specification.md` にも「CI ジョブは未追加」と書かれたまま放置されていた。脆弱な依存があっても PR が落ちないため、気づく契機が Dependabot の通知だけになっていた。
- 教訓 / 次からどうする: ルールで「CI 必須」とした検査は、ルールの追加と同じ変更で CI ジョブまで作る。ドキュメントに「未追加」「未実装」と書く状態を作ったら、その場で issue を立てて追跡する。CI の Brakeman は Rails 既定の `bin/brakeman --ensure-latest` で本体が最新版でないと失敗するため、落ちたら `bundle update --conservative brakeman` で追従する。
- 関連: `.claude/rules/ruby.md`、`.claude/rules/static-analysis.md`、#112、#113、#114、#115、kojikawazu/my-custom-skills#290
