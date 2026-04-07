require 'rails_helper'

RSpec.describe "Api::V1::Tasks", type: :request do
  let(:user) { create(:user) }
  let!(:project) { create(:project, user: user) }
  let!(:task) { create(:task, project: project) }
  let(:headers) { auth_headers(user) }

  describe "GET /api/v1/projects/:project_id/tasks" do
    it "returns tasks" do
      get api_v1_project_tasks_path(project), headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).length).to eq(1)
    end
  end

  describe "GET /api/v1/projects/:project_id/tasks/:id" do
    it "returns the task" do
      get api_v1_project_task_path(project, task), headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["id"]).to eq(task.id)
    end
  end

  describe "POST /api/v1/projects/:project_id/tasks" do
    it "creates a task" do
      expect {
        post api_v1_project_tasks_path(project),
             params: { task: { title: "新タスク", status: "not_started" } },
             headers: headers, as: :json
      }.to change(Task, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it "returns errors on invalid params" do
      post api_v1_project_tasks_path(project), params: { task: { title: "" } }, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/projects/:project_id/tasks/:id" do
    it "updates the task" do
      patch api_v1_project_task_path(project, task),
            params: { task: { status: "in_progress" } },
            headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(task.reload.status).to eq("in_progress")
    end
  end

  describe "DELETE /api/v1/projects/:project_id/tasks/:id" do
    it "destroys the task" do
      expect {
        delete api_v1_project_task_path(project, task), headers: headers, as: :json
      }.to change(Task, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
