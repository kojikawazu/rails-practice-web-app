# Step 5: テストを読む

[← README](README.md)

テストはコードの「仕様書」として読める。実装を読む前にテストを読むと意図が分かりやすい。

**フルスタック版（Minitest + RSpec 併用）**

| ファイル | 内容 |
|---|---|
| `test/controllers/projects_controller_test.rb` | Minitestでのコントローラーテスト |
| `spec/models/user_spec.rb` | shoulda-matchers でバリデーション検証 |
| `spec/requests/projects_spec.rb` | RSpec リクエストスペック |

**APIモード（RSpec のみ）**

| ファイル | 内容 |
|---|---|
| `spec/requests/api/v1/auth_spec.rb` | signup/login のトークン返却確認 |
| `spec/requests/api/v1/projects_spec.rb` | JWT付きリクエストのCRUD確認 |
| `spec/support/jwt_helper.rb` | `auth_headers(user)` ヘルパー（テスト用トークン生成） |

読むポイント:
- `auth_headers(user)` の実装を見ると JWT の使い方が分かる
- `as: :json` — リクエストボディを JSON として送信
- `JSON.parse(response.body)` — レスポンスの JSON を検証

---

前へ: [Step 4: コントローラーを読む](04-controllers.md)
