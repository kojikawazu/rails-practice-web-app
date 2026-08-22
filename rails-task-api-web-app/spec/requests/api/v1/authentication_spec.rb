require 'rails_helper'

# 認証境界の契約（資格情報の搬送方式）を固定する spec。
# 署名・有効期限の検証そのものは spec/lib/json_web_token_spec.rb と
# spec/scenarios/auth_lifecycle_spec.rb が担い、ここでは
# 「どの形式のヘッダーなら資格情報として受け取るか」だけを検証する。
RSpec.describe "Api::V1 認証（Authorization ヘッダーの契約）", type: :request do
  let(:user) { create(:user) }
  let(:token) { JsonWebToken.encode(user_id: user.id) }

  # 認証必須エンドポイントの代表として、副作用の無い一覧で検証する。
  def get_protected(headers)
    get api_v1_projects_path, headers: headers, as: :json
  end

  it "Bearer スキームの正しいヘッダーは認証を通す" do
    get_protected("Authorization" => "Bearer #{token}")
    expect(response).to have_http_status(:ok)
  end

  it "スキームの大文字小文字は区別しない（RFC 7235: auth-scheme is case-insensitive）" do
    get_protected("Authorization" => "bearer #{token}")
    expect(response).to have_http_status(:ok)
  end

  it "Authorization ヘッダーが無ければ 401 を返す" do
    get_protected({})
    expect(response).to have_http_status(:unauthorized)
  end

  it "スキーム無しの生トークンは、契約外の搬送方式のため 401 を返す" do
    get_protected("Authorization" => token)
    expect(response).to have_http_status(:unauthorized)
  end

  it "Bearer 以外のスキーム（Basic）は、有効な JWT を載せていても 401 を返す" do
    get_protected("Authorization" => "Basic #{token}")
    expect(response).to have_http_status(:unauthorized)
  end

  it "スキームの後ろに要素が並ぶヘッダーは、末尾が有効な JWT でも 401 を返す" do
    get_protected("Authorization" => "Anything ignored #{token}")
    expect(response).to have_http_status(:unauthorized)
  end

  it "Bearer でも要素が多いヘッダーは 401 を返す（token68 は 1 要素だけ）" do
    get_protected("Authorization" => "Bearer #{token} extra")
    expect(response).to have_http_status(:unauthorized)
  end

  it "Bearer の後ろにトークンが無ければ 401 を返す" do
    get_protected("Authorization" => "Bearer")
    expect(response).to have_http_status(:unauthorized)
  end

  it "改ざんされたトークンは Bearer で送られても 401 を返す" do
    get_protected("Authorization" => "Bearer #{token}tampered")
    expect(response).to have_http_status(:unauthorized)
  end

  it "認証失敗のレスポンスは、統一形式（error・単数形）で返す" do
    get_protected({})
    expect(JSON.parse(response.body)).to eq("error" => "Unauthorized")
  end
end
