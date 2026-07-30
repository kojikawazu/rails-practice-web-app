require 'rails_helper'

RSpec.describe "Api::V1::Projects", type: :request do
  let(:user) { create(:user) }
  let!(:project) { create(:project, user: user) }
  let(:headers) { auth_headers(user) }

  describe "GET /api/v1/projects（一覧）" do
    it "current_user のプロジェクトだけを 200 で返す" do
      get api_v1_projects_path, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).length).to eq(1)
    end

    it "Authorization ヘッダーが無ければ 401 を返す" do
      get api_v1_projects_path, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/projects/:id（詳細）" do
    it "自分のプロジェクトを 200 で返す" do
      get api_v1_project_path(project), headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["id"]).to eq(project.id)
    end

    it "他ユーザーのプロジェクトは、403 ではなく 404 を返して存在自体を秘匿する" do
      other_project = create(:project)
      get api_v1_project_path(other_project), headers: headers, as: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/projects（作成）" do
    it "プロジェクトを作成し、Result の status どおり 201 を返す" do
      expect {
        post api_v1_projects_path, params: { project: { title: "新プロジェクト" } }, headers: headers, as: :json
      }.to change(Project, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it "検証に失敗したら統一エラー形式で 422 を返す" do
      post api_v1_projects_path, params: { project: { title: "" } }, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/projects/:id（更新）" do
    it "プロジェクトを更新し、200 を返す" do
      patch api_v1_project_path(project), params: { project: { title: "更新後" } }, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(project.reload.title).to eq("更新後")
    end
  end

  describe "DELETE /api/v1/projects/:id（削除）" do
    it "プロジェクトを削除し、ボディ無しの 204 を返す" do
      expect {
        delete api_v1_project_path(project), headers: headers, as: :json
      }.to change(Project, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
