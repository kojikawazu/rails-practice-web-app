class TasksController < ApplicationController
  before_action :require_login
  before_action :set_project
  before_action :set_task, only: %i[show edit update destroy detach_image]

  def index
    @tasks = @project.tasks

    respond_to do |format|
      format.html { redirect_to project_path(@project) }
      format.json { render :index }
    end
  end

  def show
  end

  def new
    @task = @project.tasks.build
  end

  def edit
  end

  # 複製。複製元の値を初期入力した新規作成フォームを表示する（DB は変更しない）。
  # 以降は通常の confirm → create フローに合流する（@project は set_project で取得済み）。
  def duplicate
    source = @project.tasks.find(params[:id])
    @task = @project.tasks.build(title: "#{source.title}のコピー", status: source.status,
                                 start_date: source.start_date, end_date: source.end_date)
    flash.now[:notice] = "「#{source.title}」を複製しました。内容を確認して作成してください。"
    render :new
  end

  # 確認画面の表示。DB には保存せず valid? で検証のみ行う。
  # id 有無で新規(build)／編集(find)を切り替える（@project は set_project で取得済み）。
  #
  # 画像はファイル input を確認画面の hidden で持ち回れないため、ここで一旦
  # サーバー経由で blob を作り、signed_id を round-trip させる（JS不要）。
  def confirm
    @task = params[:id] ? @project.tasks.find(params[:id]) : @project.tasks.build
    @task.assign_attributes(task_params)
    @remove_image_ids = remove_image_ids

    # 新規アップロードを事前検証。不正なら blob を作らずフォームへ戻す（オーファン防止）。
    uploaded = uploaded_image_files
    if uploaded.any? { |f| !valid_image_upload?(f) }
      @image_signed_ids = carried_signed_ids # 既存の選択は保持する
      @task.errors.add(:images, "は png / jpeg / gif / webp 形式・1枚5MB以下のみ対応しています")
      return render(@task.persisted? ? :edit : :new, status: :unprocessable_entity)
    end

    # 検証 OK のファイルだけ blob 化し、既存の選択と合算して signed_id を持ち回る。
    @image_signed_ids = carried_signed_ids + uploaded.map { |f| upload_blob(f).signed_id }

    # 「修正する」押下時は入力フォームへ戻す（入力値・画像選択を保持）。
    return render(@task.persisted? ? :edit : :new) if params[:back].present?

    if @task.valid?
      render :confirm
    else
      render(@task.persisted? ? :edit : :new, status: :unprocessable_entity)
    end
  end

  def create
    @task = @project.tasks.build(task_params)
    attach_signed_images(@task)

    if @task.save
      redirect_to project_path(@project), notice: "タスクを作成しました。"
    else
      @image_signed_ids = carried_signed_ids
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @task.assign_attributes(task_params)
    attach_signed_images(@task)

    if @task.save
      purge_removed_images
      redirect_to project_task_path(@project, @task), notice: "タスクを更新しました。", status: :see_other
    else
      @image_signed_ids = carried_signed_ids
      @remove_image_ids = remove_image_ids
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @task.destroy!
    redirect_to project_path(@project), notice: "タスクを削除しました。", status: :see_other
  end

  # 添付済み画像を1枚削除する（詳細画面からの個別削除）。
  def detach_image
    @task.images.find(params[:image_id]).purge
    redirect_to project_task_path(@project, @task), notice: "画像を削除しました。", status: :see_other
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def set_task
    @task = @project.tasks.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :status, :start_date, :end_date)
  end

  # フォームから送られた新規アップロードファイル（ActionDispatch::Http::UploadedFile）。
  def uploaded_image_files
    Array(params.dig(:task, :images)).reject(&:blank?)
  end

  # 確認画面を round-trip してきた、アップロード済み blob の signed_id 群。
  def carried_signed_ids
    Array(params.dig(:task, :image_signed_ids)).reject(&:blank?)
  end

  # 編集フォームでチェックされた、削除対象の既存添付（ActiveStorage::Attachment）の id 群。
  def remove_image_ids
    Array(params.dig(:task, :remove_image_ids)).reject(&:blank?)
  end

  # 形式・サイズの事前検証（モデルの images_format_and_size と同基準）。
  def valid_image_upload?(file)
    Task::IMAGE_CONTENT_TYPES.include?(file.content_type) && file.size <= Task::MAX_IMAGE_SIZE
  end

  # アップロードファイルをサーバー経由で MinIO に保存し、blob を返す。
  def upload_blob(file)
    ActiveStorage::Blob.create_and_upload!(
      io: file, filename: file.original_filename, content_type: file.content_type
    )
  end

  # 確認画面から持ち回った signed_id を添付する（保存は呼び出し側の save に委ねる）。
  def attach_signed_images(task)
    ids = carried_signed_ids
    task.images.attach(ids) if ids.any?
  end

  # 編集で削除指定された既存添付を purge する（save 成功後に実行）。
  def purge_removed_images
    ids = remove_image_ids
    @task.images_attachments.where(id: ids).find_each(&:purge) if ids.any?
  end
end
