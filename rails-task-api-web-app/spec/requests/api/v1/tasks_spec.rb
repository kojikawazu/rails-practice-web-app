require 'rails_helper'

RSpec.describe "Api::V1::Tasks", type: :request do
  let(:user) { create(:user) }
  let!(:project) { create(:project, user: user) }
  let!(:task) { create(:task, project: project) }
  let(:headers) { auth_headers(user) }

  describe "GET /api/v1/projects/:project_id/tasks（一覧）" do
    it "親プロジェクト配下のタスク一覧を 200 で返す" do
      get api_v1_project_tasks_path(project), headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).length).to eq(1)
    end
  end

  describe "GET /api/v1/projects/:project_id/tasks/:id（詳細）" do
    it "タスク詳細を 200 で返す" do
      get api_v1_project_task_path(project, task), headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["id"]).to eq(task.id)
    end
  end

  describe "POST /api/v1/projects/:project_id/tasks（作成）" do
    it "タスクを作成し、Result の status どおり 201 を返す" do
      expect {
        post api_v1_project_tasks_path(project),
             params: { task: { title: "新タスク", status: "not_started" } },
             headers: headers, as: :json
      }.to change(Task, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it "検証に失敗したら統一エラー形式で 422 を返す" do
      post api_v1_project_tasks_path(project), params: { task: { title: "" } }, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/projects/:project_id/tasks/:id（更新）" do
    it "enum の status を更新し、200 を返す" do
      patch api_v1_project_task_path(project, task),
            params: { task: { status: "in_progress" } },
            headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(task.reload.status).to eq("in_progress")
    end
  end

  describe "PATCH /api/v1/projects/:project_id/tasks/:id（ステータス遷移）" do
    it "進行中 → 完了 は 200 で更新する" do
      doing = create(:task, :in_progress, project: project)
      patch api_v1_project_task_path(project, doing),
            params: { task: { status: "completed" } },
            headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(doing.reload.status).to eq("completed")
    end

    it "進行中 → 未着手 は 422 を返す（差し戻しは完了からのみ）" do
      doing = create(:task, :in_progress, project: project)
      patch api_v1_project_task_path(project, doing),
            params: { task: { status: "not_started" } },
            headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(doing.reload.status).to eq("in_progress")
    end

    it "完了 → 進行中 の差し戻しは 200 で更新する" do
      done = create(:task, :completed, project: project)
      patch api_v1_project_task_path(project, done),
            params: { task: { status: "in_progress" } },
            headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(done.reload.status).to eq("in_progress")
    end

    it "未着手 → 完了 は途中を飛ばすため 422 と errors を返し、値も変えない" do
      patch api_v1_project_task_path(project, task),
            params: { task: { status: "completed" } },
            headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to be_present
      expect(task.reload.status).to eq("not_started")
    end

    it "完了 → 未着手 も 422 を返す（差し戻し先は進行中だけ）" do
      done = create(:task, :completed, project: project)
      patch api_v1_project_task_path(project, done),
            params: { task: { status: "not_started" } },
            headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(done.reload.status).to eq("completed")
    end
  end

  describe "POST /api/v1/projects/:project_id/tasks（作成時のステータス）" do
    it "status を省略した作成は、未着手のタスクになる" do
      post api_v1_project_tasks_path(project),
           params: { task: { title: "既定ステータス確認" } },
           headers: headers, as: :json
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["status"]).to eq("not_started")
    end

    it "completed を指定した作成は 422 を返し、レコードも作らない" do
      expect {
        post api_v1_project_tasks_path(project),
             params: { task: { title: "完了で作成", status: "completed" } },
             headers: headers, as: :json
      }.not_to change(Task, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /api/v1/projects/:project_id/tasks/:id（削除）" do
    it "タスクを削除し、ボディ無しの 204 を返す" do
      expect {
        delete api_v1_project_task_path(project, task), headers: headers, as: :json
      }.to change(Task, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
