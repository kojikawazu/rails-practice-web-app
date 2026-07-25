# Step 4: コントローラーを読む

[← README](README.md)

## フルスタック版

```text
app/controllers/projects_controller.rb
app/controllers/tasks_controller.rb
```

読むポイント:

- `before_action :require_login` — 認証ガード
- `current_user.projects.find(params[:id])` — スコープ付き検索（他ユーザーのデータにアクセスできない）
- `respond_to do |format|` — HTML/JSON の両レスポンス対応

## APIモード

```text
app/controllers/api/v1/projects_controller.rb
app/controllers/api/v1/tasks_controller.rb
```

読むポイント:

- `render json: @project` — シンプルなJSON返却
- `head :no_content` — DELETE時に204を返す（ボディなし）
- `rescue ActiveRecord::RecordNotFound` → 404 JSON を返す

> **差分ポイント**: フルスタック版は `redirect_to` でページ遷移するが、APIモードは `render json:` のみ。エラーも `render json: { error: "..." }, status: :not_found` で返す。

---

前へ: [Step 3: モデルを読む（共通）](03-models.md) ｜ 次へ: [Step 5: テストを読む](05-tests.md)
