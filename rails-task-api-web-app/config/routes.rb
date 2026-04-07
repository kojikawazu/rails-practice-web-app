Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "signup", to: "auth#signup"
      post "login",  to: "auth#login"

      resources :projects do
        resources :tasks
      end
    end
  end
end
