require 'rails_helper'

# API のエラーレスポンスの契約（#147）。どのエラーも { error: { code, message, details? } } の 1 形態で返す。
# クライアントは code で分岐し、message は人に見せるだけにする。details はバリデーション（422）のときだけ付き、
# それ以外ではキーごと無い（null を返さない）。カラム追加時の露出検査と同じく、キー集合まで完全一致で固定する。
# 429 の形は、上限まで叩く準備が要るため spec/requests/api/v1/rate_limit_spec.rb で固定する。
RSpec.describe "Api::V1 エラーレスポンスの契約", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:headers) { auth_headers(user) }

  describe "アプリが返すエラー（全環境で同じ形）" do
    # API モードの ParamsWrapper は、JSON のトップレベルにあるモデルの属性（title など）を自動で
    # project キーに包む。属性名を送ると欠落にならないため、モデルに無いキーだけを送る。
    it "400: 必須パラメータが無ければ bad_request を返す" do
      post api_v1_projects_path, params: { unknown: "x" }, headers: headers, as: :json

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to eq("error" => { "code" => "bad_request", "message" => "Bad request" })
    end

    # パーサの例外メッセージには送られた本文の断片が入るため、応答に反射させない。
    it "400: 壊れた JSON も bad_request を返し、送られた本文を応答に含めない" do
      post api_v1_projects_path, params: '{"project": {"title": "<script>',
                                 headers: headers.merge("CONTENT_TYPE" => "application/json")

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to eq("error" => { "code" => "bad_request", "message" => "Bad request" })
      expect(response.body).not_to include("<script>")
    end

    it "401: トークンが無ければ unauthorized を返す" do
      get api_v1_projects_path, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq("error" => { "code" => "unauthorized", "message" => "Unauthorized" })
    end

    # メール不在とパスワード誤りを区別しない（列挙攻撃対策）。code も message も同じになる。
    it "401: ログイン失敗は invalid_credentials を返し、メール不在とパスワード誤りを区別しない" do
      expected = {
        "error" => { "code" => "invalid_credentials", "message" => "メールアドレスまたはパスワードが正しくありません。" }
      }

      post api_v1_login_path, params: { email: user.email, password: "wrong" }, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq(expected)

      post api_v1_login_path, params: { email: "missing@example.com", password: "wrong" }, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq(expected)
    end

    it "404: 他ユーザーのプロジェクトは not_found を返し、メッセージにモデル名が入る" do
      get api_v1_project_path(create(:project)), headers: headers, as: :json

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq("error" => { "code" => "not_found", "message" => "Project not found" })
    end

    it "404: 存在しないタスクも not_found を返す" do
      project = create(:project, user: user)
      get api_v1_project_task_path(project, 0), headers: headers, as: :json

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq("error" => { "code" => "not_found", "message" => "Task not found" })
    end

    it "422: 検証失敗は validation_failed を返し、details に内訳を入れる" do
      post api_v1_projects_path, params: { project: { title: "" } }, headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq(
        "error" => {
          "code" => "validation_failed",
          "message" => "入力内容に誤りがあります",
          "details" => [ "Title can't be blank" ]
        }
      )
    end

    it "422: 登録の検証失敗も同じ形で返す" do
      post api_v1_signup_path, params: { user: { email: "" } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"].keys).to contain_exactly("code", "message", "details")
      expect(response.parsed_body["error"]["code"]).to eq("validation_failed")
      expect(response.parsed_body["error"]["details"]).to include("Email can't be blank")
    end
  end

  describe "Rails が返すエラー（本番相当: 詳細表示オフ）" do
    # test 環境の既定では、consider_all_requests_local = true のためデバッグ用の詳細表示になり、
    # show_exceptions = :rescuable のため想定外の例外は描画されずテストへ raise される。
    # ルーターの 404 と想定外の 500 は exceptions_app が本番だけで整形するため、この describe の間だけ
    # 両方を本番と同じにして、本番の応答を再現する。
    around do |example|
      env_config = Rails.application.env_config
      overrides = { "action_dispatch.show_detailed_exceptions" => false, "action_dispatch.show_exceptions" => :all }
      original = overrides.keys.index_with { |key| env_config[key] }
      env_config.merge!(overrides)
      example.run
    ensure
      env_config.merge!(original)
    end

    it "404: 存在しないルートも JSON の not_found を返す（空の HTML にしない）" do
      get "/api/v1/unknown", headers: headers

      expect(response).to have_http_status(:not_found)
      expect(response.media_type).to eq("application/json")
      expect(response.parsed_body).to eq("error" => { "code" => "not_found", "message" => "Not found" })
    end

    it "500: 想定外の例外は internal_error を返し、例外の内容を出さない" do
      allow(ProjectService).to receive(:list).and_raise(RuntimeError, "secret internal detail")

      get api_v1_projects_path, headers: headers

      expect(response).to have_http_status(:internal_server_error)
      expect(response.media_type).to eq("application/json")
      expect(response.parsed_body).to eq("error" => { "code" => "internal_error", "message" => "Internal server error" })
      expect(response.body).not_to include("secret internal detail")
    end
  end
end
