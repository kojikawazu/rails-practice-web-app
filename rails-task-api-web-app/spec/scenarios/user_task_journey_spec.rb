require "rails_helper"

# E2E/シナリオ（実DB）: signup から task の作成・更新まで、複数エンドポイントを実スタックで縦断する。
# API に UI が無いため E2E == マルチエンドポイント request spec。
RSpec.describe "User task journey", type: :request do
  it "signup → project 作成 → task 作成 → 一覧 → status 更新 が一連で通る" do
    # signup（以降の書き込みはこの token だけで認可される）
    post api_v1_signup_path,
         params: { user: { name: "太郎", email: "taro@example.com",
                           password: "password123", password_confirmation: "password123" } },
         as: :json
    expect(response).to have_http_status(:created)
    token = json["token"]
    expect(token).to be_present

    # project 作成
    post api_v1_projects_path,
         params: { project: { title: "My Project" } }, headers: bearer(token), as: :json
    expect(response).to have_http_status(:created)
    project_id = json["id"]

    # task 作成
    post api_v1_project_tasks_path(project_id),
         params: { task: { title: "設計する", status: "not_started" } }, headers: bearer(token), as: :json
    expect(response).to have_http_status(:created)
    task_id = json["id"]

    # 一覧に作成した task が含まれる
    get api_v1_project_tasks_path(project_id), headers: bearer(token), as: :json
    expect(response).to have_http_status(:ok)
    expect(json.map { |t| t["id"] }).to include(task_id)

    # status を更新
    patch api_v1_project_task_path(project_id, task_id),
          params: { task: { status: "completed" } }, headers: bearer(token), as: :json
    expect(response).to have_http_status(:ok)

    # 更新が詳細に反映される
    get api_v1_project_task_path(project_id, task_id), headers: bearer(token), as: :json
    expect(response).to have_http_status(:ok)
    expect(json["status"]).to eq("completed")
  end
end
