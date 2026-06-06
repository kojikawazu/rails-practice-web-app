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
      member     { post :confirm; get :duplicate }
    end
  end

  root "projects#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
