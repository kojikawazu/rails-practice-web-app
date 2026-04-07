class Task < ApplicationRecord
  belongs_to :project

  enum :status, { not_started: 0, in_progress: 1, completed: 2 }, validate: true

  validates :title, presence: true, length: { maximum: 200 }
end
