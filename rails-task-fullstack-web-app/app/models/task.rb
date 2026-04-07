class Task < ApplicationRecord
  belongs_to :project

  enum :status, { not_started: 0, in_progress: 1, completed: 2 }, validate: true

  after_initialize :set_default_status, if: :new_record?

  validates :title, presence: true, length: { maximum: 200 }

  private

  def set_default_status
    self.status ||= :not_started
  end
end
