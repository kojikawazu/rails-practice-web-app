---
description: Ruby / Bundler / RuboCop コーディング規約・YARD ドキュメントコメント
globs: 
---

# コーディング規約

- **言語**: Ruby（Rails の規約に従う）
- **パッケージマネージャ**: Bundler を使用（gem のインストールは `bundle install`）
- **Linter / Formatter**: RuboCop でコード品質を担保
- **環境変数**: 設定値は環境変数で管理（.env）
- **シークレット禁止**: シークレット・認証情報をハードコードしない

## ドキュメントコメント（YARD）

`app/` 配下のコードには **YARD 形式**のドキュメントコメントを付与する。コメントの言語は日本語（コードベースに合わせる）。

### 付与対象

| 対象 | 方針 |
|------|------|
| クラス / モジュール | **必須**。責務を 1 行で要約し、非自明な設計理由があれば続けて記述する |
| public メソッド | **必須**。`@param` / `@return` / 例外を投げるなら `@raise` を付ける |
| private の補助メソッド | 非自明なものに付ける（Strong Parameters や単純な getter など自明なものは 1 行の説明で可） |
| 空ヘルパー・Rails 生成スタブ（`ApplicationRecord` 等） | 1 行の責務コメントに留める（過剰に書かない） |

> **原則**: 網羅より情報密度。自明な CRUD に定型コメントを量産せず、「なぜそう書いたか（非自明な判断）」を厚く書く。

### Rails の学習上重要な境界

Rails の規約やヘルパーが処理を隠す箇所では、**何をするか**だけでなく、**なぜその機構・責務分離を選ぶか**をコメントに残す。目的はフレームワークの動きを理解できる状態を保つことであり、全コードへの定型コメント追加ではない。

| 境界 | コメントに残す判断 |
|------|------------------|
| Turbo / PRG / session | Turbo を有効・無効にする理由、POST 後に redirect を選ぶ理由、入力値を session に退避する範囲と制約 |
| 認証・認可 | セッションと JWT の使い分け、外部入力の入口と `current_user` 起点の association scope で認可を保証する理由、再利用する Service の認可前提 |
| Active Storage | `signed_id` を使う round-trip、blob の staging / attach / purge を分ける理由、オーファン防止と添付利用権の境界 |
| Service / Controller / 例外 | HTTP 応答・表示判断を残す層、ビジネスロジックを委譲する層、`rescue_from` に集約する例外の理由 |

- Rails の自明な CRUD や規約どおりの記述には、説明だけの定型コメントを増やさない。
- 方式を変えたときは、既存コメントが新しい境界・理由と矛盾しないよう同じ変更で更新する。
- `signed_id` は推測不能な ID ではなく添付を許す capability として扱う。受領時は、現在の利用者・対象レコードで利用できる staging 状態かを検証し、検証できない blob を attach / purge しない。
- 認証・認可は外部入力の入口で行い、データ取得は `current_user` 起点の association scope を基本とする。Service を再利用する場合は、呼び出し前提と単独呼び出しで越権しない保証箇所をコメントに残す。

### タグの書き方

- 型は名前の**後ろ**に角括弧で書く: `@param name [String] 説明` / `@return [Array<Task>] 説明`
- 真偽値は `[Boolean]`、nil を返しうる場合は `[String, nil]` のように併記する
- **render / redirect で値を返す Rails アクション**は `@return [void]` とし、説明に「何を・どの HTTP ステータスで返すか」を書く（例: `@return [void] 成功: 詳細へリダイレクト／失敗: edit を 422 で再描画`）
- **ActiveRecord のカラム**は `def` が無くパースできないため、クラスコメントで `@!attribute [rw] title` + `@return [String] 説明` を用いて型・制約を宣言する

### 例

```ruby
# タスクを作成する。確認画面から持ち回った画像を添付して保存する。
#
# @return [void] 成功: プロジェクト詳細へリダイレクト／失敗: new を 422 で再描画
def create
  # ...
end

# 形式・サイズの事前検証（モデルの images_format_and_size と同基準）。
#
# @param file [ActionDispatch::Http::UploadedFile] 検証対象のアップロードファイル
# @return [Boolean] 許可形式かつ上限サイズ以内なら true
def valid_image_upload?(file)
  # ...
end
```

> YARD コメントは通常の `#` コメントとして扱われるため RuboCop と衝突しない。`yard` gem の導入・HTML 生成は任意（必要になった時点で `Gemfile` に追加する）。
