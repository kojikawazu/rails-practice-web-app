class Task < ApplicationRecord
  belongs_to :project

  enum :status, { not_started: 0, in_progress: 1, completed: 2 }, validate: true

  after_initialize :set_default_status, if: :new_record?

  validates :title, presence: true, length: { maximum: 200 }

  validate :end_date_not_before_start_date

  private

  def set_default_status
    self.status ||= :not_started
  end

  # 開始日・終了日が両方入力されている場合のみ、終了日 >= 開始日 を検証する。
  # （どちらも任意項目のため、片方のみ／未入力は許容する）
  def end_date_not_before_start_date
    return if start_date.blank? || end_date.blank?
    return if end_date >= start_date

    errors.add(:end_date, "は開始日以降の日付にしてください")
  end
end
