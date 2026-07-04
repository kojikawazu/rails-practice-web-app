# プロジェクトモデル。ユーザーに属し、複数のタスクを束ねる。
# 削除時は配下のタスクも連動削除される（dependent: :destroy）。
#
# @!attribute [rw] title
#   @return [String] プロジェクト名（必須・最大 100 文字）
# @!attribute [rw] description
#   @return [String, nil] 説明（任意）
class Project < ApplicationRecord
  belongs_to :user
  has_many :tasks, dependent: :destroy

  validates :title, presence: true, length: { maximum: 100 }
end
