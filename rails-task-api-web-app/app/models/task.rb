# タスクモデル。プロジェクトに属する作業単位で、ステータスを enum で管理する。
# status は DB にデフォルトを持たないため、新規レコード時にコールバックで初期化する。
#
# @!attribute [rw] title
#   @return [String] タスク名（必須・最大 200 文字）
# @!attribute [rw] status
#   @return [String] ステータス（not_started / in_progress / completed）
class Task < ApplicationRecord
  belongs_to :project

  enum :status, { not_started: 0, in_progress: 1, completed: 2 }, validate: true

  validates :title, presence: true, length: { maximum: 200 }

  after_initialize :set_default_status, if: :new_record?

  private

  # 新規レコードの status 未設定時に既定値（not_started）をセットする。
  # DB 側にデフォルトを持たせない代わりのアプリ層での初期化。
  #
  # @return [void]
  def set_default_status
    self.status ||= :not_started
  end
end
