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

  describe "POST /projects/:project_id/tasks/confirm" do
    it "renders confirm without creating a task" do
      log_in
      expect {
        post confirm_project_tasks_path(project), params: {
          task: { title: "確認用タスク", status: "not_started", due_date: Date.tomorrow }
        }
      }.not_to change(Task, :count)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("入力内容の確認")
    end

    it "renders new with 422 on invalid params" do
      log_in
      post confirm_project_tasks_path(project), params: { task: { title: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns to the form when back is pressed" do
      log_in
      post confirm_project_tasks_path(project), params: {
        task: { title: "確認用タスク", status: "not_started" }, back: 1
      }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("確認する")
    end
  end

  describe "POST /projects/:project_id/tasks/:id/confirm" do
    it "renders confirm without updating the task" do
      log_in
      post confirm_project_task_path(project, task), params: { task: { title: "編集確認タスク" } }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("入力内容の確認")
      expect(task.reload.title).not_to eq("編集確認タスク")
    end

    it "renders edit with 422 on invalid params" do
      log_in
      post confirm_project_task_path(project, task), params: { task: { title: "" } }
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
