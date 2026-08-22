require 'rails_helper'

RSpec.describe "Projects", type: :request do
  let(:user) { create(:user) }
  let!(:project) { create(:project, user: user) }

  def log_in
    post login_path, params: { email: user.email, password: 'password123' }
  end

  describe "GET /projects（一覧）" do
    context "ログイン済みの場合" do
      it "プロジェクト一覧を表示する" do
        log_in
        get projects_path
        expect(response).to have_http_status(:success)
      end
    end

    context "未ログインの場合" do
      it "require_login によりログイン画面へリダイレクトする" do
        get projects_path
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "GET /projects/:id（詳細）" do
    it "プロジェクト詳細を表示する" do
      log_in
      get project_path(project)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /projects（作成の確定）" do
    it "プロジェクトを作成し、PRG に従って詳細へリダイレクトする" do
      log_in
      expect {
        post projects_path, params: { project: { title: "新プロジェクト", description: "説明" } }
      }.to change(Project, :count).by(1)
      expect(response).to redirect_to(project_path(Project.last))
    end

    it "タイトルが空なら作成せず、new を 422 で再描画する" do
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

    it "検証に失敗したら確認画面へ進ませず、new を 422 で再描画する" do
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

  describe "POST /projects/:id/confirm（編集の確認画面）" do
    it "編集の確認画面は DB を更新せず、確認画面だけを描画する" do
      log_in
      post confirm_project_path(project), params: { project: { title: "編集確認" } }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("入力内容の確認")
      expect(project.reload.title).not_to eq("編集確認")
    end

    it "検証に失敗したら edit を 422 で再描画する" do
      log_in
      post confirm_project_path(project), params: { project: { title: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /projects/:id/duplicate（複製）" do
    let!(:project) { create(:project, user: user, title: "元プロジェクト", description: "元の説明") }

    it "複製元の値を初期入力した新規フォームを返し、DB にはレコードを作らない" do
      log_in
      expect {
        get duplicate_project_path(project)
      }.not_to change(Project, :count)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("元プロジェクトのコピー")
      expect(response.body).to include("元の説明")
      expect(response.body).to include("確認する")
    end

    it "複製フォームの送信先は更新ではなく、新規作成フロー（コレクションの confirm）である" do
      log_in
      get duplicate_project_path(project)
      expect(response.body).to include(confirm_projects_path)
    end
  end

  describe "PATCH /projects/:id（更新）" do
    it "プロジェクトを更新し、詳細へリダイレクトする" do
      log_in
      patch project_path(project), params: { project: { title: "更新後タイトル" } }
      expect(response).to redirect_to(project_path(project))
      expect(project.reload.title).to eq("更新後タイトル")
    end
  end

  describe "DELETE /projects/:id（削除）" do
    it "プロジェクトを削除し、一覧へリダイレクトする" do
      log_in
      expect {
        delete project_path(project)
      }.to change(Project, :count).by(-1)
      expect(response).to redirect_to(projects_path)
    end
  end

  describe "GET /projects (絞り込み表示)" do
    it "一覧には current_user のプロジェクトだけを表示し、他ユーザーのものは含めない" do
      mine = create(:project, user: user, title: "自分のプロジェクトXYZ")
      theirs = create(:project, user: create(:user), title: "他人のプロジェクトXYZ")
      log_in
      get projects_path
      expect(response.body).to include(mine.title)
      expect(response.body).not_to include(theirs.title)
    end
  end

  describe "GET /projects/:id (タスクのステータスバッジ表示)" do
    it "enum の 3 状態それぞれに対応する日本語バッジを表示する" do
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

  describe "GET /projects（タスク件数の表示）" do
    # 一覧は 1 行 = 1 プロジェクトのため、行を特定してから件数バッジを読む
    # （body 全体の include では、他プロジェクトの件数との取り違えを検出できない）。
    def task_count_badge_of(title)
      Capybara.string(response.body).find("tr", text: title).find(".badge").text
    end

    it "タスクが 0 件のプロジェクトも一覧から消さず、件数 0 を表示する" do
      create(:project, user: user, title: "タスク未登録プロジェクト")
      log_in
      get projects_path
      expect(task_count_badge_of("タスク未登録プロジェクト")).to eq("0")
    end

    it "プロジェクトごとに、自分の配下のタスク件数だけを表示する" do
      two_tasks = create(:project, user: user, title: "タスク2件プロジェクト")
      three_tasks = create(:project, user: user, title: "タスク3件プロジェクト")
      create_list(:task, 2, project: two_tasks)
      create_list(:task, 3, project: three_tasks)
      log_in
      get projects_path
      expect(task_count_badge_of("タスク2件プロジェクト")).to eq("2")
      expect(task_count_badge_of("タスク3件プロジェクト")).to eq("3")
    end

    it "プロジェクトが 0 件のユーザーでも、行が無い一覧を表示する" do
      no_project_user = create(:user)
      post login_path, params: { email: no_project_user.email, password: "password123" }
      get projects_path
      expect(response).to have_http_status(:success)
      expect(Capybara.string(response.body).all("tbody tr")).to be_empty
    end

    it "一覧は作成順に並べる（集計の GROUP BY で表示順が変わらないことの固定）" do
      create(:project, user: user, title: "先に作ったプロジェクト")
      create(:project, user: user, title: "後に作ったプロジェクト")
      log_in
      get projects_path
      titles = Capybara.string(response.body).all("tbody tr td strong").map(&:text)
      expect(titles.last(2)).to eq([ "先に作ったプロジェクト", "後に作ったプロジェクト" ])
    end

    it "タスク件数の集計は 1 クエリで済ませ、プロジェクト件数に比例して増やさない（N+1 の回帰ガード）" do
      log_in
      create_list(:task, 2, project: project)
      queries_for_one_project = count_queries(/"tasks"/) { get projects_path }

      3.times do |i|
        create_list(:task, 2, project: create(:project, user: user, title: "追加プロジェクト#{i}"))
      end
      queries_for_four_projects = count_queries(/"tasks"/) { get projects_path }

      expect(queries_for_one_project).to eq(1)
      expect(queries_for_four_projects).to eq(queries_for_one_project)
    end
  end

  describe "他ユーザーのプロジェクトへのアクセス（認可）" do
    let(:other_project) { create(:project, user: create(:user)) }

    before { log_in }

    it "他ユーザーのプロジェクト詳細は、403 ではなく 404 を返して存在自体を秘匿する" do
      get project_path(other_project)
      expect(response).to have_http_status(:not_found)
    end

    it "他ユーザーのプロジェクトの編集フォームも 404 を返す" do
      get edit_project_path(other_project)
      expect(response).to have_http_status(:not_found)
    end

    it "他ユーザーのプロジェクトは更新できず、404 を返して値も変わらない" do
      patch project_path(other_project), params: { project: { title: "乗っ取り" } }
      expect(response).to have_http_status(:not_found)
      expect(other_project.reload.title).not_to eq("乗っ取り")
    end

    it "他ユーザーのプロジェクトは削除できず、404 を返してレコードも残る" do
      delete project_path(other_project)
      expect(response).to have_http_status(:not_found)
      expect(Project.exists?(other_project.id)).to be(true)
    end

    it "確認画面（メンバー）も認可の抜け道にならず、404 を返す" do
      post confirm_project_path(other_project), params: { project: { title: "乗っ取り" } }
      expect(response).to have_http_status(:not_found)
    end

    it "他ユーザーのプロジェクトは複製できず、404 を返す" do
      get duplicate_project_path(other_project)
      expect(response).to have_http_status(:not_found)
    end
  end
end
