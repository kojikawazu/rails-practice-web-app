# タスク画像の round-trip ロジック（検証付き blob 化 staging・attach・削除 purge）を担うサービス。
# Active Storage と密結合する画像の業務ロジックを Controller から切り出したもの。
# HTTP 判断（render/redirect/session/params 抽出・app_host）と確認フローは Controller に残す。
# 添付制約の定数は Task モデル（ドメインの正）に置き、本サービスはそれを参照する。
class TaskImageService
  # 新規アップロードを事前検証し、全て有効な場合のみ blob 化して signed_id 群を返す。
  # 1つでも不正（形式/サイズ）なら blob を一切作らず nil を返す（オーファン防止）。
  # アップロードが空なら [] を返す（呼び出し側は carried_signed_ids と合算する）。
  #
  # @param uploaded_files [Array<ActionDispatch::Http::UploadedFile>] フォームの新規アップロード群
  # @return [Array<String>, nil] 全有効: 生成した blob の signed_id 配列（空入力は []）／不正あり: nil
  def self.stage(uploaded_files)
    return nil if uploaded_files.any? { |file| !valid_upload?(file) }

    uploaded_files.map { |file| upload_blob(file).signed_id }
  end

  # 確認画面から持ち回った signed_id を task に添付する（保存は呼び出し側の save に委ねる）。
  #
  # @param task [Task] 添付先のタスク
  # @param signed_ids [Array<String>] round-trip してきた blob の signed_id 群
  # @return [void]
  def self.attach(task, signed_ids)
    task.images.attach(signed_ids) if signed_ids.any?
  end

  # 編集で削除指定された既存添付を purge する（save 成功後に呼ぶ）。
  # 受け取るのは blob の id ではなく attachment の id（View の task.images が列挙するのも
  # attachment）。task.images_attachments 起点で引くため、対象タスク以外の添付は外せない。
  #
  # @param task [Task] 対象タスク
  # @param attachment_ids [Array<String>] 削除する ActiveStorage::Attachment の id 群
  # @return [void]
  def self.purge(task, attachment_ids)
    task.images_attachments.where(id: attachment_ids).find_each(&:purge) if attachment_ids.any?
  end

  # 形式・サイズの事前検証（モデルの images_format_and_size と同基準）。
  #
  # @param file [ActionDispatch::Http::UploadedFile] 検証対象
  # @return [Boolean] 許可形式かつ上限サイズ以内なら true
  def self.valid_upload?(file)
    Task::IMAGE_CONTENT_TYPES.include?(file.content_type) && file.size <= Task::MAX_IMAGE_SIZE
  end

  # アップロードファイルをサーバー経由でストレージに保存し blob を返す。
  #
  # @param file [ActionDispatch::Http::UploadedFile] 保存対象
  # @return [ActiveStorage::Blob] 作成された blob
  def self.upload_blob(file)
    ActiveStorage::Blob.create_and_upload!(
      io: file, filename: file.original_filename, content_type: file.content_type
    )
  end
  private_class_method :valid_upload?, :upload_blob
end
