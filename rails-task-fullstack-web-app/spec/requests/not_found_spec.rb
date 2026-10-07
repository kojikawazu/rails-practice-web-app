require "rails_helper"

# RecordNotFound のグローバルハンドリング（ApplicationController の rescue_from）。
# 認可は current_user 起点の association scope で行い、他ユーザーのリソースは
# 「存在しない」と同じ 404 で秘匿する。静的な public/404.html ではなく、アプリのレイアウトの中で
# 状況と戻り先を示す（リダイレクトにすると 404 の秘匿が崩れるため、ステータスは 404 のまま）。
RSpec.describe "Not Found（RecordNotFound のハンドリング）", type: :request do
  let(:user) { create(:user) }
  let!(:project) { create(:project, user: user) }
  let(:other_project) { create(:project, user: create(:user)) }
  let(:not_found_message) { "お探しのページは見つからないか、アクセスする権限がありません。" }

  def log_in
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "存在しないプロジェクトは 404 で、レイアウト内にメッセージと一覧への戻り先を表示する" do
    log_in
    get project_path(id: 999_999)

    expect(response).to have_http_status(:not_found)
    page = Capybara.string(response.body)
    expect(page).to have_css(".flash-alert", text: not_found_message)
    expect(page).to have_link("プロジェクト一覧へ", href: projects_path)
    # 静的な 404.html ではなく、アプリのレイアウト（サイドバーのナビゲーション）の中で描画する。
    expect(page).to have_css("nav.sidebar")
  end

  it "存在しないタスクも同じ 404 を返す" do
    log_in
    get project_task_path(project, id: 999_999)

    expect(response).to have_http_status(:not_found)
    expect(response.body).to include(not_found_message)
  end

  it "他ユーザーのプロジェクトは、存在しない場合と同じ本文の 404 を返す（存在を秘匿する）" do
    log_in
    # ログイン直後のフラッシュ（「ログインしました。」）は最初の描画で消費されるため、
    # 比較する 2 回の応答に差が出ないよう、先に 1 回描画して消費しておく。
    get projects_path
    get project_path(id: 999_999)
    missing_body = Capybara.string(response.body).find(".main-area").text

    get project_path(other_project)

    expect(response).to have_http_status(:not_found)
    expect(Capybara.string(response.body).find(".main-area").text).to eq(missing_body)
  end

  it "JSON の要求には統一エラー形式の 404 を返す" do
    log_in
    get project_tasks_path(project_id: 999_999, format: :json)

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body).to eq("error" => "Not found")
  end

  it "未ログインなら RecordNotFound より先に require_login がログイン画面へ誘導する" do
    get project_path(id: 999_999)

    expect(response).to redirect_to(login_path)
  end
end
