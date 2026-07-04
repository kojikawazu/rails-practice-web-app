# タスクの CRUD・確認画面フロー・画像添付を扱うコントローラー。
# projects 配下のネストルーティングで、常に current_user のプロジェクトのタスクのみを操作する。
#
# 画像はファイル input を確認画面の hidden で持ち回れないため、確認ステップで一旦 blob 化し、
# signed_id を round-trip させる（JS 不要）。
class TasksController < ApplicationController
  before_action :require_login
  before_action :set_project
  before_action :set_task, only: %i[show edit update destroy detach_image]

  # タスク一覧。HTML はプロジェクト詳細へ集約し、JSON のみ一覧を返す。
  #
  # @return [void] HTML: プロジェクト詳細へリダイレクト／JSON: index を描画
  def index
    @tasks = @project.tasks

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
  # @return [void] 複製元の値を入れた @task で new ビューを描画
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
  #
  # @return [void] 検証成功: confirm ／「修正する」: new/edit ／検証失敗・不正画像: new/edit（422）
  #   ／GET アクセス時: 入力フォームへリダイレクト
  def confirm
    # 確認画面は POST 専用。リロード/戻る等で GET された場合は入力フォームへ戻す
    # （show ルートへ誤って落ちて 404 になるのを防ぐ。入力値は保持できないため作り直し）。
    if request.get?
      target = params[:id] ? edit_project_task_path(@project, params[:id]) : new_project_task_path(@project)
      return redirect_to(target, alert: "確認画面は再読み込みできません。入力し直してください。")
    end

    @task = params[:id] ? @project.tasks.find(params[:id]) : @project.tasks.build
    @task.assign_attributes(task_params)
    @task.app_host = request.host # 自オリジン埋め込み拒否の判定用
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

  # 新規作成の確定。確認画面から持ち回った画像を添付して保存する。
  #
  # @return [void] 成功: プロジェクト詳細へリダイレクト／失敗: new を 422 で再描画
  def create
    @task = @project.tasks.build(task_params)
    @task.app_host = request.host
    attach_signed_images(@task)

    if @task.save
      redirect_to project_path(@project), notice: "タスクを作成しました。"
    else
      @image_signed_ids = carried_signed_ids
      render :new, status: :unprocessable_entity
    end
  end

  # タスクを更新する。新規画像の添付と、削除予約された既存画像の purge を行う。
  #
  # @return [void] 成功: 詳細へ 303 リダイレクト／失敗: edit を 422 で再描画
  def update
    @task.assign_attributes(task_params)
    @task.app_host = request.host
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

  # タスクを削除する。
  #
  # @return [void] プロジェクト詳細へ 303 リダイレクト
  def destroy
    @task.destroy!
    redirect_to project_path(@project), notice: "タスクを削除しました。", status: :see_other
  end

  # 添付済み画像を1枚削除する（詳細画面からの個別削除）。
  #
  # @return [void] 詳細へ 303 リダイレクト
  def detach_image
    @task.images.find(params[:image_id]).purge
    redirect_to project_task_path(@project, @task), notice: "画像を削除しました。", status: :see_other
  end

  private

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
  #
  # @return [Array<String>] 空要素を除いた添付 id の配列
  def remove_image_ids
    Array(params.dig(:task, :remove_image_ids)).reject(&:blank?)
  end

  # 形式・サイズの事前検証（モデルの images_format_and_size と同基準）。
  #
  # @param file [ActionDispatch::Http::UploadedFile] 検証対象のアップロードファイル
  # @return [Boolean] 許可形式かつ上限サイズ以内なら true
  def valid_image_upload?(file)
    Task::IMAGE_CONTENT_TYPES.include?(file.content_type) && file.size <= Task::MAX_IMAGE_SIZE
  end

  # アップロードファイルをサーバー経由で MinIO に保存し、blob を返す。
  #
  # @param file [ActionDispatch::Http::UploadedFile] 保存対象のアップロードファイル
  # @return [ActiveStorage::Blob] 作成された blob（signed_id を round-trip に使う）
  def upload_blob(file)
    ActiveStorage::Blob.create_and_upload!(
      io: file, filename: file.original_filename, content_type: file.content_type
    )
  end

  # 確認画面から持ち回った signed_id を添付する（保存は呼び出し側の save に委ねる）。
  #
  # @param task [Task] 添付先のタスク
  # @return [void]
  def attach_signed_images(task)
    ids = carried_signed_ids
    task.images.attach(ids) if ids.any?
  end

  # 編集で削除指定された既存添付を purge する（save 成功後に実行）。
  #
  # @return [void]
  def purge_removed_images
    ids = remove_image_ids
    @task.images_attachments.where(id: ids).find_each(&:purge) if ids.any?
  end
end
