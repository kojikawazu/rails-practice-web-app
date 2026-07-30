require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:valid_params) do
    { user: { name: "山田太郎", email: "taro@example.com",
              password: "password123", password_confirmation: "password123" } }
  end

  describe "GET /signup（登録フォーム）" do
    it "ユーザー登録フォームを表示する" do
      get signup_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /signup/confirm（登録の確認画面）" do
    it "DB には保存せず、valid? の検証だけを行って確認画面を描画する" do
      expect {
        post signup_confirm_path, params: valid_params
      }.not_to change(User, :count)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("入力内容の確認")
      expect(response.body).to include("taro@example.com")
    end

    it "検証に失敗したら確認画面へ進ませず、new を 422 で再描画する" do
      post signup_confirm_path, params: { user: { name: "", email: "", password: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "「修正する」押下時は入力値を保持したままフォームへ戻す" do
      post signup_confirm_path, params: valid_params.merge(back: 1)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("ユーザー登録")
    end
  end

  describe "POST /signup（登録の確定）" do
    it "ユーザーを作成し、そのままログイン状態にしてプロジェクト一覧へリダイレクトする" do
      expect {
        post signup_path, params: valid_params
      }.to change(User, :count).by(1)
      expect(response).to redirect_to(projects_path)
    end

    it "検証に失敗したら作成せず、new を 422 で再描画する" do
      post signup_path, params: { user: { name: "", email: "", password: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
