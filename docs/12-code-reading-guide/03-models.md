# Step 3: モデルを読む（共通）

[← README](README.md)

両プロジェクトのモデルはほぼ同一。一方を読めばもう一方も分かる。

```text
app/models/user.rb      # has_secure_password、バリデーション
app/models/project.rb   # belongs_to :user、has_many :tasks
app/models/task.rb      # belongs_to :project、enum :status
```

## モデルの関連図

```text
User
 └── has_many :projects (dependent: :destroy)
       └── has_many :tasks (dependent: :destroy)
```

読むポイント:

- `has_secure_password` → bcrypt で password_digest を自動管理
- `enum :status, { not_started: 0, in_progress: 1, completed: 2 }, validate: true`
  → `task.not_started?` / `task.in_progress?` のような便利メソッドが自動生成される
- `after_initialize :set_default_status` → 新規レコードのデフォルト値設定パターン

---

前へ: [Step 2: 認証の仕組みを読む](02-auth.md) ｜ 次へ: [Step 4: コントローラーを読む](04-controllers.md)
