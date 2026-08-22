Rails.application.routes.draw do
  get    "signup",         to: "users#new"
  post   "signup/confirm", to: "users#confirm", as: :signup_confirm
  post   "signup",         to: "users#create"
  get    "login",  to: "sessions#new"
  post   "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  resources :projects do
    # 新規作成の確認画面は (b案2) リダイレクト方式。POST(検証→session 退避→303) と
    # GET(session から確認画面を描画／無ければ new へ) の両方を受ける。
    collection { match :confirm, via: %i[get post] }
    member     { post :confirm; get :duplicate }
    resources :tasks do
      # 確認画面は POST 専用だが、リロード/戻る操作で GET される場合があるため GET も受け、
      # アクション側でフォームへリダイレクトする（show ルートに誤って落ちるのを防ぐ）。
      collection { match :confirm, via: %i[get post] }
      member do
        match :confirm, via: %i[get post]
        get :duplicate
        # 画像の追加は新規/編集フォーム（confirm→create/update）に集約。
        # 詳細画面からの個別削除のみ専用ルートを残す。
        # :attachment_id は ActiveStorage::Attachment の id（blob の id ではない）。
        delete "images/:attachment_id", action: :detach_image, as: :detach_image
      end
    end
  end

  root "projects#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
