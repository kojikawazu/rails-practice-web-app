require 'rails_helper'

RSpec.describe "Api::V1::Auth", type: :request do
  describe "POST /api/v1/signup" do
    let(:valid_params) do
      { user: { name: "テストユーザー", email: "new@example.com", password: "password123", password_confirmation: "password123" } }
    end

    it "creates a user and returns token" do
      post api_v1_signup_path, params: valid_params, as: :json
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)).to include("token")
    end

    it "returns errors with invalid params" do
      post api_v1_signup_path, params: { user: { email: "" } }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/login" do
    let!(:user) { create(:user, password: "password123") }

    it "returns token with valid credentials" do
      post api_v1_login_path, params: { email: user.email, password: "password123" }, as: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include("token")
    end

    it "returns unauthorized with wrong password" do
      post api_v1_login_path, params: { email: user.email, password: "wrong" }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
