require 'rails_helper'

RSpec.describe "Projects", type: :request do
  let(:user) { create(:user) }
  let!(:project) { create(:project, user: user) }

  def log_in
    post login_path, params: { email: user.email, password: 'password123' }
  end

  describe "GET /projects" do
    context "when logged in" do
      it "returns http success" do
        log_in
        get projects_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        get projects_path
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "GET /projects/:id" do
    it "returns http success" do
      log_in
      get project_path(project)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /projects" do
    it "creates a project and redirects" do
      log_in
      expect {
        post projects_path, params: { project: { title: "新プロジェクト", description: "説明" } }
      }.to change(Project, :count).by(1)
      expect(response).to redirect_to(project_path(Project.last))
    end

    it "renders new on invalid params" do
      log_in
      post projects_path, params: { project: { title: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /projects/:id" do
    it "updates and redirects" do
      log_in
      patch project_path(project), params: { project: { title: "更新後タイトル" } }
      expect(response).to redirect_to(project_path(project))
      expect(project.reload.title).to eq("更新後タイトル")
    end
  end

  describe "DELETE /projects/:id" do
    it "destroys and redirects" do
      log_in
      expect {
        delete project_path(project)
      }.to change(Project, :count).by(-1)
      expect(response).to redirect_to(projects_path)
    end
  end
end
