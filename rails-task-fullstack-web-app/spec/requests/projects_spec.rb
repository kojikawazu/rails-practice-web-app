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

    it "作成成功で session の退避データをクリアする" do
      log_in
      post confirm_projects_path, params: { project: { title: "クリア確認", description: "x" } }
      post projects_path, params: { project: { title: "クリア確認", description: "x" } }
      # session がクリアされたため confirm(GET) は new へ戻る。
      get confirm_projects_path
      expect(response).to redirect_to(new_project_path)
    end
  end

  # 新規作成の確認画面は (b案2) リダイレクト方式（PRG）。
  describe "POST /projects/confirm（新規・PRG）" do
    it "検証OKなら作成せず confirm(GET) へリダイレクトし、追従先で確認画面を描画する" do
      log_in
      expect {
        post confirm_projects_path, params: { project: { title: "確認用", description: "説明" } }
      }.not_to change(Project, :count)
      expect(response).to redirect_to(confirm_projects_path)

      follow_redirect!
      expect(response).to have_http_status(:success)
      expect(response.body).to include("入力内容の確認")
      expect(response.body).to include("確認用")
    end

    it "renders new with 422 on invalid params" do
      log_in
      post confirm_projects_path, params: { project: { title: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /projects/confirm（新規確認画面の描画）" do
    it "session が無ければ new へリダイレクトする（リロード安全網）" do
      log_in
      get confirm_projects_path
      expect(response).to redirect_to(new_project_path)
    end

    it "session があれば確認画面を描画する" do
      log_in
      post confirm_projects_path, params: { project: { title: "セッション確認", description: "説明" } }
      get confirm_projects_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("入力内容の確認")
      expect(response.body).to include("セッション確認")
    end
  end

  describe "GET /projects/new（「修正する」での入力値復元）" do
    it "restore=1 なら session の入力値をフォームに復元する" do
      log_in
      post confirm_projects_path, params: { project: { title: "復元タイトル", description: "復元説明" } }
      get new_project_path(restore: 1)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("復元タイトル")
      expect(response.body).to include("復元説明")
    end

    it "restore 無しの通常新規は session を破棄し空フォームを返す" do
      log_in
      post confirm_projects_path, params: { project: { title: "破棄対象", description: "x" } }
      get new_project_path
      expect(response.body).not_to include("破棄対象")
      # session が破棄されたため confirm(GET) は new へ戻る。
      get confirm_projects_path
      expect(response).to redirect_to(new_project_path)
    end
  end

  describe "POST /projects/:id/confirm" do
    it "renders confirm without updating the project" do
      log_in
      post confirm_project_path(project), params: { project: { title: "編集確認" } }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("入力内容の確認")
      expect(project.reload.title).not_to eq("編集確認")
    end

    it "renders edit with 422 on invalid params" do
      log_in
      post confirm_project_path(project), params: { project: { title: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /projects/:id/duplicate" do
    let!(:project) { create(:project, user: user, title: "元プロジェクト", description: "元の説明") }

    it "renders the new form prefilled from the source without creating a record" do
      log_in
      expect {
        get duplicate_project_path(project)
      }.not_to change(Project, :count)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("元プロジェクトのコピー")
      expect(response.body).to include("元の説明")
      expect(response.body).to include("確認する")
    end

    it "submits to the create flow (collection confirm), not update" do
      log_in
      get duplicate_project_path(project)
      expect(response.body).to include(confirm_projects_path)
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

  describe "GET /projects (絞り込み表示)" do
    it "shows only the current user's projects" do
      mine = create(:project, user: user, title: "自分のプロジェクトXYZ")
      theirs = create(:project, user: create(:user), title: "他人のプロジェクトXYZ")
      log_in
      get projects_path
      expect(response.body).to include(mine.title)
      expect(response.body).not_to include(theirs.title)
    end
  end

  describe "GET /projects/:id (タスクのステータスバッジ表示)" do
    it "renders status badges for each task state" do
      create(:task, project: project, status: :not_started)
      create(:task, project: project, status: :in_progress)
      create(:task, project: project, status: :completed)
      log_in
      get project_path(project)
      expect(response.body).to include("未着手")
      expect(response.body).to include("進行中")
      expect(response.body).to include("完了")
    end
  end

  describe "他ユーザーのプロジェクトへのアクセス（認可）" do
    let(:other_project) { create(:project, user: create(:user)) }

    before { log_in }

    it "returns 404 on show" do
      get project_path(other_project)
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 on edit" do
      get edit_project_path(other_project)
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 on update" do
      patch project_path(other_project), params: { project: { title: "乗っ取り" } }
      expect(response).to have_http_status(:not_found)
      expect(other_project.reload.title).not_to eq("乗っ取り")
    end

    it "returns 404 on destroy" do
      delete project_path(other_project)
      expect(response).to have_http_status(:not_found)
      expect(Project.exists?(other_project.id)).to be(true)
    end

    it "returns 404 on confirm (member)" do
      post confirm_project_path(other_project), params: { project: { title: "乗っ取り" } }
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 on duplicate" do
      get duplicate_project_path(other_project)
      expect(response).to have_http_status(:not_found)
    end
  end
end
