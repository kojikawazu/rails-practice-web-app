# タスクの CRUD・確認画面フロー・画像添付を扱うコントローラー。
# projects 配下のネストルーティングで、常に current_user のプロジェクトのタスクのみを操作する。
#
# 画像はファイル input を確認画面の hidden で持ち回れないため、確認ステップで一旦 blob 化し、
# signed_id を round-trip させる（JS 不要）。持ち回った signed_id は外部入力なので、受け取る
# confirm / create / update のすべてで TaskImageService.resolve により current_user 向けの
# staging 中 blob であることを検証し、検証できないものは attach せず 422 で入力し直させる。
class TasksController < ApplicationController
  before_action :require_login
  before_action :set_project
  before_action :set_task, only: %i[show edit update destroy detach_image]

  # タスク一覧。HTML はプロジェクト詳細へ集約し、JSON のみ一覧を返す。
  #
  # @return [void] HTML: プロジェクト詳細へリダイレクト／JSON: index を描画
  def index
    @tasks = TaskService.list(@project)

    respond_to do |format|
      format.html { redirect_to project_path(@project) }
      format.json { render :index }
    end
  end

  # タスク詳細を表示する。
  #
  # @return [void] set_task で取得済みの @task で show ビューを描画
  def show
  end

  # 新規作成フォームを表示する。
  #
  # @return [void] 空の @task で new ビューを描画
  def new
    @task = @project.tasks.build
  end

  # 編集フォームを表示する。
  #
  # @return [void] set_task で取得済みの @task で edit ビューを描画
  def edit
  end

  # 複製。複製元の値を初期入力した新規作成フォームを表示する（DB は変更しない）。
  # 以降は通常の confirm → create フローに合流する（@project は set_project で取得済み）。
  #
  # ステータスは複製しない。新規作成は not_started 固定（Task の遷移規則）のため、
  # 進行中・完了のタスクを複製した瞬間に規則違反のレコードを作ろうとしてしまう。
  #
  # @return [void] 複製元の値を入れた @task で new ビューを描画
  def duplicate
    source = @project.tasks.find(params[:id])
    @task = @project.tasks.build(title: "#{source.title}のコピー",
                                 start_date: source.start_date, end_date: source.end_date)
    flash.now[:notice] = "「#{source.title}」を複製しました。内容を確認して作成してください。"
    render :new
  end

  # 確認画面の表示。DB には保存せず valid? で検証のみ行う。
  # id 有無で新規(build)／編集(find)を切り替える（@project は set_project で取得済み）。
  #
  # 画像はファイル input を確認画面の hidden で持ち回れないため、ここで一旦
  # サーバー経由で blob を作り、signed_id を round-trip させる（JS不要）。
  #
  # @return [void] 検証成功: confirm ／「修正する」: new/edit ／検証失敗・不正画像・不正 signed_id: new/edit（422）
  #   ／GET・HEAD アクセス時: 入力フォームへリダイレクト
  def confirm
    # 確認画面は POST 専用。リロード/戻る等で GET / HEAD された場合は入力フォームへ戻す
    # （show ルートへ誤って落ちて 404 になるのを防ぐ。入力値は保持できないため作り直し）。
    #
    # 判定は「書き込み（POST）かどうか」で行う。Rails は HEAD を GET ルートへ配送するが
    # `request.get?` は HEAD で false になるため、GET を条件にすると HEAD が POST 分岐へ落ち、
    # Strong Parameters 不足や画像 staging に進んでしまう。
    unless request.post?
      target = params[:id] ? edit_project_task_path(@project, params[:id]) : new_project_task_path(@project)
      return redirect_to(target, alert: "確認画面は再読み込みできません。入力し直してください。")
    end

    @task = params[:id] ? @project.tasks.find(params[:id]) : @project.tasks.build
    @task.assign_attributes(task_params)
    @task.app_host = request.host # 自オリジン埋め込み拒否の判定用
    @remove_attachment_ids = remove_attachment_ids

    # 前回までに選択した画像（持ち回り分）を照合する。検証できなければ選択を破棄して入力し直させる。
    @staged_blobs = TaskImageService.resolve(current_user, carried_signed_ids)
    return render_invalid_staged_images(form_template) if @staged_blobs.nil?

    # 新規アップロードを事前検証し blob 化。不正が混じれば nil＝blob を作らずフォームへ戻す（オーファン防止）。
    new_blobs = TaskImageService.stage(uploaded_image_files)
    if new_blobs.nil?
      @task.errors.add(:images, "は png / jpeg / gif / webp 形式・1枚5MB以下のみ対応しています")
      return render(form_template, status: :unprocessable_content) # 照合済みの既存選択は保持する
    end

    # 既存の選択と合算して持ち回る（signed_id はビューで current_user 向けに発行する）。
    @staged_blobs += new_blobs

    # 「修正する」押下時は入力フォームへ戻す（入力値・画像選択を保持）。
    return render(form_template) if params[:back].present?

    if @task.valid?
      render :confirm
    else
      render(form_template, status: :unprocessable_content)
    end
  end

  # 新規作成の確定。確認画面から持ち回った画像を添付して保存する。
  #
  # @return [void] 成功: プロジェクト詳細へリダイレクト／失敗・不正 signed_id: new を 422 で再描画
  def create
    @task = TaskService.build(@project, task_params)
    @task.app_host = request.host
    @staged_blobs = TaskImageService.resolve(current_user, carried_signed_ids)
    return render_invalid_staged_images(:new) if @staged_blobs.nil?

    TaskImageService.attach(@task, @staged_blobs)

    if @task.save
      redirect_to project_path(@project), notice: "タスクを作成しました。"
    else
      render :new, status: :unprocessable_content
    end
  end

  # タスクを更新する。新規画像の添付と、削除予約された既存画像の purge を行う。
  #
  # @return [void] 成功: 詳細へ 303 リダイレクト／失敗・不正 signed_id: edit を 422 で再描画
  def update
    @task.assign_attributes(task_params)
    @task.app_host = request.host
    @remove_attachment_ids = remove_attachment_ids
    @staged_blobs = TaskImageService.resolve(current_user, carried_signed_ids)
    return render_invalid_staged_images(:edit) if @staged_blobs.nil?

    TaskImageService.attach(@task, @staged_blobs)

    if @task.save
      TaskImageService.purge(@task, @remove_attachment_ids)
      redirect_to project_task_path(@project, @task), notice: "タスクを更新しました。", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  # タスクを削除する。
  #
  # @return [void] プロジェクト詳細へ 303 リダイレクト
  def destroy
    TaskService.destroy(@task)
    redirect_to project_path(@project), notice: "タスクを削除しました。", status: :see_other
  end

  # 添付済み画像を1枚削除する（詳細画面からの個別削除）。
  # :attachment_id は attachment の id。@task.images 起点で引くことで、
  # 他タスク・他ユーザーの添付は取得できない（見つからなければ 404）。
  #
  # @return [void] 詳細へ 303 リダイレクト
  def detach_image
    @task.images.find(params[:attachment_id]).purge
    redirect_to project_task_path(@project, @task), notice: "画像を削除しました。", status: :see_other
  end

  private

  # 入力フォームのテンプレート。確認フローは新規（build）と編集（find）で同じ action を使うため、
  # 戻り先を永続化の有無で切り替える。
  #
  # @return [Symbol] :edit（永続化済み）／:new（新規）
  def form_template
    @task.persisted? ? :edit : :new
  end

  # 持ち回った signed_id が照合できなかったときの応答。
  # 検証できない選択は信用せず破棄し（hidden で再送しない）、画像を選び直させる。
  #
  # @param template [Symbol] 再描画する入力フォーム（:new / :edit）
  # @return [void] template を 422 で再描画
  def render_invalid_staged_images(template)
    @staged_blobs = []
    @task.errors.add(:images, "の有効期限が切れたか、不正な指定です。もう一度選択してください")
    render template, status: :unprocessable_content
  end

  # URL の :project_id から current_user のプロジェクトを取得して @project に設定する。
  #
  # @return [void]
  # @raise [ActiveRecord::RecordNotFound] 他ユーザーのリソース・存在しない id
  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  # URL の :id から @project 配下のタスクを取得して @task に設定する。
  #
  # @return [void]
  # @raise [ActiveRecord::RecordNotFound] 存在しない id
  def set_task
    @task = @project.tasks.find(params[:id])
  end

  # Strong Parameters。タスクの許可カラムのみを抽出する。
  # フルスタック版は期間管理（start_date/end_date）を持つ点が API 版との差分。
  #
  # @return [ActionController::Parameters] title / status / start_date / end_date / preview_url
  def task_params
    params.require(:task).permit(:title, :status, :start_date, :end_date, :preview_url)
  end

  # フォームから送られた新規アップロードファイル（ActionDispatch::Http::UploadedFile）。
  #
  # @return [Array<ActionDispatch::Http::UploadedFile>] 空要素を除いたアップロードファイル群
  def uploaded_image_files
    Array(params.dig(:task, :images)).reject(&:blank?)
  end

  # 確認画面を round-trip してきた、アップロード済み blob の signed_id 群。
  #
  # @return [Array<String>] 空要素を除いた signed_id の配列
  def carried_signed_ids
    Array(params.dig(:task, :image_signed_ids)).reject(&:blank?)
  end

  # 編集フォームでチェックされた、削除対象の既存添付（ActiveStorage::Attachment）の id 群。
  # blob の id ではなく attachment の id を受け取る（同じ blob を複数レコードで共有できるため、
  # 「どのタスクのどの添付を外すか」は attachment でしか指定できない）。
  #
  # @return [Array<String>] 空要素を除いた添付 id の配列
  def remove_attachment_ids
    Array(params.dig(:task, :remove_attachment_ids)).reject(&:blank?)
  end
end
