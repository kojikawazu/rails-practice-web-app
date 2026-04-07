require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user, password: 'password123') }

  describe "GET /login" do
    it "returns http success" do
      get login_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /login" do
    context "with valid credentials" do
      it "redirects to projects" do
        post login_path, params: { email: user.email, password: 'password123' }
        expect(response).to redirect_to(projects_path)
      end
    end

    context "with invalid password" do
      it "returns unprocessable entity" do
        post login_path, params: { email: user.email, password: 'wrong' }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with unknown email" do
      it "returns unprocessable entity" do
        post login_path, params: { email: 'nobody@example.com', password: 'password123' }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /logout" do
    it "redirects to login" do
      post login_path, params: { email: user.email, password: 'password123' }
      delete logout_path
      expect(response).to redirect_to(login_path)
    end
  end
end
