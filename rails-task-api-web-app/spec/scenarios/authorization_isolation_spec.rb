require "rails_helper"

# E2E/シナリオ（実DB）: 他ユーザーのリソースへアクセスすると 404 になり、一覧は自分のものだけに
# 限定される、という認可スコープを end-to-end で固定する（UT でモックしなかった保証を実DBで検証）。
RSpec.describe "Authorization isolation", type: :request do
  # signup してトークンを返すヘルパー。
  def signup_token(email)
    post api_v1_signup_path,
         params: { user: { name: "u", email: email,
                           password: "password123", password_confirmation: "password123" } },
         as: :json
    json["token"]
  end

  it "他ユーザーの project/task は 404、project 一覧は自分のものだけ" do
    token_a = signup_token("a@example.com")

    post api_v1_projects_path,
         params: { project: { title: "A の Project" } }, headers: bearer(token_a), as: :json
    project_id = json["id"]

    post api_v1_project_tasks_path(project_id),
         params: { task: { title: "A の Task" } }, headers: bearer(token_a), as: :json
    task_id = json["id"]

    token_b = signup_token("b@example.com")

    # B が A の project にアクセス → 404
    get api_v1_project_path(project_id), headers: bearer(token_b), as: :json
    expect(response).to have_http_status(:not_found)

    # B が A の task にアクセス → 404
    get api_v1_project_task_path(project_id, task_id), headers: bearer(token_b), as: :json
    expect(response).to have_http_status(:not_found)

    # B の project 一覧は空（A のものは見えない）
    get api_v1_projects_path, headers: bearer(token_b), as: :json
    expect(response).to have_http_status(:ok)
    expect(json).to eq([])
  end
end
