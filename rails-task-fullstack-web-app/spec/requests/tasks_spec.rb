require 'rails_helper'

RSpec.describe "Tasks", type: :request do
  let(:user) { create(:user) }
  let!(:project) { create(:project, user: user) }
  let!(:task) { create(:task, project: project) }

  def log_in
    post login_path, params: { email: user.email, password: 'password123' }
  end

  # ステータス選択の option を出現順で読む（順序も検証対象のため text ではなく value を見る）。
  def status_options_in_form
    Capybara.string(response.body).all("select[name='task[status]'] option").map { |option| option[:value] }
  end

  # blob と attachment の id 系列をずらしてから添付する。
  # 両者が偶然一致していると、blob の id で引く実装でもテストが通ってしまい取り違えを検出できない。
  def attach_images_with_skewed_ids(task, filenames)
    3.times do
      ActiveStorage::Blob.create_and_upload!(io: File.open(Rails.root.join("spec/fixtures/files/sample.png")),
                                             filename: "orphan.png", content_type: "image/png")
    end
    filenames.each do |filename|
      task.images.attach(io: File.open(Rails.root.join("spec/fixtures/files/sample.png")),
                         filename: filename, content_type: "image/png")
    end
    task.reload
  end

  describe "GET /projects/:project_id/tasks/new（新規作成フォーム）" do
    it "新規作成フォームを表示する" do
      log_in
      get new_project_task_path(project)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /projects/:project_id/tasks/:id（タスク詳細）" do
    it "タスク詳細を表示する" do
      log_in
      get project_task_path(project, task)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /projects/:project_id/tasks（作成の確定）" do
    it "タスクを作成し、PRG に従ってプロジェクト詳細へリダイレクトする" do
      log_in
      expect {
        post project_tasks_path(project), params: {
          task: { title: "新タスク", status: "not_started", start_date: Date.tomorrow, end_date: Date.tomorrow + 3 }
        }
      }.to change(Task, :count).by(1)
      expect(response).to redirect_to(project_path(project))
    end

    it "タイトルが空なら作成せず、new を 422 で再描画する" do
      log_in
      post project_tasks_path(project), params: { task: { title: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /projects/:project_id/tasks/confirm（新規の確認画面）" do
    it "DB には保存せず、valid? の検証だけを行って確認画面を描画する" do
      log_in
      expect {
        post confirm_project_tasks_path(project), params: {
          task: { title: "確認用タスク", status: "not_started", start_date: Date.tomorrow, end_date: Date.tomorrow + 3 }
        }
      }.not_to change(Task, :count)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("入力内容の確認")
    end

    it "検証に失敗したら確認画面へ進ませず、new を 422 で再描画する" do
      log_in
      post confirm_project_tasks_path(project), params: { task: { title: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "「修正する」押下時は入力値を保持したままフォームへ戻す" do
      log_in
      post confirm_project_tasks_path(project), params: {
        task: { title: "確認用タスク", status: "not_started" }, back: 1
      }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("確認する")
    end
  end

  describe "POST /projects/:project_id/tasks/:id/confirm（編集の確認画面）" do
    it "編集の確認画面も DB を更新せず、確認画面だけを描画する" do
      log_in
      post confirm_project_task_path(project, task), params: { task: { title: "編集確認タスク" } }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("入力内容の確認")
      expect(task.reload.title).not_to eq("編集確認タスク")
    end

    it "検証に失敗したら edit を 422 で再描画する" do
      log_in
      post confirm_project_task_path(project, task), params: { task: { title: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /projects/:project_id/tasks/:id/duplicate（複製）" do
    let!(:task) { create(:task, :in_progress, project: project, title: "元タスク") }

    it "複製元の値を初期入力した新規フォームを返し、DB にはレコードを作らない" do
      log_in
      expect {
        get duplicate_project_task_path(project, task)
      }.not_to change(Task, :count)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("元タスクのコピー")
      expect(response.body).to include("確認する")
    end

    it "複製フォームの送信先は更新ではなく、新規作成フロー（コレクションの confirm）である" do
      log_in
      get duplicate_project_task_path(project, task)
      expect(response.body).to include(confirm_project_tasks_path(project))
    end

    it "進行中のタスクを複製しても、新規作成は未着手固定のためステータスは引き継がない" do
      log_in
      get duplicate_project_task_path(project, task)
      expect(response.body).to include("未着手（新規作成時は固定）")
      expect(Capybara.string(response.body).all("select[name='task[status]']")).to be_empty
    end
  end

  describe "PATCH /projects/:project_id/tasks/:id（更新）" do
    it "タスクを更新し、タスク詳細へリダイレクトする" do
      log_in
      patch project_task_path(project, task), params: {
        task: { title: "更新タスク", status: "in_progress" }
      }
      expect(response).to redirect_to(project_task_path(project, task))
      expect(task.reload.title).to eq("更新タスク")
    end
  end

  describe "PATCH /projects/:project_id/tasks/:id（ステータス遷移）" do
    it "未着手 → 進行中 は更新でき、タスク詳細へリダイレクトする" do
      log_in
      patch project_task_path(project, task), params: { task: { status: "in_progress" } }
      expect(response).to redirect_to(project_task_path(project, task))
      expect(task.reload.status).to eq("in_progress")
    end

    it "完了 → 進行中 の差し戻しは許可する" do
      done = create(:task, :completed, project: project)
      log_in
      patch project_task_path(project, done), params: { task: { status: "in_progress" } }
      expect(done.reload.status).to eq("in_progress")
    end

    it "未着手 → 完了 は UI を経由しない直接送信でも拒否し、edit を 422 で再描画して値も変えない" do
      log_in
      patch project_task_path(project, task), params: { task: { status: "completed" } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(task.reload.status).to eq("not_started")
    end

    it "完了 → 未着手 も拒否する（差し戻し先は進行中だけ）" do
      done = create(:task, :completed, project: project)
      log_in
      patch project_task_path(project, done), params: { task: { status: "not_started" } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(done.reload.status).to eq("completed")
    end
  end

  describe "POST /projects/:project_id/tasks（作成時のステータス）" do
    it "ステータスを送らない通常の作成は、未着手のタスクになる" do
      log_in
      post project_tasks_path(project), params: { task: { title: "既定ステータス確認" } }
      expect(Task.find_by(title: "既定ステータス確認").status).to eq("not_started")
    end

    it "完了を指定した作成は拒否し、new を 422 で再描画してレコードも作らない" do
      log_in
      expect {
        post project_tasks_path(project), params: { task: { title: "完了で作成", status: "completed" } }
      }.not_to change(Task, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "ステータスの選択肢（フォーム）" do
    it "新規フォームはステータスを選ばせず、未着手固定であることを示す" do
      log_in
      get new_project_task_path(project)
      expect(response.body).to include("未着手（新規作成時は固定）")
      expect(Capybara.string(response.body).all("select[name='task[status]']")).to be_empty
    end

    it "未着手タスクの編集フォームは、現在の状態と進行中だけを選択肢に出す" do
      log_in
      get edit_project_task_path(project, task)
      expect(status_options_in_form).to eq(%w[not_started in_progress])
    end

    it "完了タスクの編集フォームは、差し戻し先の進行中だけを遷移先に出す" do
      done = create(:task, :completed, project: project)
      log_in
      get edit_project_task_path(project, done)
      expect(status_options_in_form).to eq(%w[completed in_progress])
    end
  end

  describe "DELETE /projects/:project_id/tasks/:id（削除）" do
    it "タスクを削除し、プロジェクト詳細へリダイレクトする" do
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

    it "他ユーザーのタスク詳細は、403 ではなく 404 を返して存在自体を秘匿する" do
      get project_task_path(other_project, other_task)
      expect(response).to have_http_status(:not_found)
    end

    it "他ユーザーのタスクの編集フォームも 404 を返す" do
      get edit_project_task_path(other_project, other_task)
      expect(response).to have_http_status(:not_found)
    end

    it "他ユーザーのタスクは更新できず、404 を返して値も変わらない" do
      patch project_task_path(other_project, other_task), params: { task: { title: "乗っ取り" } }
      expect(response).to have_http_status(:not_found)
      expect(other_task.reload.title).not_to eq("乗っ取り")
    end

    it "他ユーザーのタスクは削除できず、404 を返してレコードも残る" do
      delete project_task_path(other_project, other_task)
      expect(response).to have_http_status(:not_found)
      expect(Task.exists?(other_task.id)).to be(true)
    end

    it "他ユーザーのプロジェクト配下にはタスクを作成できず、404 を返す" do
      expect {
        post project_tasks_path(other_project), params: { task: { title: "侵入タスク", status: "not_started" } }
      }.not_to change(Task, :count)
      expect(response).to have_http_status(:not_found)
    end

    it "他ユーザーのタスクは複製できず、404 を返す" do
      get duplicate_project_task_path(other_project, other_task)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "存在しないプロジェクト配下のタスク（異常系）" do
    it "存在しない project_id では 404 を返す（不存在と他ユーザーを同じ応答に揃える）" do
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

    it "確認画面で新規アップロード画像がサムネイル（img タグ）で表示される" do
      log_in
      post confirm_project_tasks_path(project), params: {
        task: { title: "画像付きタスク", status: "not_started",
                images: [ fixture_file_upload("sample.png", "image/png") ] }
      }
      expect(response).to have_http_status(:success)
      # ファイル名バッジだけでなく、variant の representation URL を指す img が描画される。
      expect(response.body).to include("/rails/active_storage/representations/")
      expect(response.body).to match(%r{<img[^>]+/rails/active_storage/representations/})
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
    it "remove_attachment_ids で指定した既存画像を1枚外せる" do
      log_in
      task.images.attach(io: File.open(Rails.root.join("spec/fixtures/files/sample.png")),
                         filename: "sample.png", content_type: "image/png")
      attachment_id = task.images.first.id
      expect {
        patch project_task_path(project, task), params: {
          task: { title: task.title, status: task.status, remove_attachment_ids: [ attachment_id ] }
        }
      }.to change { task.reload.images.count }.by(-1)
      expect(response).to redirect_to(project_task_path(project, task))
    end

    it "blob と attachment の id がずれていても、選んだ画像だけが外れる" do
      log_in
      attach_images_with_skewed_ids(task, %w[keep.png remove.png])
      target = task.images.find { |image| image.filename.to_s == "remove.png" }

      expect {
        patch project_task_path(project, task), params: {
          task: { title: task.title, status: task.status, remove_attachment_ids: [ target.id ] }
        }
      }.to change { task.reload.images.count }.by(-1)
      expect(task.reload.images.map { |image| image.filename.to_s }).to eq([ "keep.png" ])
    end

    it "確認画面を round-trip しても、削除予約した画像だけが外れる" do
      log_in
      attach_images_with_skewed_ids(task, %w[keep.png remove.png])
      target = task.images.find { |image| image.filename.to_s == "remove.png" }

      post confirm_project_task_path(project, task), params: {
        task: { title: task.title, status: task.status, remove_attachment_ids: [ target.id ] }
      }
      expect(response.body).to include(%(name="task[remove_attachment_ids][]" value="#{target.id}"))

      expect {
        patch project_task_path(project, task), params: {
          task: { title: task.title, status: task.status, remove_attachment_ids: [ target.id ] }
        }
      }.to change { task.reload.images.count }.by(-1)
      expect(task.reload.images.map { |image| image.filename.to_s }).to eq([ "keep.png" ])
    end

    it "他タスクの添付 id を送っても外せない（認可境界は images_attachments のスコープで担保する）" do
      log_in
      other_task = create(:task, project: project)
      other_task.images.attach(io: File.open(Rails.root.join("spec/fixtures/files/sample.png")),
                               filename: "other.png", content_type: "image/png")
      task.images.attach(io: File.open(Rails.root.join("spec/fixtures/files/sample.png")),
                         filename: "mine.png", content_type: "image/png")

      expect {
        patch project_task_path(project, task), params: {
          task: { title: task.title, status: task.status,
                  remove_attachment_ids: [ other_task.images.first.id ] }
        }
      }.not_to change { other_task.reload.images.count }
      expect(task.reload.images.count).to eq(1)
    end
  end

  describe "DELETE /projects/:project_id/tasks/:id/images/:attachment_id（詳細画面からの個別削除）" do
    it "添付済みの画像を1枚削除できる" do
      log_in
      task.images.attach(io: File.open(Rails.root.join("spec/fixtures/files/sample.png")),
                         filename: "sample.png", content_type: "image/png")
      attachment_id = task.images.first.id
      expect {
        delete detach_image_project_task_path(project, task, attachment_id)
      }.to change { task.reload.images.count }.by(-1)
      expect(response).to redirect_to(project_task_path(project, task))
    end

    it "blob と attachment の id がずれていても、指定した画像だけが削除される" do
      log_in
      attach_images_with_skewed_ids(task, %w[keep.png remove.png])
      target = task.images.find { |image| image.filename.to_s == "remove.png" }

      delete detach_image_project_task_path(project, task, target.id)
      expect(task.reload.images.map { |image| image.filename.to_s }).to eq([ "keep.png" ])
    end
  end

  describe "GET /projects/:project_id/tasks/confirm（確認画面の再読み込み・戻る対策）" do
    it "新規(コレクション)の GET confirm は新規フォームへリダイレクトする（404 にしない）" do
      log_in
      get confirm_project_tasks_path(project)
      expect(response).to redirect_to(new_project_task_path(project))
    end

    it "編集(メンバー)の GET confirm は編集フォームへリダイレクトする" do
      log_in
      get confirm_project_task_path(project, task)
      expect(response).to redirect_to(edit_project_task_path(project, task))
    end

    # Rails は HEAD を GET ルートへ配送する。request.get? は HEAD で false になるため、
    # GET で分岐すると HEAD だけが POST（書き込み）の処理へ落ちる。
    it "新規(コレクション)の HEAD confirm は GET と同じく新規フォームへリダイレクトする" do
      log_in
      head confirm_project_tasks_path(project)
      expect(response).to redirect_to(new_project_task_path(project))
    end

    it "編集(メンバー)の HEAD confirm は GET と同じく編集フォームへリダイレクトする" do
      log_in
      head confirm_project_task_path(project, task)
      expect(response).to redirect_to(edit_project_task_path(project, task))
    end
  end

  describe "プレビュー URL（フォーム→確認→作成）" do
    it "確認画面で http(s) URL が sandbox iframe としてプレビューされる" do
      log_in
      post confirm_project_tasks_path(project), params: {
        task: { title: "URL付きタスク", status: "not_started", preview_url: "https://example.com" }
      }
      expect(response).to have_http_status(:success)
      expect(response.body).to include('<iframe')
      expect(response.body).to include('sandbox="allow-scripts allow-same-origin"')
      expect(response.body).to include('https://example.com')
    end

    it "自ホストの URL は確認に進まない（自オリジン埋め込み＝sandbox 脱獄経路を拒否）" do
      log_in
      # request spec の既定ホストは www.example.com
      post confirm_project_tasks_path(project), params: {
        task: { title: "自ホスト", status: "not_started", preview_url: "http://www.example.com/admin" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).not_to include("<iframe")
    end

    it "localhost の URL は確認に進まない（内部アドレス埋め込みを拒否）" do
      log_in
      post confirm_project_tasks_path(project), params: {
        task: { title: "ローカル", status: "not_started", preview_url: "http://localhost:3000/" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "確認→作成で preview_url が永続化される" do
      log_in
      expect {
        post project_tasks_path(project), params: {
          task: { title: "URL付きタスク", status: "not_started", preview_url: "https://example.com/x" }
        }
      }.to change(Task, :count).by(1)
      expect(Task.order(:id).last.preview_url).to eq("https://example.com/x")
    end

    it "javascript: スキームは確認に進まず 422・iframe を描画しない（XSS 防止）" do
      log_in
      post confirm_project_tasks_path(project), params: {
        task: { title: "悪意URL", status: "not_started", preview_url: "javascript:alert(document.cookie)" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).not_to include("<iframe")
    end

    it "javascript: スキームは作成もできない（422）" do
      log_in
      expect {
        post project_tasks_path(project), params: {
          task: { title: "悪意URL", status: "not_started", preview_url: "javascript:alert(1)" }
        }
      }.not_to change(Task, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
