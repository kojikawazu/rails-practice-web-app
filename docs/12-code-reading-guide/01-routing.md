# Step 1: ルーティングから全体像を把握する

[← README](README.md)

まずどのURLがどのコントローラーに繋がっているかを確認する。

**フルスタック版**
```
rails-task-fullstack-web-app/config/routes.rb
```
```ruby
resources :projects do
  resources :tasks      # ネスト: /projects/:project_id/tasks
end
get "login"  → SessionsController#new
post "login" → SessionsController#create
```

**APIモード**
```
rails-task-api-web-app/config/routes.rb
```
```ruby
namespace :api do
  namespace :v1 do
    post "login"  → Api::V1::AuthController#login
    resources :projects do
      resources :tasks
    end
  end
end
```

> **差分ポイント**: APIモードは `namespace :api do namespace :v1` で全エンドポイントをバージョン管理している。

---

次へ: [Step 2: 認証の仕組みを読む](02-auth.md)
