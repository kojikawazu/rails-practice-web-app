# タスク関連ビューのヘルパーを定義するモジュール。
module TasksHelper
  # 編集フォームで選択できるステータスの選択肢を返す。
  # 現在の状態と、そこから許可された遷移先だけを出し、選べない遷移を UI に出さない。
  # UI で塞ぐのは誤操作を減らすためで、規則の最終的な担保はモデルの遷移バリデーション。
  #
  # 基準は入力中の値ではなく status_in_database（＝保存済みの状態）にする。
  # 検証エラーで再描画したとき、送られてきた不正な値を基準にすると選択肢が崩れるため。
  #
  # @param task [Task] 編集対象のタスク（永続化済み）
  # @return [Array<Array(String, String)>] [表示名, status の値] の組
  def selectable_status_options(task)
    current = task.status_in_database
    [ current, *Task::ALLOWED_STATUS_TRANSITIONS.fetch(current, []) ].map do |status|
      [ I18n.t("task_status.#{status}", default: status.humanize), status ]
    end
  end

  # 確認フローで hidden に埋める、staging 中 blob の signed_id を返す。
  # 発行先を current_user に限定した期限付きの値にし、他の利用者や画像 URL の signed_id と区別する。
  # 描画のたびに発行し直すため、確認画面を往復している間は有効期限が延長される。
  #
  # @param blob [ActiveStorage::Blob] TaskImageService.resolve / stage を経た staging 中の blob
  # @return [String] current_user 向けの staging 用 signed_id
  def staged_image_signed_id(blob)
    TaskImageService.signed_id_for(current_user, blob)
  end
end
