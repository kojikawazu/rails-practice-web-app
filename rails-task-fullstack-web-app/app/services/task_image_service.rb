# タスク画像の round-trip ロジック（検証付き blob 化 staging・signed_id の発行と照合・attach・削除 purge）を担うサービス。
# Active Storage と密結合する画像の業務ロジックを Controller から切り出したもの。
# HTTP 判断（render/redirect/session/params 抽出・app_host）と確認フローは Controller に残す。
# 添付制約の定数は Task モデル（ドメインの正）に置き、本サービスはそれを参照する。
#
# signed_id は推測不能な ID ではなく「添付を許す capability」として扱う。
# 確認画面で持ち回る signed_id は、用途（purpose）に staging 専用の値と発行先の利用者を含めて署名する。
# 画像 URL に載る既定用途の signed_id や、他の利用者向けに発行された signed_id は照合で nil になるため、
# 推測・流用された ID で他人の blob を自分のタスクへ添付すること（replay）を署名だけで拒否できる
# （利用者との紐付けを DB やセッションに保存しなくてよい）。
class TaskImageService
  # 確認画面で持ち回る signed_id の有効期限。入力〜確認〜確定にかかる時間の上限として 1 時間とする。
  # 期限切れは照合で nil になり、入力し直しを求める。放棄された blob の清掃
  # （PurgeUnattachedBlobsJob::RETENTION）は、この期限より十分長く取る。
  STAGING_EXPIRES_IN = 1.hour

  # staging 用 signed_id の用途。画像 URL などに使われる既定用途（:blob_id）と区別する。
  STAGING_PURPOSE = "task_image_staging".freeze
  private_constant :STAGING_PURPOSE

  # 新規アップロードを事前検証し、全て有効な場合のみ blob 化して返す。
  # 1つでも不正（形式/サイズ）なら blob を一切作らず nil を返す（オーファン防止）。
  # アップロードが空なら [] を返す（呼び出し側は持ち回り分と合算する）。
  #
  # @param uploaded_files [Array<ActionDispatch::Http::UploadedFile>] フォームの新規アップロード群
  # @return [Array<ActiveStorage::Blob>, nil] 全有効: 生成した blob の配列（空入力は []）／不正あり: nil
  def self.stage(uploaded_files)
    return nil if uploaded_files.any? { |file| !valid_upload?(file) }

    uploaded_files.map { |file| upload_blob(file) }
  end

  # 確認画面で持ち回るための、利用者に紐付いた期限付き signed_id を発行する。
  #
  # @param user [User] 確認フローを操作している利用者（current_user）
  # @param blob [ActiveStorage::Blob] staging 中の blob
  # @return [String] staging 用途・利用者限定・期限付きの signed_id
  def self.signed_id_for(user, blob)
    blob.signed_id(purpose: staging_purpose(user), expires_in: STAGING_EXPIRES_IN)
  end

  # 持ち回ってきた signed_id 群を照合し、利用者が添付してよい staging 中の blob 群を返す。
  # 改ざん・期限切れ・他の利用者向け・既定用途の signed_id と、既に添付済みの blob
  # （別タスクへの使い回し・二重送信）は不正とみなす。
  # 1つでも不正なら nil を返し、検証できない blob を部分的に attach しない。
  #
  # 認可の前提: user は Controller の current_user を渡すこと。発行時と同じ利用者でしか照合できないことが、
  # 単独で呼び出されても他人の blob に越権しない保証になる。
  #
  # @param user [User] 確認フローを操作している利用者（current_user）
  # @param signed_ids [Array<String>] フォームが round-trip してきた signed_id 群
  # @return [Array<ActiveStorage::Blob>, nil] 全て有効: blob の配列（空入力は []）／不正あり: nil
  def self.resolve(user, signed_ids)
    blobs = signed_ids.map { |id| ActiveStorage::Blob.find_signed(id, purpose: staging_purpose(user)) }
    return nil if blobs.any? { |blob| blob.nil? || blob.attachments.exists? }

    blobs
  end

  # 照合済みの blob を task に添付する（保存は呼び出し側の save に委ねる）。
  # signed_id の文字列を渡すと Active Storage が既定用途で find_signed! し直すため、照合済みの blob を受け取る。
  #
  # @param task [Task] 添付先のタスク
  # @param blobs [Array<ActiveStorage::Blob>] resolve で照合済みの blob 群
  # @return [void]
  def self.attach(task, blobs)
    task.images.attach(blobs) if blobs.any?
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

  # 発行先の利用者を含めた staging 用途。異なる利用者の signed_id は照合で一致しない。
  #
  # @param user [User] 発行先・照合先の利用者
  # @return [String] 例: "task_image_staging/42"
  def self.staging_purpose(user)
    "#{STAGING_PURPOSE}/#{user.id}"
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
  private_class_method :staging_purpose, :valid_upload?, :upload_blob
end
