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
          task: { title: "新タスク", status: "not_started", start_date: Date.tomorrow, end_date: Date.tomorrow + 3 }
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
          task: { title: "確認用タスク", status: "not_started", start_date: Date.tomorrow, end_date: Date.tomorrow + 3 }
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

  describe "GET /projects/:project_id/tasks/:id/duplicate" do
    let!(:task) { create(:task, project: project, title: "元タスク", status: :in_progress) }

    it "renders the new form prefilled from the source without creating a record" do
      log_in
      expect {
        get duplicate_project_task_path(project, task)
      }.not_to change(Task, :count)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("元タスクのコピー")
      expect(response.body).to include("確認する")
    end

    it "submits to the create flow (collection confirm), not update" do
      log_in
      get duplicate_project_task_path(project, task)
      expect(response.body).to include(confirm_project_tasks_path(project))
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

  describe "他ユーザーのタスクへのアクセス（認可）" do
    let(:other_project) { create(:project, user: create(:user)) }
    let!(:other_task) { create(:task, project: other_project) }

    before { log_in }

    it "returns 404 on show (project not in scope)" do
      get project_task_path(other_project, other_task)
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 on edit" do
      get edit_project_task_path(other_project, other_task)
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 on update" do
      patch project_task_path(other_project, other_task), params: { task: { title: "乗っ取り" } }
      expect(response).to have_http_status(:not_found)
      expect(other_task.reload.title).not_to eq("乗っ取り")
    end

    it "returns 404 on destroy" do
      delete project_task_path(other_project, other_task)
      expect(response).to have_http_status(:not_found)
      expect(Task.exists?(other_task.id)).to be(true)
    end

    it "returns 404 when creating a task under another user's project" do
      expect {
        post project_tasks_path(other_project), params: { task: { title: "侵入タスク", status: "not_started" } }
      }.not_to change(Task, :count)
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 on duplicate" do
      get duplicate_project_task_path(other_project, other_task)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "存在しないプロジェクト配下のタスク（異常系）" do
    it "returns 404 for a nonexistent project_id" do
      log_in
      get new_project_task_path(project_id: 999_999)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "画像添付（フォーム→確認→作成フロー）" do
    it "確認画面で画像をアップロードすると blob 化され、signed_id が hidden で持ち回られる" do
      log_in
      expect {
        post confirm_project_tasks_path(project), params: {
          task: { title: "画像付きタスク", status: "not_started",
                  images: [ fixture_file_upload("sample.png", "image/png") ] }
        }
      }.to change(ActiveStorage::Blob, :count).by(1)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('name="task[image_signed_ids][]"')
    end

    it "確認→作成で signed_id 経由の画像がタスクに永続化される" do
      log_in
      # 確認ステップで生成された signed_id を抽出し、作成リクエストに引き渡す（実フロー再現）。
      post confirm_project_tasks_path(project), params: {
        task: { title: "画像付きタスク", status: "not_started",
                images: [ fixture_file_upload("sample.png", "image/png") ] }
      }
      signed_id = response.body[/name="task\[image_signed_ids\]\[\]" value="([^"]+)"/, 1]
      expect(signed_id).to be_present

      expect {
        post project_tasks_path(project), params: {
          task: { title: "画像付きタスク", status: "not_started", image_signed_ids: [ signed_id ] }
        }
      }.to change(Task, :count).by(1)
      expect(Task.order(:id).last.images.count).to eq(1)
    end

    it "確認ステップで非画像（text/plain）は blob 化されず 422 でフォームへ戻る" do
      log_in
      expect {
        post confirm_project_tasks_path(project), params: {
          task: { title: "不正ファイル", status: "not_started",
                  images: [ fixture_file_upload("not_image.txt", "text/plain") ] }
        }
      }.not_to change(ActiveStorage::Blob, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("png / jpeg / gif / webp")
    end
  end

  describe "PATCH /projects/:project_id/tasks/:id（編集での既存画像削除）" do
    it "remove_image_ids で指定した既存画像を1枚外せる" do
      log_in
      task.images.attach(io: File.open(Rails.root.join("spec/fixtures/files/sample.png")),
                         filename: "sample.png", content_type: "image/png")
      attachment_id = task.images.first.id
      expect {
        patch project_task_path(project, task), params: {
          task: { title: task.title, status: task.status, remove_image_ids: [ attachment_id ] }
        }
      }.to change { task.reload.images.count }.by(-1)
      expect(response).to redirect_to(project_task_path(project, task))
    end
  end

  describe "DELETE /projects/:project_id/tasks/:id/images/:image_id（詳細画面からの個別削除）" do
    it "添付済みの画像を1枚削除できる" do
      log_in
      task.images.attach(io: File.open(Rails.root.join("spec/fixtures/files/sample.png")),
                         filename: "sample.png", content_type: "image/png")
      image_id = task.images.first.id
      expect {
        delete detach_image_project_task_path(project, task, image_id)
      }.to change { task.reload.images.count }.by(-1)
      expect(response).to redirect_to(project_task_path(project, task))
    end
  end
end
