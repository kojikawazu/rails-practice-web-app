require "rails_helper"

# E2E/シナリオ（実DB）: 認証と JWT のライフサイクルを実ミドルウェア込みで検証する。
# JWT の期限切れ・改ざん拒否（UT で固定した性質）が、実際の認証フローでも 401 になることを確認する。
RSpec.describe "Auth lifecycle", type: :request do
  let!(:user) { create(:user, email: "user@example.com", password: "password123") }

  it "signup で得た token が保護エンドポイントで即利用できる" do
    post api_v1_signup_path,
         params: { user: { name: "新規", email: "new@example.com",
                           password: "password123", password_confirmation: "password123" } },
         as: :json
    token = json["token"]

    get api_v1_projects_path, headers: bearer(token), as: :json
    expect(response).to have_http_status(:ok)
  end

  it "login で token が得られ、誤パスワードは 401 になる" do
    post api_v1_login_path, params: { email: "user@example.com", password: "password123" }, as: :json
    expect(response).to have_http_status(:ok)
    expect(json["token"]).to be_present

    post api_v1_login_path, params: { email: "user@example.com", password: "wrong" }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it "期限切れトークンは保護エンドポイントで 401 になる" do
    expired = JsonWebToken.encode({ user_id: user.id }, 1.hour.ago)
    get api_v1_projects_path, headers: bearer(expired), as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it "改ざんされたトークンは保護エンドポイントで 401 になる" do
    header, payload, = JsonWebToken.encode(user_id: user.id).split(".")
    tampered = [ header, payload, "invalid-signature" ].join(".")
    get api_v1_projects_path, headers: bearer(tampered), as: :json
    expect(response).to have_http_status(:unauthorized)
  end
end
