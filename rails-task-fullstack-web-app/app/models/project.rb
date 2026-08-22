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

  # 一覧表示用に、各プロジェクトのタスク件数を 1 クエリで同時に取得するスコープ。
  #
  # ビュー側で `project.tasks.count` を呼ぶと 1 行につき COUNT が 1 本増える（N+1）。
  # `includes` での事前読み込みでは解消しない（`count` は関連が読み込み済みでも SQL COUNT を発行する）ため、
  # 集計そのものを SQL 側（LEFT JOIN + GROUP BY）へ寄せ、件数を `tasks_count` 属性として載せる。
  #
  # タスク 0 件のプロジェクトを一覧から落とさないため、INNER ではなく LEFT JOIN を使う。
  # 集約済みの Relation を返すため、このスコープに対する `count` は件数ではなく
  # プロジェクト ID をキーにした Hash を返す（一覧描画専用であり、件数計測には使わない）。
  #
  # @return [ActiveRecord::Relation<Project>] tasks_count 属性を持つプロジェクト
  scope :with_task_counts, -> {
    left_joins(:tasks)
      .group(:id)
      .select("projects.*, COUNT(tasks.id) AS tasks_count")
  }
end
