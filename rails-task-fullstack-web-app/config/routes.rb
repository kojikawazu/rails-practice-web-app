Rails.application.routes.draw do
  get    "signup",         to: "users#new"
  post   "signup/confirm", to: "users#confirm", as: :signup_confirm
  post   "signup",         to: "users#create"
  get    "login",  to: "sessions#new"
  post   "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  resources :projects do
    collection { post :confirm }
    member     { post :confirm; get :duplicate }
    resources :tasks do
      collection { post :confirm }
      member do
        post :confirm
        get :duplicate
        # 画像の追加は新規/編集フォーム（confirm→create/update）に集約。
        # 詳細画面からの個別削除のみ専用ルートを残す。
        delete "images/:image_id", action: :detach_image, as: :detach_image
      end
    end
  end

  root "projects#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
