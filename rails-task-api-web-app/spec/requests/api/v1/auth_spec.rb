require 'rails_helper'

RSpec.describe "Api::V1::Auth", type: :request do
  describe "POST /api/v1/signup（サインアップ）" do
    let(:valid_params) do
      { user: { name: "テストユーザー", email: "new@example.com", password: "password123", password_confirmation: "password123" } }
    end

    it "ユーザーを作成し、201 と JWT を返す（セッションではなくトークンを発行する）" do
      post api_v1_signup_path, params: valid_params, as: :json
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)).to include("token")
    end

    it "検証に失敗したら統一エラー形式で 422 を返す" do
      post api_v1_signup_path, params: { user: { email: "" } }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/login（ログイン）" do
    let!(:user) { create(:user, password: "password123") }

    it "正しい認証情報なら 200 と JWT を返す" do
      post api_v1_login_path, params: { email: user.email, password: "password123" }, as: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include("token")
    end

    it "パスワードが誤っていれば 401 を返し、トークンを発行しない" do
      post api_v1_login_path, params: { email: user.email, password: "wrong" }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
