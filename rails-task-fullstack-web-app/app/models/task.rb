class Task < ApplicationRecord
  # 画像添付の許可形式と上限サイズ（コントローラー側の事前チェックでも参照する）
  IMAGE_CONTENT_TYPES = %w[image/png image/jpeg image/gif image/webp].freeze
  MAX_IMAGE_SIZE = 5.megabytes

  belongs_to :project

  # 1タスクに複数の画像を添付できる（Active Storage）
  has_many_attached :images

  enum :status, { not_started: 0, in_progress: 1, completed: 2 }, validate: true

  after_initialize :set_default_status, if: :new_record?

  validates :title, presence: true, length: { maximum: 200 }

  validate :end_date_not_before_start_date
  validate :images_format_and_size

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

  # 添付画像の形式・サイズを検証する（不正な添付はドメイン層で弾く）。
  def images_format_and_size
    images.each do |image|
      unless IMAGE_CONTENT_TYPES.include?(image.content_type)
        errors.add(:images, "は png / jpeg / gif / webp 形式のみ対応しています")
      end
      if image.byte_size > MAX_IMAGE_SIZE
        errors.add(:images, "は1枚あたり5MB以下にしてください")
      end
    end
  end
end
