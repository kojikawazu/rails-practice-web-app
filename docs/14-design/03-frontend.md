# フロントエンド（View 層）設計方針

> 本方針はフルスタック版（`rails-task-fullstack-web-app`）の View 層が対象。
> API 版（`rails-task-api-web-app`）は `rails new --api` で **View 層を持たない**（JSON のみ）ため対象外。

## 目次

- [基本方針](#基本方針)
- [テンプレート構成](#テンプレート構成)
  - [レイアウトとパーシャル](#レイアウトとパーシャル)
  - [ロジックを View に書かない](#ロジックを-view-に書かない)
- [Turbo / Stimulus（Hotwire）](#turbo--stimulushotwire)
  - [Turbo Drive と確認画面の例外](#turbo-drive-と確認画面の例外)
  - [プロジェクト新規作成の PRG 例外](#プロジェクト新規作成の-prg-例外)
  - [Stimulus コントローラー](#stimulus-コントローラー)
  - [Importmap](#importmap)
- [ディレクトリ構成](#ディレクトリ構成)

[← 目次に戻る](README.md)

## 基本方針

- **サーバーサイドレンダリング**（ERB）を基本とする。SPA フレームワーク（React / Next.js 等）は採用しない。
- インタラクションは Rails 標準の **Hotwire（Turbo + Stimulus）+ Importmap** で最小限に実装する（Node ビルドを持たない）。
- フォームは `form_with` ヘルパーで生成する（CSRF トークンが自動付与される）。

## テンプレート構成

### レイアウトとパーシャル

- 全体レイアウトは `app/views/layouts/application.html.erb`。サイドバー + メインエリア構成で、`logged_in?` でナビ表示を分岐し、フラッシュメッセージ領域を持つ。
- 再利用する UI 部品はパーシャルに切り出す。
  - 例: 新規/編集で共通の入力フォームを `_form.html.erb` に集約する（`projects/_form.html.erb`, `tasks/_form.html.erb`）。
- 認証系画面（ログイン・登録）は中央寄せの単体レイアウトとする。

### ロジックを View に書かない

- 条件分岐・整形ロジックは View に直接書かず、**Helper** またはモデル/Presenter 相当に寄せる（`.claude/rules/fullstack.md`）。
- 確認画面のように「保存はせず `valid?` のみ実行して表示する内容」は、Controller がメモリ上のオブジェクトを組み立てて View に渡す。View は描画に専念する。

## Turbo / Stimulus（Hotwire）

### Turbo Drive と確認画面の例外

本アプリは登録・作成・編集で**確認画面**を挟む（仕様は `docs/03`）。確認画面は「POST に対し別ページを 200 で描画する」パターンで、これは Turbo Drive と相性が悪い。

- **Turbo Drive は非リダイレクトの 200 応答を破棄する**ため、有効のままだと確認画面へ遷移できない。
- そのため、確認画面へ POST するフォームには `data: { turbo: false }`（Turbo 無効・フルページ遷移）を付与する。
  - 対象: ユーザー登録 / プロジェクト編集 / タスク作成・編集の各フォーム。
- 一方、削除ボタンの `turbo_confirm`（確認ダイアログ）は **Turbo が必要なため無効化しない**。確認画面とは扱いを分ける。

| 用途 | Turbo | 理由 |
|------|-------|------|
| 確認画面へ POST するフォーム（登録/編集/タスク） | 無効（`turbo: false`） | 非リダイレクト 200 が破棄されるため |
| 削除ボタン | 有効 | `turbo_confirm` ダイアログに必要 |
| プロジェクト新規作成の確認 | 有効（下記 PRG） | リダイレクトで Turbo と両立 |

### プロジェクト新規作成の PRG 例外

**プロジェクト新規作成のみ**、確認ステップを **PRG（Post / Redirect / Get）**で実装する。

- `confirm`(POST) は `valid?` 後に入力値を `session[:pending_project]` へ退避し、`confirm`(GET) へ **303 リダイレクト**する。
- `confirm`(GET) が session から確認画面を描画する（session 不在時は `new` へ戻す＝リロード安全網）。
- これにより **Turbo Drive を有効化できる**（白画面なし）うえ、確認画面のリロードも安全になる。「修正する」は session が値を保持するため GET リンク（`new?restore=1`）で戻る。
- リダイレクト方式は JS 非依存で、Turbo は白画面除去の上乗せにすぎない。**新規のみ**が対象で、編集・タスク・登録は前節の `turbo: false` 方式のまま。

> 確認ルートは GET / POST 両方を受ける。`turbo: false` のフルページ POST のため、確認 URL をリロード/戻る操作で GET すると `show` に誤って落ちる。これを防ぐため GET 時は入力フォームへリダイレクトする（`docs/03` 参照）。

### Stimulus コントローラー

- クライアント側の振る舞いは Stimulus コントローラー（`app/javascript/controllers/`）に閉じ込める。
- 例: `flatpickr_controller.js` — タスクの開始日/終了日入力に flatpickr を適用し、開始日の変更に応じて終了日の選択可能下限（`minDate`）を連動させる。`allowInput: true`（System spec の `fill_in` 互換）など、テスト容易性も考慮する。

### Importmap

- JS 依存は **Importmap**（`config/importmap.rb`）で管理し、Node / bundler（webpack 等）は使わない。
- pin 例: `@hotwired/turbo-rails`, `@hotwired/stimulus`, `flatpickr`、および `app/javascript/controllers` 配下のコントローラー群。

## ディレクトリ構成

```text
app/
├── views/
│   ├── layouts/            # application.html.erb（共通レイアウト）
│   ├── projects/           # index/show/new/edit/confirm + _form.html.erb
│   ├── tasks/              # index/show/new/edit/confirm + _form.html.erb
│   ├── users/             # new/confirm（登録）
│   └── sessions/          # new（ログイン）
├── helpers/                # ビューヘルパー（ロジックの逃がし先）
└── javascript/
    └── controllers/        # Stimulus コントローラー（flatpickr 等）
config/
└── importmap.rb            # JS 依存の pin 定義
```
