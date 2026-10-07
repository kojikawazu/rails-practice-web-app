require "rails_helper"

# 認証系（ログイン・ユーザー登録）のレートリミット（Rails 8 標準の rate_limit）。
# カウンタは同一 IP（request spec では 127.0.0.1）単位で、test 環境は memory_store に保存し
# 例ごとにクリアする（spec/support/rate_limit.rb）。上限は config/environments/test.rb で小さくしている。
RSpec.describe "認証系のレートリミット", type: :request do
  let(:auth_limit) { Rails.configuration.x.rate_limit.auth_limit }
  let!(:user) { create(:user) }
  let(:limited_message) { "試行回数が多すぎます。しばらく待ってから再度お試しください。" }

  def wrong_login
    post login_path, params: { email: user.email, password: "wrong" }
  end

  def signup_confirm
    post signup_confirm_path, params: { user: { name: "新規", email: "new@example.com",
                                                password: "password123", password_confirmation: "password123" } }
  end

  describe "POST /login" do
    it "上限回数までは通常どおり 422 でログイン画面を再描画する" do
      auth_limit.times { wrong_login }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "上限を超えると 429 でログイン画面にメッセージを表示し、Retry-After を返す（総当たり攻撃の抑止）" do
      (auth_limit + 1).times { wrong_login }

      expect(response).to have_http_status(:too_many_requests)
      page = Capybara.string(response.body)
      expect(page).to have_css(".flash-alert", text: limited_message)
      expect(page).to have_field("email")
      expect(response.headers["Retry-After"]).to eq(Rails.configuration.x.rate_limit.auth_period.to_i.to_s)
    end

    it "上限に達すると正しい認証情報でもログインさせない" do
      auth_limit.times { wrong_login }
      post login_path, params: { email: user.email, password: "password123" }

      expect(response).to have_http_status(:too_many_requests)
      expect(session[:user_id]).to be_nil
    end
  end

  describe "ユーザー登録（POST /signup/confirm・POST /signup）" do
    it "上限を超えると 429 で登録フォームにメッセージを表示する" do
      (auth_limit + 1).times { signup_confirm }

      expect(response).to have_http_status(:too_many_requests)
      page = Capybara.string(response.body)
      expect(page).to have_css(".flash-alert", text: limited_message)
      expect(page).to have_field("user[email]")
    end

    it "確認と確定は同じカウンタを共有し、上限到達後はアカウントを作らない" do
      auth_limit.times { signup_confirm }

      expect {
        post signup_path, params: { user: { name: "新規", email: "new@example.com",
                                            password: "password123", password_confirmation: "password123" } }
      }.not_to change(User, :count)
      expect(response).to have_http_status(:too_many_requests)
    end

    it "ログインとはカウンタを分ける（登録を繰り返しても、ログインの上限は消費しない）" do
      auth_limit.times { signup_confirm }
      wrong_login

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
