require 'rails_helper'

RSpec.describe "Tasks", type: :request do
  let(:user) { create(:user) }
  let!(:project) { create(:project, user: user) }
  let!(:task) { create(:task, project: project) }

  def log_in
    post login_path, params: { email: user.email, password: 'password123' }
  end

  describe "GET /projects/:project_id/tasks/new" do
    it "returns http success" do
      log_in
      get new_project_task_path(project)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /projects/:project_id/tasks/:id" do
    it "returns http success" do
      log_in
      get project_task_path(project, task)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /projects/:project_id/tasks" do
    it "creates a task and redirects to project" do
      log_in
      expect {
        post project_tasks_path(project), params: {
          task: { title: "新タスク", status: "not_started", due_date: Date.tomorrow }
        }
      }.to change(Task, :count).by(1)
      expect(response).to redirect_to(project_path(project))
    end

    it "renders new on invalid params" do
      log_in
      post project_tasks_path(project), params: { task: { title: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /projects/:project_id/tasks/:id" do
    it "updates and redirects to task" do
      log_in
      patch project_task_path(project, task), params: {
        task: { title: "更新タスク", status: "in_progress" }
      }
      expect(response).to redirect_to(project_task_path(project, task))
      expect(task.reload.title).to eq("更新タスク")
    end
  end

  describe "DELETE /projects/:project_id/tasks/:id" do
    it "destroys and redirects to project" do
      log_in
      expect {
        delete project_task_path(project, task)
      }.to change(Task, :count).by(-1)
      expect(response).to redirect_to(project_path(project))
    end
  end
end
