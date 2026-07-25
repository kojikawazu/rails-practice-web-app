---
description: コーディング規約
globs: 
---

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
