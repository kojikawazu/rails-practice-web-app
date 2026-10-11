require 'rails_helper'

# レートリミット（Rails 8 標準の rate_limit）。カウンタは同一 IP（request spec では 127.0.0.1）単位で、
# test 環境は memory_store に保存し例ごとにクリアする（spec/support/rate_limit.rb）。
# 上限値は config.x.rate_limit から読む（test 環境では config/environments/test.rb で小さくしている）。
RSpec.describe "Api::V1 レートリミット", type: :request do
  let(:auth_limit) { Rails.configuration.x.rate_limit.auth_limit }
  let(:api_limit) { Rails.configuration.x.rate_limit.api_limit }
  let!(:user) { create(:user, password: "password123") }

  def wrong_login
    post api_v1_login_path, params: { email: user.email, password: "wrong" }, as: :json
  end

  describe "認証系（login / signup）" do
    it "上限回数までは通常どおり応答する（誤ったパスワードは 401 のまま）" do
      auth_limit.times { wrong_login }
      expect(response).to have_http_status(:unauthorized)
    end

    it "上限を超えた login は統一エラー形式の 429 と Retry-After を返す（総当たり攻撃の抑止）" do
      auth_limit.times { wrong_login }
      wrong_login

      expect(response).to have_http_status(:too_many_requests)
      expect(response.parsed_body).to eq("error" => { "code" => "rate_limited", "message" => "Too many requests" })
      expect(response.headers["Retry-After"]).to eq(Rails.configuration.x.rate_limit.auth_period.to_i.to_s)
    end

    it "上限に達すると正しい認証情報でもトークンを発行しない" do
      auth_limit.times { wrong_login }
      post api_v1_login_path, params: { email: user.email, password: "password123" }, as: :json

      expect(response).to have_http_status(:too_many_requests)
      expect(response.parsed_body).not_to include("token")
    end

    it "上限を超えた signup も 429 を返す（アカウントの大量作成の抑止）" do
      (auth_limit + 1).times { post api_v1_signup_path, params: { user: { email: "" } }, as: :json }

      expect(response).to have_http_status(:too_many_requests)
      expect(response.parsed_body).to eq("error" => { "code" => "rate_limited", "message" => "Too many requests" })
    end

    it "login と signup はカウンタを分ける（登録を繰り返しても、ログインの上限は消費しない）" do
      auth_limit.times { post api_v1_signup_path, params: { user: { email: "" } }, as: :json }
      wrong_login

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "API 全体" do
    it "認証済みでも、上限を超えたリクエストは 429 と Retry-After を返す" do
      headers = auth_headers(user)
      api_limit.times { get api_v1_projects_path, headers: headers }
      expect(response).to have_http_status(:ok)

      get api_v1_projects_path, headers: headers
      expect(response).to have_http_status(:too_many_requests)
      expect(response.parsed_body).to eq("error" => { "code" => "rate_limited", "message" => "Too many requests" })
      expect(response.headers["Retry-After"]).to eq(Rails.configuration.x.rate_limit.api_period.to_i.to_s)
    end

    it "カウンタはコントローラーをまたいで共有する（エンドポイントを切り替えて上限を回避できない）" do
      headers = auth_headers(user)
      project = create(:project, user: user)
      api_limit.times { get api_v1_projects_path, headers: headers }

      get api_v1_project_tasks_path(project), headers: headers
      expect(response).to have_http_status(:too_many_requests)
    end
  end
end
