require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:valid_params) do
    { user: { name: "山田太郎", email: "taro@example.com",
              password: "password123", password_confirmation: "password123" } }
  end

  describe "GET /signup" do
    it "returns http success" do
      get signup_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /signup/confirm" do
    it "renders confirm without creating a user" do
      expect {
        post signup_confirm_path, params: valid_params
      }.not_to change(User, :count)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("入力内容の確認")
      expect(response.body).to include("taro@example.com")
    end

    it "renders new with 422 on invalid params" do
      post signup_confirm_path, params: { user: { name: "", email: "", password: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns to the form when back is pressed" do
      post signup_confirm_path, params: valid_params.merge(back: 1)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("ユーザー登録")
    end
  end

  describe "POST /signup" do
    it "creates a user, logs in and redirects" do
      expect {
        post signup_path, params: valid_params
      }.to change(User, :count).by(1)
      expect(response).to redirect_to(projects_path)
    end

    it "renders new with 422 on invalid params" do
      post signup_path, params: { user: { name: "", email: "", password: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
