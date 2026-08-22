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
end
