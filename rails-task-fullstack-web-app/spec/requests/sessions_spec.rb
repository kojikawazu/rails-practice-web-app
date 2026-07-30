require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user, password: 'password123') }

  describe "GET /login（ログインフォーム）" do
    it "ログインフォームを表示する" do
      get login_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /login（ログイン）" do
    context "正しい認証情報の場合" do
      it "セッションを確立し、PRG に従ってプロジェクト一覧へリダイレクトする" do
        post login_path, params: { email: user.email, password: 'password123' }
        expect(response).to redirect_to(projects_path)
      end
    end

    context "パスワードが誤っている場合" do
      it "ログイン画面を 422 で再描画する" do
        post login_path, params: { email: user.email, password: 'wrong' }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "存在しないメールアドレスの場合" do
      it "パスワード誤りと同じ 422 を返す（アカウントの存在有無を漏らさない）" do
        post login_path, params: { email: 'nobody@example.com', password: 'password123' }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /logout（ログアウト）" do
    it "セッションを破棄し、ログイン画面へリダイレクトする" do
      post login_path, params: { email: user.email, password: 'password123' }
      delete logout_path
      expect(response).to redirect_to(login_path)
    end
  end
end
