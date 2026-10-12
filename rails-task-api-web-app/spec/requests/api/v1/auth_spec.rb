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
      # password_digest などの内部カラムを返さない
      expect(JSON.parse(response.body)["user"].keys).to contain_exactly(*%w[id name email])
    end

    it "検証に失敗したら統一エラー形式で 422 を返す" do
      post api_v1_signup_path, params: { user: { email: "" } }, as: :json
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST /api/v1/login（ログイン）" do
    let!(:user) { create(:user, password: "password123") }

    it "正しい認証情報なら 200 と JWT を返す" do
      post api_v1_login_path, params: { email: user.email, password: "password123" }, as: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include("token")
      expect(JSON.parse(response.body)["user"].keys).to contain_exactly(*%w[id name email])
    end

    it "パスワードが誤っていれば 401 を返し、トークンを発行しない" do
      post api_v1_login_path, params: { email: user.email, password: "wrong" }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/logout（ログアウト）" do
    let(:user) { create(:user) }
    let(:token) { JsonWebToken.encode(user_id: user.id) }
    let(:claims) { JsonWebToken.decode(token) }

    it "204 を返し、トークンの jti を有効期限つきで失効テーブルに記録する" do
      delete api_v1_logout_path, headers: bearer(token), as: :json

      expect(response).to have_http_status(:no_content)
      expect(response.body).to be_empty
      revoked = RevokedToken.find_by!(jti: claims[:jti])
      expect(revoked.expires_at.to_i).to eq(claims[:exp])
    end

    it "ログアウトしたトークンは、以降の保護エンドポイントで 401 になる" do
      delete api_v1_logout_path, headers: bearer(token), as: :json
      get api_v1_projects_path, headers: bearer(token), as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq("error" => { "code" => "unauthorized", "message" => "Unauthorized" })
    end

    it "同じユーザーの別のトークン（別の端末）は、ログアウトしても有効のまま" do
      other_device = JsonWebToken.encode(user_id: user.id)

      delete api_v1_logout_path, headers: bearer(token), as: :json
      get api_v1_projects_path, headers: bearer(other_device), as: :json

      expect(response).to have_http_status(:ok)
    end

    it "失効済みのトークンで再びログアウトすると、ほかの無効なトークンと区別せず 401 を返す" do
      delete api_v1_logout_path, headers: bearer(token), as: :json
      delete api_v1_logout_path, headers: bearer(token), as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(RevokedToken.where(jti: claims[:jti]).count).to eq(1)
    end

    it "トークンが無ければ 401 を返し、失効テーブルに何も記録しない" do
      expect {
        delete api_v1_logout_path, as: :json
      }.not_to change(RevokedToken, :count)

      expect(response).to have_http_status(:unauthorized)
    end

    it "ログアウトのたびに有効期限を過ぎた失効記録を消し、期限内の記録は残す（テーブルが増え続けないようにする）" do
      expired = create(:revoked_token, :expired)
      active = create(:revoked_token)

      delete api_v1_logout_path, headers: bearer(token), as: :json

      expect(RevokedToken.exists?(expired.id)).to be(false)
      expect(RevokedToken.exists?(active.id)).to be(true)
    end
  end
end
