require 'rails_helper'

RSpec.describe "Api::V1::Projects", type: :request do
  let(:user) { create(:user) }
  let!(:project) { create(:project, user: user) }
  let(:headers) { auth_headers(user) }

  describe "GET /api/v1/projects" do
    it "returns projects" do
      get api_v1_projects_path, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).length).to eq(1)
    end

    it "returns unauthorized without token" do
      get api_v1_projects_path, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/projects/:id" do
    it "returns the project" do
      get api_v1_project_path(project), headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["id"]).to eq(project.id)
    end

    it "returns not found for another user's project" do
      other_project = create(:project)
      get api_v1_project_path(other_project), headers: headers, as: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/projects" do
    it "creates a project" do
      expect {
        post api_v1_projects_path, params: { project: { title: "新プロジェクト" } }, headers: headers, as: :json
      }.to change(Project, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it "returns errors on invalid params" do
      post api_v1_projects_path, params: { project: { title: "" } }, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/projects/:id" do
    it "updates the project" do
      patch api_v1_project_path(project), params: { project: { title: "更新後" } }, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(project.reload.title).to eq("更新後")
    end
  end

  describe "DELETE /api/v1/projects/:id" do
    it "destroys the project" do
      expect {
        delete api_v1_project_path(project), headers: headers, as: :json
      }.to change(Project, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
